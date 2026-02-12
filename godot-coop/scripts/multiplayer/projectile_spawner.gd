extends MultiplayerSpawner

class_name ProjectileSpawner


func _init() -> void:
	spawn_function = _spawn_projectile

func _spawn_projectile(data: Array):
	var pos = data[0]
	var rot = data[1]
	var vel = data[2]
	var scene_path = data[3]
	var potion_stats_path = data[4]
	
	var scene = load(scene_path)
	var stats = load(potion_stats_path) as ThrowableData
	
	if not scene: return null
	var obj = scene.instantiate()
	obj.position = pos
	obj.rotation = rot
	if obj is RigidBody3D:
		obj.linear_velocity = vel
	if obj.has_method("setup_projectile"):
		obj.setup_projectile(stats, vel)
	
	return obj
