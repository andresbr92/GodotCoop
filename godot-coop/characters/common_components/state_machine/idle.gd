class_name IdleState
extends State

# Called when the state machine enters this state
func enter() -> void:
	# Todo: Here we will tell the AnimationTree to travel to "Idle"
	print("[Animation FSM] Entered IDLE")


# Called during _physics_process
func physics_update(_delta: float) -> void:
	# Only the multiplayer authority should dictate animation state changes based on local input/physics
	# We read the velocity calculated by player.gd
	if state_machine.character.velocity.length_squared() > 0.1:
		transitioned.emit(self, "move")
