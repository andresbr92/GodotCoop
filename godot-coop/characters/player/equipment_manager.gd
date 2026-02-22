@tool
@icon("res://addons/inventory-system/icons/interactor.svg")
class_name EquipmentManager
extends Node
@export var ability_system_node: NodePath = "../../AbilitySystemComponent"
@onready var ability_system: AbilitySystemComponent = get_node(ability_system_node)
@onready var openable: Openable = $HeadSlot/Openable
@onready var fake_skeleton: Node3D = $"../../MeshInstance3D/FakeSkeleton"

@export var character_mesh_root: Node3D 

## Maps slot_id (String) -> NodePath. The slot_id is the node name.
## This separates the physical slot instance from the logical SlotType.
@export var equipment_slots: Dictionary = {
	"HeadSlot": NodePath("HeadSlot"),
	"ChestSlot": NodePath("ChestSlot"),
	"HandSlot": NodePath("HandSlot"),
	"BeltSlot1": NodePath("BeltSlot1"),
	"BeltSlot2": NodePath("BeltSlot2"),
	"BeltSlot3": NodePath("BeltSlot3"),
}

## Tracks active equipment by slot_id (String) -> context Dictionary
var active_equipment: Dictionary = {}

## Storage-only slots: items here get visuals but NO abilities/effects.
## These are for carrying items, not for "using" them.
const STORAGE_SLOTS: Array[String] = ["BeltSlot1", "BeltSlot2", "BeltSlot3"]


func open(character: Node):
	openable.open(character)


func close(character: Node):
	openable.close(character)


func _ready() -> void:
	await get_tree().process_frame
	_connect_slots()


func _connect_slots() -> void:
	for slot_id in equipment_slots:
		var node_path = equipment_slots[slot_id]
		var inventory = get_node_or_null(node_path)
		
		if inventory:
			# Pass slot_id (String) to identify which physical slot triggered the event
			inventory.stack_added.connect(_on_item_equipped.bind(inventory, slot_id))
			inventory.stack_removed.connect(_on_item_unequipped.bind(inventory, slot_id))
		else:
			printerr("[EquipmentManager] Invalid inventory path for slot: ", slot_id)


func _on_item_equipped(stack_index: int, inventory: Node, slot_id: String) -> void:
	print(slot_id)
	var stack = inventory.stacks[stack_index]
	if stack == null: return
	
	var def = inventory.database.get_item(stack.item_id)
	if not def.properties.has("equipment_data"): return
	
	var data_path = def.properties["equipment_data"]
	var data = load(data_path) as EquipmentData
	_apply_equipment_logic(data, slot_id)

	print("[EquipmentManager] Equipped item in slot: ", slot_id)


func _on_item_unequipped(_stack_index: int, _inventory: Node, slot_id: String) -> void:
	print("[EquipmentManager] Unequipped item from slot: ", slot_id)
	_remove_equipment_logic(slot_id)


func _apply_equipment_logic(data: EquipmentData, slot_id: String) -> void:
	if active_equipment.has(slot_id):
		_remove_equipment_logic(slot_id)
	
	var context = {
		"effect_handles": [],
		"ability_handles": [],
		"visual_node": null
	}
	
	var is_storage_slot = STORAGE_SLOTS.has(slot_id)
	
	# Only apply abilities and effects for NON-storage slots (active equipment)
	if not is_storage_slot and multiplayer.is_server():
		if data.passive_effects.size() > 0:
			var handles = ability_system.apply_gameplay_effects(data.passive_effects)
			context["effect_handles"].append_array(handles)
		
		if data.granted_abilities.size() > 0:
			var inventory_node = get_node(equipment_slots[slot_id])
			for grant in data.granted_abilities:
				var handle = ability_system.grant_ability(
					grant.ability,
					grant.input_tag,
					inventory_node,
					0
				)
				if handle:
					context["ability_handles"].append(handle)
	
	# Visuals are applied for ALL slots (including storage)
	if data.visual_scene and fake_skeleton:
		context["visual_node"] = _spawn_visual_attachment(data, slot_id)
	
	active_equipment[slot_id] = context


func _remove_equipment_logic(slot_id: String) -> void:
	if not active_equipment.has(slot_id): return
	
	var context = active_equipment[slot_id]
	
	if multiplayer.is_server():
		for handle in context["effect_handles"]:
			ability_system.remove_effect(handle)
			
		for handle in context["ability_handles"]:
			ability_system.clear_ability(handle)
	
	if is_instance_valid(context["visual_node"]):
		context["visual_node"].queue_free()
	
	active_equipment.erase(slot_id)


