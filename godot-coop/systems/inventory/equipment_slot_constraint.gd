class_name EquipmentSlotConstraint
extends GridInventoryConstraint

# The slot that this inventory accepts
@export var allowed_slot: EquipmentData.SlotType

func _can_add_on_inventory(inventory: Node, item_id: String, amount: int, properties: Dictionary) -> bool:
	print("check item")
	# 1. Get Item Definition
	# (Assuming 'inventory' has access to 'database', standard in this addon)
	if not "database" in inventory: return false
	
	var def = inventory.database.get_item(item_id)
	if def == null: return false
	
	# 2. Check if it has Equipment Data
	if not def.properties.has("equipment_data"):
		return false # Not an equipment item
	
	var data = def.properties["equipment_data"] as EquipmentData
	if data == null: return false
	
	# 3. Validate Slot
	return data.slot_type == allowed_slot
