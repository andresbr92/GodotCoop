extends InventoryConstraint
class_name SearchConstraint


func _can_remove_stack(inventory: Inventory, stack_index: int, amount: int) -> bool:
	var stack = inventory.stacks[stack_index]
	if stack == null: return true
	
	# If it has the property and it's false, BLOCK the extraction
	if stack.properties.has("revealed") and stack.properties["revealed"] == false:
		return false # "You can't take what you haven't searched!"
		
	return true
