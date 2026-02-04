@tool
@icon("res://addons/inventory-system-demos/icons/character_inventory_system.svg")
extends NodeInventories
class_name CoopCharacterInventorySystem


const Interactor = preload("res://addons/inventory-system-demos/interaction_system/inventory_interactor.gd")




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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
