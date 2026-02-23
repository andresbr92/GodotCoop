class_name ActionState
extends State

var current_action_name: String = ""
var is_animating: bool = false

func enter() -> void:
	is_animating = true
	if state_machine.playback and current_action_name != "":
		state_machine.playback.travel(current_action_name)
		print("[Animation FSM] Executing Action: ", current_action_name)
	else:
		_finish_action()

func physics_update(_delta: float) -> void:
	if not is_animating:
		return
		
	# Comprobamos si el AnimationTree ha terminado de reproducir la animación actual
	if state_machine.animation_tree:
		var current_node = state_machine.playback.get_current_node()
		
		# Si el playback ya no está en nuestro nodo de acción (terminó y volvió a otro, o no lo encontró)
		# Opcionalmente, podemos usar señales, pero consultar el playback es más seguro en el FSM
		if current_node != current_action_name and current_node != "":
			# Godot a veces tarda un frame en transicionar, así que verificamos que no estemos en proceso de viajar
			if not state_machine.playback.is_playing():
				pass # Está viajando
			else:
				_finish_action()

func _finish_action() -> void:
	is_animating = false
	current_action_name = ""
	
	# Decidir a dónde volver basándonos en la velocidad actual
	var horizontal_velocity := Vector2(state_machine.character.velocity.x, state_machine.character.velocity.z)
	if horizontal_velocity.length_squared() > 0.1:
		transitioned.emit(self, "move")
	else:
		transitioned.emit(self, "idle")

# Método especial para inyectar la animación antes de entrar al estado
func set_action(anim_name: String) -> void:
	current_action_name = anim_name
