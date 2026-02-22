class_name StateMachine
extends Node

# The initial state when the machine starts
@export var initial_state: NodePath

# The character this state machine controls
@onready var character: CharacterBody3D = owner

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	# Wait for the owner to be ready
	await owner.ready
	
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
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


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
