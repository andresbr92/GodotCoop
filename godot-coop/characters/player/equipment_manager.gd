@tool
@icon("res://addons/inventory-system/icons/interactor.svg")
class_name EquipmentManager
extends Node
@export var ability_system_node: NodePath = "../../AbilitySystemComponent"
@onready var ability_system: AbilitySystemComponent = get_node(ability_system_node)
@onready var openable: Openable = $HeadSlot/Openable
@onready var skeleton_3d: Skeleton3D = $"../../Visuals/X_Bot/Mesh/Skeleton"

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
	var stack = inventory.stacks[stack_index]
	if stack == null: return
	
	var item_def = inventory.database.get_item(stack.item_id)
	if not item_def.properties.has("equipment_data"): return
	
	var data_path = item_def.properties["equipment_data"]
	var data = load(data_path) as EquipmentData
	_apply_equipment_logic(data, item_def, slot_id)


func _on_item_unequipped(_stack_index: int, _inventory: Node, slot_id: String) -> void:
	_remove_equipment_logic(slot_id)


func _apply_equipment_logic(data: EquipmentData, item_def: ItemDefinition, slot_id: String) -> void:
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
		_apply_equipment_effects_logic(data, slot_id, context)
	
	# Visuals are applied for ALL slots (including storage)
	# Visual comes from ItemDefinition.properties["hand_item"], NOT from EquipmentData
	if item_def.properties.has("hand_item") and skeleton_3d:
		context["visual_node"] = _spawn_visual_attachment(item_def, slot_id)
	
	active_equipment[slot_id] = context


## Testable equipment effects logic - call directly in tests
func _apply_equipment_effects_logic(data: EquipmentData, slot_id: String, context: Dictionary) -> void:
	if data.passive_effects.size() > 0:
		var handles = ability_system.effect_manager._apply_effects_logic(data.passive_effects)
		context["effect_handles"].append_array(handles)
	
	if data.granted_abilities.size() > 0:
		var inventory_node = get_node(equipment_slots[slot_id])
		for grant in data.granted_abilities:
			var handle = ability_system.ability_manager._grant_ability_logic(
				grant.ability,
				grant.input_tag,
				inventory_node,
				0
			)
			if handle:
				context["ability_handles"].append(handle)


func _remove_equipment_logic(slot_id: String) -> void:
	if not active_equipment.has(slot_id): return
	
	var context = active_equipment[slot_id]
	
	if multiplayer.is_server():
		_remove_equipment_effects_logic(context)
	
	if is_instance_valid(context["visual_node"]):
		context["visual_node"].queue_free()
	
	active_equipment.erase(slot_id)


## Testable remove equipment effects logic - call directly in tests
func _remove_equipment_effects_logic(context: Dictionary) -> void:
	for handle in context["effect_handles"]:
		ability_system.effect_manager._remove_effect_logic(handle)
		
	for handle in context["ability_handles"]:
		ability_system.ability_manager._clear_ability_logic(handle)


## Maps slot_id to the corresponding visual marker path in the skeleton.
## Markers are nested inside BoneAttachments to allow transform adjustments.
## Path is relative to skeleton_3d.
const SLOT_TO_MARKER: Dictionary = {
	"HeadSlot": "Head/HeadSlot",
	"ChestSlot": "Chest/ChestSlot", 
	"HandSlot": "RightHand/RightHandSlot",
	"BeltSlot1": "BeltSlot/BeltSlot_1",
	"BeltSlot2": "BeltSlot/BeltSlot_2",
	"BeltSlot3": "BeltSlot/BeltSlot_3",
}

## Belt slot names for quick access by index (1, 2, 3)
const BELT_SLOTS: Array[String] = ["BeltSlot1", "BeltSlot2", "BeltSlot3"]

## Tracks if a swap is currently in progress (prevents spam)
var _swap_in_progress: bool = false


# ============================================
# BELT SLOT SWAP SYSTEM
# ============================================

## Called by client to request a swap between HandSlot and a BeltSlot
## belt_index: 0, 1, or 2 (corresponding to BeltSlot1, BeltSlot2, BeltSlot3)
func request_swap_belt_slot(belt_index: int) -> void:
	if belt_index < 0 or belt_index >= BELT_SLOTS.size():
		return
	
	if multiplayer.is_server():
		_start_swap(belt_index)
	else:
		_swap_belt_slot_rpc.rpc_id(1, belt_index)


