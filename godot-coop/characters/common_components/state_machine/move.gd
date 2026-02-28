class_name MoveState
extends State
@onready var mesh: MeshInstance3D = $"../../Visuals/X_Bot/Mesh/Skeleton/Mesh"

# Called when the state machine enters this state
func enter() -> void:
	# Todo: Here we will tell the AnimationTree to travel to "Move/Run"
	if state_machine.playback:
		state_machine.playback.travel("Move")


# Called during _physics_process
func physics_update(_delta: float) -> void:
	if not state_machine.character.is_multiplayer_authority():
		return
		
	var global_velocity: Vector3 = state_machine.character.velocity
	var horizontal_velocity := Vector2(global_velocity.x, global_velocity.z)
	
	# Transition back to Idle if we stop moving
	if horizontal_velocity.length_squared() <= 0.1:
		transitioned.emit(self, "Idle")
		state_machine.replicated_blend_position = Vector2.ZERO
		return
		
	# -- BLENDSPACE 2D LOGIC --
	
	# 1. Get the mesh node. We use the mesh rotation to determine "Forward"
	#var mesh = state_machine.character.get_node("Visuals/X_Bot")

	
	if mesh and state_machine.animation_tree:

		# 2. Transform global velocity to local velocity relative to the mesh's transform
		var local_velocity: Vector3 = mesh.global_transform.basis.inverse() * global_velocity
		
		var blend_position := -Vector2(local_velocity.x, -local_velocity.z).normalized()
		

		state_machine.replicated_blend_position = blend_position
