class_name EquipmentSlotConstraint
extends GridInventoryConstraint

# El slot que este inventario acepta
@export var allowed_slot: EquipmentData.SlotType

# 1. Punto de entrada para Drag & Drop en Grilla (Lo que te fallaba)
func _can_add_on_position(inventory: Node, position: Vector2i, item_id: String, amount: int, properties: Dictionary, is_rotated: bool) -> bool:
	return _validate_item(inventory, item_id)

# 2. Punto de entrada para Auto-Add / Transferencia Rápida (Por seguridad)
func _can_add_on_inventory(inventory: Node, item_id: String, amount: int, properties: Dictionary) -> bool:
	return _validate_item(inventory, item_id)

# --- Lógica Común ---
func _validate_item(inventory: Node, item_id: String) -> bool:
	print("validating item")
	# 1. Obtener base de datos
	if not "database" in inventory: 
		return false
	
	var def = inventory.database.get_item(item_id)
	if def == null: 
		return false
	
	# 2. Verificar si tiene datos de equipamiento
	# NOTA: Asegúrate de que el nombre de la propiedad en la DB es EXACTAMENTE "equipment_data"
	if not def.properties.has("equipment_data"):
		return false 
	
	var data_path = def.properties["equipment_data"] 
	var data = load(data_path) as EquipmentData
	#if item_definition.properties.has("hand_item"):
		#var path = item_definition.properties["hand_item"]
		#hand_item_scene = load(path)
	if data == null: 
		return false
	
	# 3. Validar el Slot
	# Si el slot del item coincide con el permitido por este constraint
	if data.slot_type == allowed_slot:
		return true
		
	# Feedback opcional (solo debug)
	# print("Rechazado: El item es ", data.slot_type, " pero el slot pide ", allowed_slot)
	return false
