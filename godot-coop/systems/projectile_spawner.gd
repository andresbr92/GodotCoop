extends MultiplayerSpawner

class_name ProjectileSpawner


func _init() -> void:
	spawn_function = _spawn_projectile

func _spawn_projectile(data: Array):
	var pos = data[0]
	var rot = data[1]
	var vel = data[2]
	var path_to_tres  = data[3]
	
	
	var stats_resource = load(path_to_tres) as ThrowableData
	if not stats_resource: return null
	var scene_inside_resource = stats_resource.projectile_scene

	if not scene_inside_resource: return null
	var obj = scene_inside_resource.instantiate()
	obj.position = pos
	obj.rotation = rot
	if obj is RigidBody3D:
		obj.linear_velocity = vel
	if obj.has_method("setup_projectile"):
		obj.setup_projectile(stats_resource, vel)
	
	return obj