## Maps slot_id to the corresponding visual marker name in the skeleton.
## This allows items with SlotType.BELT to be placed in the correct marker
## based on which physical slot they were equipped to.
const SLOT_TO_MARKER: Dictionary = {
	"HeadSlot": "Head",
	"ChestSlot": "Chest", 
	"HandSlot": "RightHand",
	"BeltSlot1": "BeltSlotMarker1",
	"BeltSlot2": "BeltSlotMarker2",
	"BeltSlot3": "BeltSlotMarker3",
}

## Belt slot names for quick access by index (1, 2, 3)
const BELT_SLOTS: Array[String] = ["BeltSlot1", "BeltSlot2", "BeltSlot3"]


# ============================================
# BELT SLOT SWAP SYSTEM
# ============================================

## Called by client to request a swap between HandSlot and a BeltSlot
## belt_index: 0, 1, or 2 (corresponding to BeltSlot1, BeltSlot2, BeltSlot3)
func request_swap_belt_slot(belt_index: int) -> void:
	if belt_index < 0 or belt_index >= BELT_SLOTS.size():
		printerr("[EquipmentManager] Invalid belt index: ", belt_index)
		return
	
	if multiplayer.is_server():
		_perform_atomic_swap(belt_index)
	else:
		_swap_belt_slot_rpc.rpc_id(1, belt_index)


@rpc("any_peer", "reliable")
func _swap_belt_slot_rpc(belt_index: int) -> void:
	if not multiplayer.is_server():
		return
	_perform_atomic_swap(belt_index)


## Performs an atomic swap between HandSlot and the specified BeltSlot
## This runs ONLY on the server to prevent race conditions
func _perform_atomic_swap(belt_index: int) -> void:
	var hand_slot: GridInventory = get_node_or_null(equipment_slots["HandSlot"])
	var belt_slot: GridInventory = get_node_or_null(equipment_slots[BELT_SLOTS[belt_index]])
	
	if hand_slot == null or belt_slot == null:
		printerr("[EquipmentManager] Cannot find slots for swap")
		return
	
	# Extract data from both slots BEFORE modifying anything
	var hand_data = _extract_slot_data(hand_slot)
	var belt_data = _extract_slot_data(belt_slot)
	
	# If both are empty, nothing to do
	if hand_data == null and belt_data == null:
		return
	
	# Clear both slots (this triggers stack_removed signals)
	_clear_slot(hand_slot)
	_clear_slot(belt_slot)
	
	# Add items to swapped positions (this triggers stack_added signals)
	# Belt item -> Hand
	if belt_data != null:
		_add_to_slot(hand_slot, belt_data)
	
	# Hand item -> Belt
	if hand_data != null:
		_add_to_slot(belt_slot, hand_data)
	
	print("[EquipmentManager] Swapped HandSlot <-> ", BELT_SLOTS[belt_index])


## Extracts item data from a slot (returns null if empty)
func _extract_slot_data(slot: GridInventory) -> Dictionary:
	if slot.stacks.size() == 0:
		return {}
	
	var stack = slot.stacks[0]
	if stack == null:
		return {}
	
	return {
		"item_id": stack.item_id,
		"amount": stack.amount,
		"properties": stack.properties.duplicate(),
		"position": slot.stack_positions[0] if slot.stack_positions.size() > 0 else Vector2i.ZERO,
		"rotation": slot.stack_rotations[0] if slot.stack_rotations.size() > 0 else false
	}


## Clears all items from a slot
func _clear_slot(slot: GridInventory) -> void:
	# Remove from end to start to avoid index shifting issues
	for i in range(slot.stacks.size() - 1, -1, -1):
		var stack = slot.stacks[i]
		if stack != null:
			slot.remove_at(i, stack.item_id, stack.amount)


## Adds an item to a slot using extracted data
func _add_to_slot(slot: GridInventory, data: Dictionary) -> void:
	if data.is_empty():
		return
	slot.add_at_position(
		data.get("position", Vector2i.ZERO),
		data["item_id"],
		data["amount"],
		data.get("properties", {}),
		data.get("rotation", false)
	)


func _spawn_visual_attachment(data: EquipmentData, slot_id: String) -> Node3D:
	if not data.visual_scene: return null
	
	var visual_instance = data.visual_scene.instantiate()
	
	# Determine marker: use slot-specific marker, or fallback to data.bone_name
	var marker_name = SLOT_TO_MARKER.get(slot_id, data.bone_name)
	
	if marker_name != "":
		var marker = fake_skeleton.get_node_or_null(marker_name)
		if marker:
			marker.add_child(visual_instance)
			return visual_instance
		else:
			printerr("[EquipmentManager] Marker not found: ", marker_name)
	
	fake_skeleton.add_child(visual_instance)
	return visual_instance
