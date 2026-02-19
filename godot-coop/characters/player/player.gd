extends CharacterBase


const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 10.0 # Velocidad de giro del personaje

@onready var camera: Camera3D = $SpringArmPivot/Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var character_inventory_system: NetworkedCharacterInventorySystem = $CharacterInventorySystem

func _enter_tree() -> void:
	super._enter_tree()
	set_multiplayer_authority(name.to_int())
	$CharacterInventorySystem/Inventory/SyncInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentInventory/SyncInventory.set_multiplayer_authority(1)
	%SyncHotbar.set_multiplayer_authority(1)
	$CharacterInventorySystem/CraftStation/SyncCraftStation.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/HeadSlot/SyncGridInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/HeadSlot/Openable.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/ChestSlot/SyncGridInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/ChestSlot/Openable.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/HandSlot/SyncGridInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/EquipmentManager/HandSlot/Openable.set_multiplayer_authority(1)
	%AttributeSet.set_multiplayer_authority(1)
	#$Dropper.set_multiplayer_authority(1)
func _ready() -> void:
	#var Fireball = GameplayAbility.new()
	#attribute_set.grant_ability(Fireball, "ability.primary")
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	#if Input.is_action_just_pressed("aim"):
		#is_strafing = true
	#if Input.is_action_just_released("aim"):
		#is_strafing = false
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Rotate direction vector according to camera
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	if attribute_set.is_strafing:
		mesh_instance_3d.global_rotation.y = camera.global_rotation.y
	
	if direction:
		velocity.x = direction.x * attribute_set.speed
		velocity.z = direction.z * attribute_set.speed
		
		# --- ROTATION LOGIC HERE ---
		var target_rotation = atan2(direction.x, direction.z) + PI
		if not attribute_set.is_strafing:
			mesh_instance_3d.rotation.y = lerp_angle(mesh_instance_3d.rotation.y, target_rotation, delta * ROTATION_SPEED)

		
	else:
		velocity.x = move_toward(velocity.x, 0, attribute_set.speed)
		velocity.z = move_toward(velocity.z, 0, attribute_set.speed)

	move_and_slide()
func _input(event: InputEvent) -> void:
	# Only the local player controls input
	if not is_multiplayer_authority(): return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	
	# --- ABILITY INPUT MAPPING ---
	
	# Primary Attack (Left Click)
	if event.is_action_pressed("attack_primary") : # Or "throw" if you kept that name
		var data = _collect_activation_data()
		attribute_set.server_ability_input_pressed.rpc(AttributeSet.INPUT_PRIMARY, data)
		
	if event.is_action_released("attack_primary"):
		attribute_set.server_ability_input_released.rpc(AttributeSet.INPUT_PRIMARY)

	# Secondary Attack (Right Click - Aiming/Alt Fire)
	if event.is_action_pressed("attack_secondary"):
		#set_strafing(true) 
		attribute_set.server_ability_input_pressed.rpc(AttributeSet.INPUT_SECONDARY)
		
	if event.is_action_released("attack_secondary"):
		#set_strafing(false) 
		attribute_set.server_ability_input_released.rpc(AttributeSet.INPUT_SECONDARY)
	#if event.is_action_pressed("aim"): # O el nombre que tengas en InputMap
		#attribute_set.server_ability_input_pressed.rpc(AttributeSet.INPUT_SECONDARY)
		#
	#if event.is_action_released("aim"):
		#attribute_set.server_ability_input_released.rpc(AttributeSet.INPUT_SECONDARY)
		
	# You can add more mappings here (Reload, Jump, Ultimate...)

func _collect_activation_data() -> Dictionary:
	var data = {}
	data["aim_direction"] = -camera.global_transform.basis.z
	data["aim_position"] = camera.global_position
	return data
func set_strafing(state: bool) -> void:
	attribute_set.is_strafing = state
