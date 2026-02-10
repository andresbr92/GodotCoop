extends Node3D

@export var mouse_sensivity := 0.0025
@onready var spring_arm_3d: SpringArm3D = $SpringArm3D


func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else: set_process(false)
	

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotation.y -= event.relative.x * mouse_sensivity
			rotation.y = wrapf(rotation.y, 0.0, TAU)
			
			rotation.x -= event.relative.y * mouse_sensivity
			rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(30))
