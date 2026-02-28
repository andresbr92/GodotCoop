class_name StateMachine
extends Node

# The initial state when the machine starts
@export var initial_state: NodePath

@export var animation_tree: AnimationTree

# The character this state machine controls
@onready var character: CharacterBody3D = owner

var playback: AnimationNodeStateMachinePlayback

var current_state: State
@export var replicated_blend_position: Vector2 = Vector2.ZERO
@export var replicated_state_name: StringName = &"Idle"
var states: Dictionary = {}


func _ready() -> void:
	# Wait for the owner to be ready
	await owner.ready
	# Get the playback object from the AnimationTree
	if animation_tree:
		playback = animation_tree.get("parameters/Locomotion/playback")
	else:
		push_warning("StateMachine: AnimationTree is missing!")
	
	# Populate the states dictionary and setup references
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.transitioned.connect(on_child_transition)
	
	# Initialize the default state
	if initial_state:
		var start_node := get_node(initial_state) as State
		if start_node:
			start_node.enter()
			current_state = start_node


func _process(delta: float) -> void:
	if animation_tree:
		animation_tree.set("parameters/Locomotion/Move/blend_position", replicated_blend_position)


func _apply_replicated_state() -> void:
	if not playback: return
	var current_anim = playback.get_current_node()
	if current_anim != replicated_state_name:
		playback.travel(replicated_state_name)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
	if not character.is_multiplayer_authority():
		_apply_replicated_state()


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


# Handles transitions between states
func on_child_transition(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
		
	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: Trying to transition to unknown state: " + new_state_name)
		return
		
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state
	if character.is_multiplayer_authority():
		replicated_state_name = StringName(new_state_name.capitalize())

func perform_action(anim_name: String) -> void:
	
	if anim_name == "":
		return
		
	var action_state = states.get("action")
	if action_state:
		printt("performing action", anim_name)
		action_state.set_action(anim_name)
		
		if current_state:
			current_state.exit()
		action_state.enter()
		current_state = action_state


@rpc("any_peer", "call_local", "reliable")
func play_upper_body_action(anim_name: String) -> void:
	if not animation_tree: return
	
	# 1. Asignamos dinámicamente qué animación va a usar el nodo OneShot
	# Nota: Para hacer esto dinámico en un BlendTree, hay un truco.
	# Por ahora, para el MVP, asumiremos que el nodo "Throw" está conectado.
	# En sistemas avanzados, cambiamos el nodo conectado por código.
	
	# 2. Disparamos el OneShot
	animation_tree.set("parameters/UpperBodyAction/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	GlobalLogger.log("[Animation FSM] Upper Body Action Triggered")
