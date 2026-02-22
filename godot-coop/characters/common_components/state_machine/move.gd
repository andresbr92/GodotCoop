class_name MoveState
extends State

# Called when the state machine enters this state
func enter() -> void:
	# Todo: Here we will tell the AnimationTree to travel to "Move/Run"
	print("[Animation FSM] Entered MOVE")


# Called during _physics_process
func physics_update(_delta: float) -> void:
	# If the character stops moving, transition back to Idle
	if state_machine.character.velocity.length_squared() <= 0.1:
		transitioned.emit(self, "idle")