## Testable swap request logic - call directly in tests (bypasses network check)
func _request_swap_belt_slot_logic(belt_index: int) -> void:
	if belt_index < 0 or belt_index >= BELT_SLOTS.size():
		return
	_start_swap(belt_index)


@rpc("any_peer", "reliable")
func _swap_belt_slot_rpc(belt_index: int) -> void:
	if not multiplayer.is_server():
		return
	_start_swap(belt_index)


## Validates and starts the swap process with delay
func _start_swap(belt_index: int) -> void:
	# Prevent multiple swaps at once
	if _swap_in_progress:
		return
	
	var hand_slot: GridInventory = get_node_or_null(equipment_slots["HandSlot"])
	var belt_slot: GridInventory = get_node_or_null(equipment_slots[BELT_SLOTS[belt_index]])
	
	if hand_slot == null or belt_slot == null:
		return
	
	# Check if there's anything to swap
	var hand_has_item = _slot_has_item(hand_slot)
	var belt_has_item = _slot_has_item(belt_slot)
	
	# Only proceed if at least one slot has an item
	if not hand_has_item and not belt_has_item:
		return
	
	# Get swap time from ability system's attribute set
	var swap_duration = 0.5  # Default fallback
	if ability_system and ability_system.attribute_set:
		swap_duration = ability_system.attribute_set.swap_time
	
	_swap_in_progress = true
	print("[EquipmentManager] Starting swap... (%.2fs)" % swap_duration)
	
	# Wait for the swap duration, then perform the swap
	await get_tree().create_timer(swap_duration).timeout
	
	# Re-validate after delay (items might have changed)
	if _slot_has_item(hand_slot) or _slot_has_item(belt_slot):
		_perform_atomic_swap(belt_index)
	
	_swap_in_progress = false


## Checks if a slot contains any item
func _slot_has_item(slot: GridInventory) -> bool:
	if slot.stacks.size() == 0:
		return false
	return slot.stacks[0] != null


## Performs an atomic swap between HandSlot and the specified BeltSlot
## This runs ONLY on the server to prevent race conditions
func _perform_atomic_swap(belt_index: int) -> void:
	var hand_slot: GridInventory = get_node_or_null(equipment_slots["HandSlot"])
	var belt_slot: GridInventory = get_node_or_null(equipment_slots[BELT_SLOTS[belt_index]])
	
	if hand_slot == null or belt_slot == null:
		return
	
	# Extract data from both slots BEFORE modifying anything
	var hand_data = _extract_slot_data(hand_slot)
	var belt_data = _extract_slot_data(belt_slot)
	
	# Clear both slots (this triggers stack_removed signals)
	_clear_slot(hand_slot)
	_clear_slot(belt_slot)
	
	# Add items to swapped positions (this triggers stack_added signals)
	# Belt item -> Hand
	if not belt_data.is_empty():
		_add_to_slot(hand_slot, belt_data)
	
	# Hand item -> Belt
	if not hand_data.is_empty():
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


## Spawns the visual for an equipped item based on the slot it's in.
## Visual scene path comes from ItemDefinition.properties["hand_item"].
func _spawn_visual_attachment(item_def: ItemDefinition, slot_id: String) -> Node3D:
	var visual_path = item_def.properties.get("hand_item", "")
	if visual_path == "":
		return null
	
	var visual_scene = load(visual_path)
	if not visual_scene:
		printerr("[EquipmentManager] Failed to load hand_item: ", visual_path)
		return null
	
	var visual_instance = visual_scene.instantiate()
	
	# Always use the slot_id to determine the marker - this ensures items
	# spawn in the correct location based on WHERE they're equipped, not
	# what type of item they are (e.g., potion in hand vs potion on belt)
	var marker_name = SLOT_TO_MARKER.get(slot_id, "")
	
	if marker_name == "":
		printerr("[EquipmentManager] No marker mapping for slot: ", slot_id)
		visual_instance.queue_free()
		return null
	
	var marker = skeleton_3d.get_node_or_null(marker_name)
	if marker:
		marker.add_child(visual_instance)
		return visual_instance
	
	printerr("[EquipmentManager] Marker not found in skeleton: ", marker_name)
	visual_instance.queue_free()
	return null
