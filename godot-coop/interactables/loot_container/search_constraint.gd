extends InventoryConstraint
class_name SearchConstraint


func _can_remove_stack(inventory: Inventory, stack_index: int, amount: int) -> bool:
	var stack = inventory.stacks[stack_index]
	if stack == null: return true
	
	# Si el item no tiene la lista de revelados, asumimos que es público (o viejo sistema)
	if not stack.properties.has("revealed_to"):
		# Fallback para compatibilidad: si tiene 'revealed' antiguo y es false, bloquea
		if stack.properties.has("revealed") and stack.properties["revealed"] == false:
			return false
		return true
		
	var revealed_list = stack.properties["revealed_to"]
	
	# Accedemos al multiplayer a través del nodo Inventario
	var mp = inventory.multiplayer 
	var request_id = 0
	
	if mp.is_server():
		# Validación Autoritaria: ¿Quién llamó a la función/RPC?
		request_id = mp.get_remote_sender_id()
		
		# Si request_id es 0, significa que la llamada fue local (el Host jugando)
		if request_id == 0:
			request_id = 1
	else:
		# Validación Visual (Cliente): Soy yo quien mira el inventario
		request_id = mp.get_unique_id()
	
	# La lógica: ¿Está la ID en la lista de "Gente que ha buscado este item"?
	if request_id in revealed_list:
		return true 
		
	return false
