extends CharacterBase

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 10.0 # Velocidad de giro del personaje
var is_strafing = false

@onready var camera: Camera3D = $SpringArmPivot/Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var character_inventory_system: NetworkedCharacterInventorySystem = $CharacterInventorySystem

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	$CharacterInventorySystem/Inventory/SyncInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentInventory/SyncInventory.set_multiplayer_authority(1)
	%SyncHotbar.set_multiplayer_authority(1)
	$CharacterInventorySystem/CraftStation/SyncCraftStation.set_multiplayer_authority(1)
	#$Dropper.set_multiplayer_authority(1)
func _ready() -> void:
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if Input.is_action_just_pressed("aim"):
		is_strafing = true
	if Input.is_action_just_released("aim"):
		is_strafing = false
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Rotamos el vector de dirección según la cámara
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# --- AQUÍ ESTÁ LA LÓGICA DE ROTACIÓN ---
		if !is_strafing:
				
			# 1. Calculamos el ángulo hacia donde queremos mirar (atan2 devuelve el ángulo en radianes)
			var target_rotation = atan2(direction.x, direction.z) + PI
			
			# 2. Rotamos el MESH suavemente hacia ese ángulo
			# Usamos lerp_angle para que busque el camino más corto (evita giros de 360 grados raros)
			mesh_instance_3d.rotation.y = lerp_angle(mesh_instance_3d.rotation.y, target_rotation, delta * ROTATION_SPEED)
		else :
			mesh_instance_3d.global_rotation.y = camera.global_rotation.y
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
