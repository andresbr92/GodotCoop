@tool
class_name BTActionFleeSmart
extends BTAction

# ---------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------
@export var move_speed: float = 4.0
@export var flee_distance: float = 8.0
@export var target_var: StringName = &"target_player"

# ---------------------------------------------------------
# INTERNAL VARIABLES
# ---------------------------------------------------------
var _npc: CharacterBody3D
var _nav_agent: NavigationAgent3D

# _setup is called once when the BT initializes
func _setup() -> void:
	_npc = agent as CharacterBody3D
	# Dynamically fetch the NavigationAgent3D from the NPC
	_nav_agent = _npc.get_node_or_null("NavigationAgent3D")
	if not _nav_agent:
		printerr("[BTActionFleeSmart] NavigationAgent3D not found on ", _npc.name)

# _enter is called every time this task becomes active
func _enter() -> void:
	if not is_instance_valid(_npc) or not is_instance_valid(_nav_agent):
		return
		
	var target: Node3D = blackboard.get_var(target_var, null)
	if is_instance_valid(target):
		_update_flee_path(target)

# ---------------------------------------------------------
# EXECUTION LOGIC
# ---------------------------------------------------------
func _tick(delta: float) -> Status:
	# Sanity check
	if not is_instance_valid(_npc) or not is_instance_valid(_nav_agent):
		return FAILURE
		
	var target: Node3D = blackboard.get_var(target_var, null)
	if not is_instance_valid(target):
		return FAILURE

	# Dynamically update the path if the player keeps chasing us
	# (In a production environment, we might put this on a timer to save CPU)
	_update_flee_path(target)

	# If we reached the safe location, we can stop fleeing (SUCCESS)
	if _nav_agent.is_navigation_finished():
		# Optionally, reset velocity so it doesn't slide
		_npc.velocity = Vector3.ZERO
		return SUCCESS
		
	# Move towards the next path position provided by the NavMesh
	var next_path_pos: Vector3 = _nav_agent.get_next_path_position()
	var current_pos: Vector3 = _npc.global_position
	
	var direction: Vector3 = (next_path_pos - current_pos).normalized()
	# Keep movement strictly horizontal
	direction.y = 0.0 
	
	_npc.velocity = direction * move_speed
	
	# Rotate the NPC to face the escape route
	if direction.length_squared() > 0.001:
		var look_target = current_pos + direction
		# Use lerp_angle in the future for smoother rotation, instant for now
		_npc.look_at(look_target, Vector3.UP)
		
	_npc.move_and_slide()
	
	return RUNNING

# ---------------------------------------------------------
# HELPER METHODS
# ---------------------------------------------------------
func _update_flee_path(threat: Node3D) -> void:
	var current_pos: Vector3 = _npc.global_position
	var threat_pos: Vector3 = threat.global_position
	
	# Get the direction AWAY from the threat
	var flee_dir: Vector3 = (current_pos - threat_pos).normalized()
	flee_dir.y = 0.0
	
	# Calculate a theoretical point in the distance
	var desired_pos: Vector3 = current_pos + (flee_dir * flee_distance)
	
	# The NavigationAgent3D will automatically map this theoretical point 
	# to the closest valid NavMesh polygon.
	_nav_agent.target_position = desired_pos
