@tool
@icon("res://addons/inventory-system-demos/icons/character_inventory_system.svg")
extends NodeInventories
class_name CoopCharacterInventorySystem

#region Signals
signal opened_inventory(inventory : Inventory)
#endregion
const Interactor = preload("res://addons/inventory-system-demos/interaction_system/inventory_interactor.gd")

var opened_inventories : Array[Inventory]

@export_group("🗃️ Inventory Nodes")

@onready var main_inventory: GridInventory = $Inventory
@onready var drop_parent: CharacterBody3D = $".."
@export_node_path var interactor_path := NodePath("Interactor")
@onready var interactor : Interactor = get_node(interactor_path)



@export_group("⌨️ Inputs")
## Change mouse state based on inventory status
@export var change_mouse_state : bool = true
@export var check_inputs : bool = true
@export var toggle_inventory_input : String = "toggle_inventory"

@export_group("🫴 Interact")
@export var can_interact : bool = true
@export var raycast : RayCast3D:
	set(value):
		raycast = value
		var _interactor = get_node(interactor_path)
		if _interactor != null and value != null:
			_interactor.raycast = value
@export var camera_3d : Camera3D:
	set(value):
		camera_3d = value
		var _interactor = get_node(interactor_path)
		if _interactor != null and value != null:
			_interactor.camera = value

func _ready():
	if Engine.is_editor_hint():
		return

func _physics_process(_delta : float):
	if Engine.is_editor_hint():
		return
	if not can_interact:
		return
	interactor.try_interact()



func _input(_event : InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if check_inputs:
		inventory_inputs()


func inventory_inputs() -> void:
	if Input.is_action_just_released(toggle_inventory_input):
		# Check if any inventory or craft statis is already open
		if not is_any_station_or_inventory_opened():
			open_main_inventory()
			pass

func open_main_inventory():
	open_inventory(main_inventory)

func is_any_station_or_inventory_opened() -> bool:
	return is_open_any_station() or is_open_main_inventory()

func pick_to_inventory(node : Node):
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
		node.queue_free();
		return

	printerr("pick_to_inventory return false");


#region Open Inventories

func is_open_inventory(inventory : Inventory):
	return opened_inventories.find(inventory) != -1


func open_inventory(inventory: Inventory) -> void:
	if is_open_inventory(inventory):
		return
	add_open_inventory(inventory)


func add_open_inventory(inventory: Inventory) -> void:
	opened_inventories.append(inventory)
	opened_inventory.emit(inventory)
	if not is_open_main_inventory():
		#inventory.request_drop_obj.connect(_on_request_drop_obj)
		open_main_inventory()


func _check_inputs():
	if is_any_station_or_inventory_opened():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_open_main_inventory():
	return is_open_inventory(main_inventory)
#endregion
	
#region Open Craft Stations
func is_open_station(_station : CraftStation):
	# TODO: Add craft station logic
	return false
func is_open_any_station() -> bool:
	return false
	#return !opened_stations.is_empty()
#endregion
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
