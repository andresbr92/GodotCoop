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
	
	# ASIGNACIÓN DE POSICIÓN
	obj.position = pos
	
	# --- CORRECCIÓN AQUÍ ---
	# Comprobamos el tipo de dato para asignarlo correctamente
	if rot_data is Basis:
		# Si llega un Basis (Matriz), lo asignamos a la basis del transform
		obj.transform.basis = rot_data
	elif rot_data is Vector3:
		# Si llega un Vector3 (Euler), lo asignamos a la rotación
		obj.rotation = rot_data
	# -----------------------

	if obj is RigidBody3D:
		obj.linear_velocity = vel
		
	if obj.has_method("setup_projectile"):
		# Nota: asegúrate de que setup_projectile espera el Resource, no el path
		obj.setup_projectile(stats_resource, vel)
	
	return obj
