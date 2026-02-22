class_name EquipmentSlotConstraint
extends GridInventoryConstraint

# The slot this inventory accepts
@export var allowed_slot: Array[EquipmentData.SlotType]

# 1. Entry point for Grid Drag & Drop
func _can_add_on_position(inventory: Node, position: Vector2i, item_id: String, amount: int, properties: Dictionary, is_rotated: bool) -> bool:
	return _validate_item(inventory, item_id)

# 2. Entry point for Auto-Add / Quick Transfer (for safety)
func _can_add_on_inventory(inventory: Node, item_id: String, amount: int, properties: Dictionary) -> bool:
	return _validate_item(inventory, item_id)

# --- Common Logic ---
func _validate_item(inventory: Node, item_id: String) -> bool:
	# 1. Get database
	if not "database" in inventory: 
		return false
	
	var def = inventory.database.get_item(item_id)
	if def == null: 
		return false
	
	# 2. Check if it has equipment data
	# NOTE: Make sure the property name in the DB is EXACTLY "equipment_data"
	if not def.properties.has("equipment_data"):
		return false 
	
	var data_path = def.properties["equipment_data"] 
	var data = load(data_path) as EquipmentData
	if data == null: 
		return false
	
	# 3. Validate the Slot
	# Check if ANY of the item's allowed_slots matches ANY slot this constraint accepts
	for item_slot in data.allowed_slots:
		if allowed_slot.has(item_slot):
			return true
		
	# Optional feedback (debug only)
	# print("Rejected: Item allows ", data.allowed_slots, " but slot requires ", allowed_slot)
	return false
