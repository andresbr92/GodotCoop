extends Camera3D
@export var lerp_speed := 5
@export var spring_arm : Node3D

func _ready() -> void:
	if is_multiplayer_authority():
		current = true
	else:
		current = false
		set_process(false)

func _process(delta: float) -> void:
	
	position = lerp(position, spring_arm.position, delta * lerp_speed)
