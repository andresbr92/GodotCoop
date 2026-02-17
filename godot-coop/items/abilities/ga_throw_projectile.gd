extends GameplayAbility
class_name GA_ThrowProjectile

# Referencia a los datos del proyectil (Visuales, Daño, Radio...)
# Usamos el mismo recurso que ya tenías para no tirar trabajo a la basura.
@export var throwable_data: ThrowableData 

func activate(actor: Node, handle: AbilitySpecHandle) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	# 1. Obtener referencias del Actor (Player)
	# Asumimos que el actor tiene las propiedades expuestas o buscamos los nodos
	var camera: Camera3D = actor.get_node("SpringArmPivot/Camera3D") # Ajusta la ruta si cambió
	var hand_marker: Node3D = actor.get_node("MeshInstance3D/HandMarker") # Necesitarás crear este Marker3D
	
	if not camera:
		printerr("[GA_Throw] Error: No camera found on actor")
		return

	# Si no hay marcador de mano, usamos la posición del actor + offset
	var spawn_pos = actor.global_position + Vector3(0, 1.5, 0) + (actor.global_transform.basis.z * 0.5)
	if hand_marker:
		spawn_pos = hand_marker.global_position

	# 2. Calcular Físicas
	var direction = -camera.global_transform.basis.z
	var velocity = direction * throwable_data.throw_force
	
	# 3. Networking (RPC al Spawner)
	# La lógica original estaba en ItemThrower. Ahora la habilidad gestiona la petición.
	# Como GameplayAbility es un Recurso, no tiene RPCs propios.
	# Llamamos a una función en el Actor para que haga el RPC, o buscamos el Spawner directamente.
	
	# Opción más limpia: Buscar el Spawner global (Singleto/Grupo)
	var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
	if spawner:
		# Enviamos los datos necesarios: Pos, Rot, Vel, y la RUTA del recurso de datos
		# Importante: El Spawner espera la ruta del ThrowableData
		spawner.spawn([spawn_pos, camera.global_rotation, velocity, throwable_data.resource_path])
		
		# 4. Consumir munición/item (Opcional por ahora)
		# Aquí deberíamos restar 1 al stack del inventario.
		# Esto requiere que la Habilidad sepa de qué Slot vino.
		# Lo dejaremos para un "refinamiento" posterior para no bloquearnos.
	
	print("[GA_Throw] Proyectil lanzado!")
