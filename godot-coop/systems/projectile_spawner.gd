extends MultiplayerSpawner

class_name ProjectileSpawner


func _init() -> void:
	spawn_function = _spawn_projectile

func _spawn_projectile(data: Array):
	var pos = data[0]
	var rot_data = data[1] # Le cambio el nombre a rot_data
	var vel = data[2]
	var path_to_tres = data[3]
	
	var stats_resource = load(path_to_tres) as ThrowableData
	if not stats_resource: return null
	var scene_inside_resource = stats_resource.projectile_scene

	if not scene_inside_resource: return null
	var obj = scene_inside_resource.instantiate()
	
	# POSITION ASSIGNMENT
	obj.position = pos
	
	# --- FIX HERE ---
	# Check the data type to assign it correctly
	if rot_data is Basis:
		# If it's a Basis (Matrix), assign it to the transform's basis
		obj.transform.basis = rot_data
	elif rot_data is Vector3:
		# If it's a Vector3 (Euler), assign it to rotation
		obj.rotation = rot_data
	# -----------------------

	if obj is RigidBody3D:
		obj.linear_velocity = vel
		
	if obj.has_method("setup_projectile"):
		# Note: make sure setup_projectile expects the Resource, not the path
		obj.setup_projectile(stats_resource, vel)
	
	return obj
