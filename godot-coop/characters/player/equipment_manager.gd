class_name EquipmentManager
extends Node

# Reference to the AttributeSet (ASC) to apply effects/abilities
@export var attribute_set: AttributeSet
@onready var openable: Openable = $HeadSlot/Openable
@onready var fake_skeleton: Node3D = $"../../MeshInstance3D/FakeSkeleton"


# Reference to the Skeleton/Mesh for visuals
@export var character_mesh_root: Node3D 

# Mapping of Slot Enum -> Inventory Node
# Assign these in the Inspector!
@export var equipment_slots: Dictionary = {
	 EquipmentData.SlotType.HEAD : NodePath("$HeadSlot")
}

# --- RUNTIME STATE ---
# Stores handles to clean up when unequipped
# Key: SlotType (int), Value: Dictionary { "effects": [], "abilities": [], "visual": Node }
var active_equipment: Dictionary = {}

func open(character : Node):
	openable.open(character)


func close(character : Node):
	openable.close(character)
	
func _ready() -> void:
	# Wait a frame to ensure inventory nodes are ready
	await get_tree().process_frame
	_connect_slots()

func _connect_slots() -> void:
	for slot_key in equipment_slots:
		var node_path = equipment_slots[slot_key]
		var inventory = get_node_or_null(node_path)
		
		if inventory:
			# We bind the 'slot_key' (Enum) so we know WHICH slot changed
			inventory.stack_added.connect(_on_item_equipped.bind(inventory, slot_key))
			inventory.stack_removed.connect(_on_item_unequipped.bind(inventory, slot_key))
		else:
			printerr("[EquipmentManager] Invalid inventory path for slot: ", slot_key)
# --- SIGNAL CALLBACKS ---

func _on_item_equipped(stack_index: int, inventory: Node, slot_type: int) -> void:
	print("item equipped")
	# Retrieve the data
	var stack = inventory.stacks[stack_index]
	if stack == null: return
	
	var def = inventory.database.get_item(stack.item_id)
	if not def.properties.has("equipment_data"): return
	
	var data_path = def.properties["equipment_data"]
	var data = load(data_path) as EquipmentData
	_apply_equipment_logic(data, slot_type)

	print("[EquipmentManager] Equipped item in slot: ", slot_type)
	
	# TODO: Call logic to apply GAS (Phase 4.3)
	# _apply_equipment_gas(data, slot_type)
	# _spawn_visuals(data, slot_type)

func _on_item_unequipped(stack_index: int, inventory: Node, slot_type: int) -> void:
	print("[EquipmentManager] Unequipped item from slot: ", slot_type)
	_remove_equipment_logic(slot_type)
	
	
	# TODO: Call logic to remove GAS (Phase 4.3)
	# _remove_equipment_gas(slot_type)
	# _despawn_visuals(slot_type)


func _apply_equipment_logic(data: EquipmentData, slot_type: int) -> void:
		# Si ya había algo (por error de señales), limpiamos primero
	if active_equipment.has(slot_type):
		_remove_equipment_logic(slot_type)
	
	# Estructura de contexto para guardar los recibos
	var context = {
		"effect_handles": [],
		"ability_handles": [],
		"visual_node": null
	}
	
	# 1. APLICAR GAS (Solo Servidor)
	if multiplayer.is_server():
		# A. Efectos Pasivos (Stats)
		if data.passive_effects.size() > 0:
			var handles = attribute_set.apply_gameplay_effects(data.passive_effects)
			context["effect_handles"].append_array(handles)
		
		# B. Habilidades Otorgadas
		if data.granted_abilities.size() > 0:
			for grant in data.granted_abilities:
				var handle = attribute_set.grant_ability(grant.ability, grant.input_tag)
				if handle:
					context["ability_handles"].append(handle)
	
	# 2. APLICAR VISUALES (Todos los peers)
	# (Asumiendo que InventorySync replica la acción de equipar, todos verán esto)
	if data.visual_scene and fake_skeleton:
		context["visual_node"] = _spawn_visual_attachment(data)
	
	# Guardar contexto en memoria
	active_equipment[slot_type] = context
	pass
func _remove_equipment_logic(slot_type: int) -> void:
	if not active_equipment.has(slot_type): return
	
	var context = active_equipment[slot_type]
	
	# 1. RETIRAR GAS (Solo Servidor)
	if multiplayer.is_server():
		# Retirar efectos usando los Handles guardados
		for handle in context["effect_handles"]:
			attribute_set.remove_effect(handle)
			
		# Retirar habilidades
		for handle in context["ability_handles"]:
			attribute_set.clear_ability(handle)
	
	# 2. RETIRAR VISUALES
	if is_instance_valid(context["visual_node"]):
		context["visual_node"].queue_free()
	
	# Limpiar diccionario
	active_equipment.erase(slot_type)
	pass
func _spawn_visual_attachment(data: EquipmentData) -> Node3D:
	if not data.visual_scene: return null
	
	# Instanciamos el modelo del item
	var visual_instance = data.visual_scene.instantiate()
	
	# Si se definió un hueso, usamos BoneAttachment3D
	if data.bone_name != "":
		var attachment = BoneAttachment3D.new()
		attachment.bone_name = data.bone_name
		# Importante: El nombre debe ser único o no importa, pero ayuda a debuggear
		attachment.name = "VisualAttachment_" + str(data.slot_type)
		
		fake_skeleton.add_child(attachment)
		attachment.add_child(visual_instance)
		
		return attachment
	else:
		# Si no hay hueso, lo pegamos al esqueleto (o raíz) directamente (Fallback)
		fake_skeleton.add_child(visual_instance)
		return visual_instance
