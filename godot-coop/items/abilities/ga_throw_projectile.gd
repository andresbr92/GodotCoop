extends GameplayAbility
class_name GA_ThrowProjectile

# Referencia a los datos del proyectil (Visuales, Daño, Radio...)
# Usamos el mismo recurso que ya tenías para no tirar trabajo a la basura.
@export var throwable_data: ThrowableData 

func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	# 1. Obtener referencias del Actor (Player)
	# Asumimos que el actor tiene las propiedades expuestas o buscamos los nodos
	var direction = Vector3.FORWARD
	var spawn_pos = actor.global_position + Vector3(0, 1.5, 0)
	
	if args.has("aim_direction"):
		direction = args["aim_direction"]
	else:
		# Fallback si no hay datos (ej: activado por IA)
		direction = -actor.global_transform.basis.z

	if args.has("aim_position"):
		# Ajustamos el spawn para que no salga desde los pies del server,
		# sino relativo a donde miraba el cliente (o usar HandMarker del server)
		# Nota: Mejor usar HandMarker del server para evitar trampas de spawn,
		# pero usar la DIRECCION del cliente.
		pass

	# 2. Calcular Velocidad usando la dirección del cliente
	var velocity = direction * throwable_data.throw_force
	
	# 3. Spawnear (Server side)
	var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
	if spawner:
		# Usamos HandMarker del actor (Server) para el origen, 
		# pero Velocity basada en la cámara del Cliente.
		var hand_node = actor.get_node_or_null("MeshInstance3D/HandMarker")
		var real_spawn_pos = hand_node.global_position if hand_node else spawn_pos
		
		spawner.spawn([real_spawn_pos, Basis.looking_at(direction), velocity, throwable_data.resource_path])
