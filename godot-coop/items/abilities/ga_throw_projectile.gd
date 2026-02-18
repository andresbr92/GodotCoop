extends GameplayAbility
class_name GA_ThrowProjectile

# Reference to projectile data (Visuals, Damage, Radius...)
# We use the same resource you already had to avoid wasting work.
@export var throwable_data: ThrowableData 

func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	# 1. Get references from the Actor (Player)
	# We assume the actor has exposed properties or we search for the nodes
	var direction = Vector3.FORWARD
	var spawn_pos = actor.global_position + Vector3(0, 1.5, 0)
	
	if args.has("aim_direction"):
		direction = args["aim_direction"]
	else:
		# Fallback if no data (e.g.: activated by AI)
		direction = -actor.global_transform.basis.z

	if args.has("aim_position"):
		# Adjust spawn so it doesn't come from the server's feet,
		# but relative to where the client was looking (or use server's HandMarker)
		# Note: Better to use server's HandMarker to avoid spawn cheats,
		# but use the client's DIRECTION.
		pass

	# 2. Calculate Velocity using client's direction
	var velocity = direction * throwable_data.throw_force
	
	# 3. Spawn (Server side)
	var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
	if spawner:
		# We use the actor's HandMarker (Server) for origin,
		# but Velocity based on the Client's camera.
		var hand_node = actor.get_node_or_null("MeshInstance3D/HandMarker")
		var real_spawn_pos = hand_node.global_position if hand_node else spawn_pos
		
		spawner.spawn([real_spawn_pos, Basis.looking_at(direction), velocity, throwable_data.resource_path])
