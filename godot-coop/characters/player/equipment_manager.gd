@tool
@icon("res://addons/inventory-system/icons/interactor.svg")
class_name EquipmentManager
extends Node

@export var ability_system: AbilitySystemComponent
@onready var openable: Openable = $HeadSlot/Openable
@onready var fake_skeleton: Node3D = $"../../MeshInstance3D/FakeSkeleton"

@export var character_mesh_root: Node3D 

@export var equipment_slots: Dictionary = {
	EquipmentData.SlotType.HEAD : NodePath("$HeadSlot"),
	EquipmentData.SlotType.CHEST : NodePath("$ChestSlot"),
	EquipmentData.SlotType.HAND : NodePath("$HandSlot"),
	EquipmentData.SlotType.BELTSLOT : NodePath("$BeltSlot1"),
	EquipmentData.SlotType.BELTSLOT : NodePath("$BeltSlot2"),
	EquipmentData.SlotType.BELTSLOT : NodePath("$BeltSlot3")
}

var active_equipment: Dictionary = {}


func open(character: Node):
	openable.open(character)


func close(character: Node):
	openable.close(character)


func _ready() -> void:
	await get_tree().process_frame
	_connect_slots()


func _connect_slots() -> void:
	for slot_key in equipment_slots:
		print(slot_key)
		var node_path = equipment_slots[slot_key]
		var inventory = get_node_or_null(node_path)
		
		if inventory:
			inventory.stack_added.connect(_on_item_equipped.bind(inventory, slot_key))
			inventory.stack_removed.connect(_on_item_unequipped.bind(inventory, slot_key))
		else:
			printerr("[EquipmentManager] Invalid inventory path for slot: ", slot_key)


func _on_item_equipped(stack_index: int, inventory: Node, slot_type: int) -> void:
	print("item equipped")
	var stack = inventory.stacks[stack_index]
	if stack == null: return
	
	var def = inventory.database.get_item(stack.item_id)
	if not def.properties.has("equipment_data"): return
	
	var data_path = def.properties["equipment_data"]
	var data = load(data_path) as EquipmentData
	_apply_equipment_logic(data, slot_type)

	print("[EquipmentManager] Equipped item in slot: ", slot_type)


func _on_item_unequipped(_stack_index: int, _inventory: Node, slot_type: int) -> void:
	print("[EquipmentManager] Unequipped item from slot: ", slot_type)
	_remove_equipment_logic(slot_type)


func _apply_equipment_logic(data: EquipmentData, slot_type: int) -> void:
	if active_equipment.has(slot_type):
		_remove_equipment_logic(slot_type)
	
	var context = {
		"effect_handles": [],
		"ability_handles": [],
		"visual_node": null
	}
	
	if multiplayer.is_server():
		if data.passive_effects.size() > 0:
			var handles = ability_system.apply_gameplay_effects(data.passive_effects)
			context["effect_handles"].append_array(handles)
		
		if data.granted_abilities.size() > 0:
			var inventory_node = get_node(equipment_slots[slot_type])
			for grant in data.granted_abilities:
				var handle = ability_system.grant_ability(
					grant.ability,
					grant.input_tag,
					inventory_node,
					0
				)
				if handle:
					context["ability_handles"].append(handle)
	
	if data.visual_scene and fake_skeleton:
		context["visual_node"] = _spawn_visual_attachment(data)
	
	active_equipment[slot_type] = context


func _remove_equipment_logic(slot_type: int) -> void:
	if not active_equipment.has(slot_type): return
	
	var context = active_equipment[slot_type]
	
	if multiplayer.is_server():
		for handle in context["effect_handles"]:
			ability_system.remove_effect(handle)
			
		for handle in context["ability_handles"]:
			ability_system.clear_ability(handle)
	
	if is_instance_valid(context["visual_node"]):
		context["visual_node"].queue_free()
	
	active_equipment.erase(slot_type)
func _spawn_visual_attachment(data: EquipmentData) -> Node3D:
	if not data.visual_scene: return null
	
	var visual_instance = data.visual_scene.instantiate()
	
	if data.bone_name != "":
		var marker = fake_skeleton.get_node_or_null(data.bone_name)
		if marker:
			marker.add_child(visual_instance)
			return visual_instance
		else:
			printerr("[EquipmentManager] Marker not found: ", data.bone_name)
	
	fake_skeleton.add_child(visual_instance)
	return visual_instance
