class_name State
extends Node

# Emitted when the state wants to transition to another state
signal transitioned(state: State, new_state_name: String)

# Reference to the state machine for accessing the character and animation tree
var state_machine: StateMachine = null


# Called when the state machine enters this state
func enter() -> void:
	pass


# Called when the state machine exits this state
func exit() -> void:
	pass


# Called during _process
func update(_delta: float) -> void:
	pass


# Called during _physics_process
func physics_update(_delta: float) -> void:
	pass


# Called during _input
func handle_input(_event: InputEvent) -> void:
	pass
