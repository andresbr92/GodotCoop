class_name GameplayAbility
extends Resource

@export var ability_name: String = "Base Ability"

@export_group("Activation Requirements")
@export var activation_required_tags: PackedStringArray
@export var activation_blocked_tags: PackedStringArray

@export_group("Ongoing Effects")
@export var ongoing_effects: Array[GameplayEffect]

@export_group("Animation")
## (ej: "Throw", "Drink")
@export var animation_name: String = ""
@export var wait_for_animation_event: bool = false



func can_activate(actor: Node) -> bool:
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if not asc: 
		return false
		
	for tag in activation_required_tags:
		if not asc.has_tag(tag):
			return false 
			
	for tag in activation_blocked_tags:
		if asc.has_tag(tag):
			return false 
			
	return true

func _execute_payload(_actor: Node, _data: Dictionary, _args: Dictionary = {}) -> void:
	pass

func activate(_actor: Node, _handle: AbilitySpecHandle, _args: Dictionary = {}) -> void:
	# 1. Disparar visuales (esto ya lo hacíamos)
	# (Aquí va tu código actual que inicia la animación, etc)
	
	# 2. Decidir cuándo ejecutar la lógica
	if wait_for_animation_event:
		var asc = _actor.get_node_or_null("AbilitySystemComponent")
		if asc:
			# Conectamos una sola vez a la señal para esperar el evento
			# Usamos CONNECT_ONE_SHOT para que se desconecte sola tras dispararse
			asc.gameplay_event_triggered.connect(
				func(event_id): 
					if event_id == "execute":
						_execute_payload(_actor, {}, _args),
				CONNECT_ONE_SHOT
			)
		else:
			_execute_payload(_actor, {}, _args)
	else:
		_execute_payload(_actor, {}, _args)


func input_released(_actor: Node, _handle: AbilitySpecHandle) -> void:
	pass


func end_ability(_actor: Node, _handle: AbilitySpecHandle) -> void:
	pass
