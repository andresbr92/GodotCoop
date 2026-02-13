extends Camera3D
@export var lerp_speed := 5
@export var target_node : Node3D
@export var camera_x_offset: float = 0.5 # Offset lateral (derecha positivo, izquierda negativo)

func _ready() -> void:
	if is_multiplayer_authority():
		current = true
	else:
		current = false
		set_process(false)

func _process(delta: float) -> void:
	var target_pos = target_node.position
	
	target_pos.x += camera_x_offset
	
	position = lerp(position, target_pos, delta * lerp_speed)
