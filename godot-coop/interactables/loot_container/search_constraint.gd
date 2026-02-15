extends InventoryConstraint
class_name SearchConstraint


func _can_remove_stack(inventory: Inventory, stack_index: int, amount: int) -> bool:
	var stack = inventory.stacks[stack_index]
	if stack == null: return true
	
	# Si tiene la propiedad y es falsa, BLOQUEAMOS la extracción
	if stack.properties.has("revealed") and stack.properties["revealed"] == false:
		return false # "¡No puedes coger lo que no has buscado!"
		
	return true
