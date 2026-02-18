@tool
@icon("res://addons/inventory-system-demos/icons/character_inventory_system.svg")
class_name InventorySystemManager
extends NetworkedCharacterInventorySystem
@export_node_path var equipment_manager_path := NodePath("EquipmentManager")


func _ready():
	if Engine.is_editor_hint():
		return
	if is_multiplayer_authority():
		# Setup for enabled/disabled mouse 🖱️😀
		if change_mouse_state:
			opened_inventory.connect(_update_opened_inventories)
			closed_inventory.connect(_update_opened_inventories)
			opened_station.connect(_update_opened_stations)
			closed_station.connect(_update_opened_stations)
			_update_opened_inventories(main_inventory)
	else:
		picked.connect(_on_picked)
	hotbar.active_slot(0)
	hotbar.active_slot(1)
	hotbar.active_slot(2)
	hotbar.active_slot(3)
	#hotbar.active_slot(4)
	#hotbar.active_slot(5)
	#hotbar.active_slot(6)
	#hotbar.active_slot(7)


func _on_picked(obj : Node):
	picked_rpc.rpc(obj.get_path())


func _input(event : InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if check_inputs and is_multiplayer_authority():
		hot_bar_inputs(event)
		inventory_inputs()


func _physics_process(_delta : float):
	if Engine.is_editor_hint():
		return
	if not can_interact:
		return
	if multiplayer.multiplayer_peer != null and is_multiplayer_authority():
		interactor.try_interact()


func is_any_station_or_inventory_opened() -> bool:
	return is_open_any_station() or is_open_main_inventory()


func _update_opened_inventories(_inventory : Inventory):
	_check_inputs()


func _update_opened_stations(_craft_station : CraftStation):
	_craft_station.load_valid_recipes()
	_check_inputs()


func _check_inputs():
	if is_any_station_or_inventory_opened():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func inventory_inputs():
	if Input.is_action_just_released(toggle_inventory_input):
		if not is_any_station_or_inventory_opened():
			open_main_inventory()

	if Input.is_action_just_released(exit_inventory_and_craft_panel_input):
		close_inventories()
		close_craft_stations()

	if Input.is_action_just_released(toggle_craft_panel_input):
		if not is_any_station_or_inventory_opened():
			open_main_craft_station()


#region Pick
func pick_to_inventory(node : Node):
	if multiplayer.is_server():
		_pick_to_inventory_logic(node)
	else:
		pick_to_inventory_rpc.rpc_id(1, node.get_path())


func _pick_to_inventory_logic(node : Node):
	if main_inventory == null:
		return

	if node == null:
		return

	if !node.get("is_pickable"):
		return

	var item_id = node.item_id
	var item_properties = node.item_properties
	var amount = node.amount

	if main_inventory.add(item_id, amount, item_properties, true) == 0:
		picked.emit(node)
		node.queue_free();
		return

	printerr("pick_to_inventory return false");
#endregion


#region Transfer
func transfer(inventory: GridInventory, origin_pos: Vector2i, destination: GridInventory, amount: int):
	var stack_index = inventory.get_stack_index_at(origin_pos)
	if stack_index == -1:
		return
	inventory.transfer(stack_index, destination, amount)


func transfer_to(inventory: GridInventory, origin_pos: Vector2i, destination: GridInventory, destination_pos: Vector2i, amount: int, is_rotated: bool):
	if multiplayer.is_server():
		_transfer_to_logic(inventory, origin_pos, destination, destination_pos, amount, is_rotated)
	else:
		transfer_to_rpc.rpc_id(1, inventory.get_path(), origin_pos, destination.get_path(), destination_pos, amount, is_rotated)


func _transfer_to_logic(inventory: GridInventory, origin_pos: Vector2i, destination: GridInventory, destination_pos: Vector2i, amount: int, is_rotated: bool):
	inventory.transfer_to(origin_pos, destination, destination_pos, amount, is_rotated)
#endregion


#region Split
func split(inventory : Inventory, stack_index : int, amount : int):
	if multiplayer.is_server():
		_split_logic(inventory, stack_index, amount)
	else:
		split_rpc.rpc_id(1, inventory.get_path(), stack_index, amount)


func _split_logic(inventory : Inventory, stack_index : int, amount : int):
	inventory.split(stack_index, amount)
#endregion


#region Equip
func equip(stack: ItemStack, inventory: Inventory, slot_index: int):
	if multiplayer.is_server():
		_equip_logic(stack, inventory, slot_index)
	else:
		var stack_index = inventory.stacks.find(stack)
		if stack_index != -1:
			equip_rpc.rpc_id(1, stack_index, inventory.get_path(), slot_index)


func _equip_logic(stack: ItemStack, _inventory : Inventory, slot_index: int):
	hotbar.equip(stack, slot_index)
#endregion


#region Rotate
func rotate(stack: ItemStack, inventory : Inventory):
	if multiplayer.is_server():
		_rotate_logic(stack, inventory)
	else:
		var stack_index = inventory.stacks.find(stack)
		if stack_index != -1:
			rotate_rpc.rpc_id(1, stack_index, inventory.get_path())


func _rotate_logic(stack: ItemStack, inventory : Inventory):
	inventory.rotate(stack)
#endregion


#region Sort
func sort(inventory : Inventory):
	if multiplayer.is_server():
		_sort_logic(inventory)
	else:
		sort_rpc.rpc_id(1, inventory.get_path())


func _sort_logic(inventory : Inventory):
	inventory.sort()
#endregion


#region Drop
func drop(stack: ItemStack, inventory: Inventory):
	if multiplayer.is_server():
		_drop_logic(stack, inventory)
	else:
		var stack_index = inventory.stacks.find(stack)
		if stack_index != -1:
			drop_rpc.rpc_id(1, stack_index, inventory.get_path())


func _drop_logic(stack: ItemStack, inventory: Inventory):
	var stack_index = inventory.stacks.find(stack)
	if stack_index == -1:
		return
	inventory.drop_from_inventory(stack_index, stack.amount, stack.properties)


func drop_all_items():
	main_inventory.drop_all_stacks()
	equipment_inventory.drop_all_stacks()
#endregion


#region Crafter
func craft(craft_station : CraftStation, recipe_index : int):
	if multiplayer.is_server():
		_craft_logic(craft_station, recipe_index)
	else:
		craft_rpc.rpc(craft_station.get_path(), recipe_index)


func _craft_logic(craft_station : CraftStation, recipe_index : int):
	craft_station.craft(recipe_index)
#endregion


#region Hotbar
func hot_bar_inputs(event : InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				hotbar_previous_item()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				hotbar_next_item()
	if event is InputEventKey:
		var input_key_event = event as InputEventKey
		if event.is_pressed() and not event.is_echo():
			if input_key_event.keycode > KEY_0 and input_key_event.keycode < KEY_9:
				hotbar_change_selection(input_key_event.keycode - KEY_1)


func hotbar_change_selection(index : int):
	if multiplayer.is_server():
		_hotbar_change_selection_logic(index)
	else:
		hotbar_change_selection_rpc.rpc_id(1, index)


func _hotbar_change_selection_logic(index : int):
	if hotbar.selection_index == index:
		index = -1
	hotbar.selection_index = index


func hotbar_previous_item():
	if multiplayer.is_server():
		_hotbar_previous_item_logic()
	else:
		hotbar_previous_item_rpc.rpc_id(1)


func _hotbar_previous_item_logic():
	hotbar.previous_item()


func hotbar_next_item():
	if multiplayer.is_server():
		_hotbar_next_item_logic()
	else:
		hotbar_next_item_rpc.rpc_id(1)


func _hotbar_next_item_logic():
	hotbar.next_item()
#endregion


#region Open Inventories
#region Open Inventories
func is_open_inventory(inventory : Inventory):
	return opened_inventories.find(inventory) != -1


func open_inventory(inventory : Inventory):
	if multiplayer.is_server():
		_open_inventory_logic(inventory)
		# Si abrimos un inventario externo suelto, intentamos activar su Openable
		_set_openable_state(inventory, true) 
	else:
		open_inventory_rpc.rpc_id(1, inventory.get_path())


func _open_inventory_logic(inventory : Inventory):
	if is_open_inventory(inventory):
		return
	add_open_inventory(inventory)


func add_open_inventory(inventory : Inventory):
	if multiplayer.is_server():
		add_open_inventory_rpc.rpc(inventory.get_path())
	_add_open_inventory_logic(inventory)


func _add_open_inventory_logic(inventory : Inventory):
	opened_inventories.append(inventory)
	opened_inventory.emit(inventory)
	if not is_open_main_inventory():
		open_main_inventory()


func open_main_inventory():
	if multiplayer.is_server():
		_open_main_inventory_logic()
	else:
		open_main_inventory_rpc.rpc_id(1)


func _open_main_inventory_logic():
	# 1. Abrir inventario principal
	_open_inventory_logic(main_inventory)
	_set_openable_state(main_inventory, true)
	
	# 2. Abrir inventarios de equipamiento (Usando el EquipmentManager)
	if equipment_manager:
		for slot in equipment_manager.get_children():
			if slot and slot is Inventory:
				_open_inventory_logic(slot)
				_set_openable_state(slot, true)


func close_inventory(inventory : Inventory):
	# Manejo de contenedores externos (Chest, Box)
	if main_inventory != inventory:
		# Si el padre tiene metodo close (ej. BoxInventory), lo llamamos
		if inventory.get_parent().has_method("close"):
			inventory.get_parent().close(get_parent())
	
	# Manejo del nodo Openable interno del inventario
	_set_openable_state(inventory, false)
	
	remove_open_inventory(inventory)


func remove_open_inventory(inventory : Inventory):
	if multiplayer.is_server():
		remove_open_inventory_rpc.rpc(inventory.get_path())
	_remove_open_inventory_logic(inventory)


func _remove_open_inventory_logic(inventory : Inventory):
	var index = opened_inventories.find(inventory)
	opened_inventories.remove_at(index)
	closed_inventory.emit(inventory)


func close_inventories():
	if multiplayer.is_server():
		_close_inventories_logic()
	else:
		close_inventories_rpc.rpc_id(1)


func _close_inventories_logic():
	for index in range(opened_inventories.size() - 1, -1, -1):
		close_inventory(opened_inventories[index])


func is_open_any_inventory():
	return !opened_inventories.is_empty()


func is_open_main_inventory():
	return is_open_inventory(main_inventory)
#endregion


#region Open Craft Stations
func is_open_station(station : CraftStation):
	return opened_stations.find(station) != -1


func open_station(craft_station : CraftStation):
	if multiplayer.is_server():
		_open_station_logic(craft_station)
	else:
		open_station_rpc.rpc(get_path_to(craft_station))


func _open_station_logic(station : CraftStation):
	if is_open_station(station):
		return
	add_open_station(station)


func add_open_station(craft_station : CraftStation):
	if multiplayer.is_server():
		add_open_station_rpc.rpc(craft_station.get_path())
	_add_open_station_logic(craft_station)


func _add_open_station_logic(station : CraftStation):
	opened_stations.append(station)
	opened_station.emit(station)


func close_station(station : CraftStation):
	if not is_open_station(station):
		return
	remove_open_station(station)


func remove_open_station(craft_station : CraftStation):
	if multiplayer.is_server():
		remove_open_station_rpc.rpc(craft_station.get_path())
	_remove_open_station_logic(craft_station)


func _remove_open_station_logic(station : CraftStation):
	var index = opened_stations.find(station)
	opened_stations.remove_at(index)
	closed_station.emit(station)
	if main_station != station:
		station.get_parent().close(get_parent())


func open_main_craft_station():
	if multiplayer.is_server():
		_open_main_craft_station_logic()
	else:
		open_main_craft_station_rpc.rpc_id(1)


func _open_main_craft_station_logic():
	_open_station_logic(main_station)


func close_craft_stations():
	if multiplayer.is_server():
		_close_craft_stations_logic()
	else:
		close_stations_rpc.rpc_id(1)


func _close_craft_stations_logic():
	for index in range(opened_stations.size() - 1, -1, -1):
		close_station(opened_stations[index])


func is_open_any_station():
	return !opened_stations.is_empty()
#endregion


#region RPCs
@rpc("any_peer")
func picked_rpc(obj_path : NodePath):
	var obj = get_node(obj_path)
	picked.emit(obj)


@rpc("any_peer")
func open_main_inventory_rpc():
	_open_main_inventory_logic()


@rpc
func open_inventory_rpc(inventory_path : NodePath):
	var inventory = get_node(inventory_path)
	_open_inventory_logic(inventory)


@rpc("any_peer")
func add_open_inventory_rpc(inventory_path : NodePath):
	var inventory = get_node(inventory_path)
	_add_open_inventory_logic(inventory)


@rpc("any_peer")
func remove_open_inventory_rpc(inventory_path : NodePath):
	var inventory = get_node(inventory_path)
	_remove_open_inventory_logic(inventory)


@rpc("any_peer")
func add_open_station_rpc(station_path : NodePath):
	var station = get_node(station_path)
	_add_open_station_logic(station)


@rpc("any_peer")
func remove_open_station_rpc(station_path : NodePath):
	var station = get_node(station_path)
	_remove_open_station_logic(station)


@rpc
func close_inventories_rpc():
	if multiplayer.is_server():
		_close_inventories_logic()


@rpc
func pick_to_inventory_rpc(node_path: NodePath):
	_pick_to_inventory_logic(get_node(node_path))


@rpc
func transfer_to_rpc(inventory_path: NodePath, origin_pos: Vector2i, destination_path: NodePath, destination_pos: Vector2i, amount: int, is_rotated: bool):
	var inv = get_node(inventory_path)
	var dest_inv = get_node(destination_path)
	if inv == null or dest_inv == null:
		return
	_transfer_to_logic(inv, origin_pos, dest_inv, destination_pos, amount, is_rotated)


@rpc
func split_rpc(inventory_path: NodePath, stack_index: int, amount: int):
	var inv = get_node(inventory_path)
	if inv == null:
		return
	_split_logic(inv, stack_index, amount)


@rpc
func rotate_rpc(stack_index: int, inventory_path: NodePath):
	var inv = get_node(inventory_path)
	if inv == null:
		return
	var stack = inv.stacks[stack_index]
	_rotate_logic(stack, inv)


@rpc
func sort_rpc(inventory_path: NodePath):
	var inv = get_node(inventory_path)
	if inv == null:
		return
	_sort_logic(inv)


@rpc
func drop_rpc(stack_index: int, inventory_path: NodePath):
	var inv = get_node(inventory_path)
	if inv == null:
		return
	var stack = inv.stacks[stack_index]
	_drop_logic(stack, inv)


@rpc
func equip_rpc(stack_index: int, inventory_path: NodePath, slot_index: int):
	var inv = get_node(inventory_path)
	if inv == null:
		return
	var stack = inv.stacks[stack_index]
	_equip_logic(stack, inv, slot_index)


@rpc
func hotbar_change_selection_rpc(selection_index: int):
	if not multiplayer.is_server():
		return
	_hotbar_change_selection_logic(selection_index)


@rpc
func hotbar_previous_item_rpc():
	if not multiplayer.is_server():
		return
	_hotbar_previous_item_logic()


@rpc
func hotbar_next_item_rpc():
	if not multiplayer.is_server():
		return
	_hotbar_next_item_logic()


@rpc
func open_main_craft_station_rpc():
	_open_main_craft_station_logic()


@rpc
func open_station_rpc(craft_station_path : NodePath):
	var station = get_node(craft_station_path)
	_open_station_logic(station)


@rpc
func close_stations_rpc():
	if multiplayer.is_server():
		_close_craft_stations_logic()


@rpc
func craft_rpc(craft_station_path : NodePath, recipe_index : int):
	var station = get_node(craft_station_path)
	_craft_logic(station, recipe_index)
#endregion

#region Helpers
func _set_openable_state(inventory: Inventory, is_open: bool):
	# 1. Check if it has Openable node as direct child
	var openable = inventory.get_node_or_null("Openable")
	
	# 2. (Optional) If not a child, check if it's a sibling (BoxInventory pattern)
	if not openable:
		var parent = inventory.get_parent()
		if parent:
			openable = parent.get_node_or_null("Openable")
	
	# 3. Execute the action
	if openable:
		# Asumimos que drop_parent es el CharacterBody3D (el 'character')
		if is_open:
			if openable.has_method("open"):
				openable.open(drop_parent)
		else:
			if openable.has_method("close"):
				openable.close(drop_parent)
#endregion
