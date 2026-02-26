@tool
class_name BTActionFindNearestPlayer
extends BTAction

# ---------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------
@export var detection_radius: float = 10.0
# The key we will use to store the target in the Blackboard
@export var target_var: StringName = &"target_player"

# ---------------------------------------------------------
# EXECUTION LOGIC
# ---------------------------------------------------------
func _tick(delta: float) -> Status:
	# Ensure this only runs on the server
	if not agent.multiplayer.is_server():
		return FAILURE
		
	# Agent is the NPC executing this Behavior Tree
	var npc: CharacterBody3D = agent as CharacterBody3D
	if not is_instance_valid(npc):
		return FAILURE
		
	var closest_player: Node3D = null
	var closest_dist_sq: float = detection_radius * detection_radius
	
	# Iterate over all players in the game to find the nearest
	# Note: Assume players are added to a "players" group when spawned
	var players = npc.get_tree().get_nodes_in_group("players")
	
	for player in players:
		if not is_instance_valid(player):
			continue
			
		var dist_sq: float = npc.global_position.distance_squared_to(player.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_player = player
			
	if closest_player != null:
		# Save the target to the Blackboard so other tasks can use it
		blackboard.set_var(target_var, closest_player)
		return SUCCESS
		
	# Clear the blackboard target if no player is in range
	blackboard.set_var(target_var, null)
	return FAILURE
