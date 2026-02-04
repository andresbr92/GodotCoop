@tool
@icon("res://addons/inventory-system-demos/icons/character_inventory_system.svg")
extends NodeInventories
class_name CoopCharacterInventorySystem


const Interactor = preload("res://addons/inventory-system-demos/interaction_system/inventory_interactor.gd")


@export_group("🗃️ Inventory Nodes")
@export_node_path var main_inventory_path := NodePath("InventoryHandler/Inventory")
@onready var main_inventory : GridInventory = get_node(main_inventory_path)
@export_node_path var drop_parent_path := NodePath("../..");
@onready var drop_parent : Node = get_node(drop_parent_path)
@export_node_path var drop_parent_position_path := NodePath("..");
@onready var drop_parent_position : Node = get_node(drop_parent_position_path)



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



func _input(event : InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if check_inputs:
		inventory_inputs()


func inventory_inputs() -> void:
	pass

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


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
