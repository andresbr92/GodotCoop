extends CharacterBase


const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 3

@onready var camera: Camera3D = $SpringArmPivot/Camera3D
@onready var mesh_instance_3d: Node3D = $Visuals
@onready var character_inventory_system: NetworkedCharacterInventorySystem = $CharacterInventorySystem
@onready var label_3d: Label3D = $Label3D


func _enter_tree() -> void:
	super._enter_tree()
	set_multiplayer_authority(name.to_int())
	$CharacterInventorySystem/Inventory/SyncInventory.set_multiplayer_authority(1)
	$CharacterInventorySystem/CraftStation/SyncCraftStation.set_multiplayer_authority(1)
	$AbilitySystemComponent.set_multiplayer_authority(1)
	for system in $AbilitySystemComponent.get_children():
		system.set_multiplayer_authority(1)

	for inventory in $CharacterInventorySystem/EquipmentManager.get_children():
		if inventory is GridInventory:
			inventory.set_multiplayer_authority(1)
			for sincronizer in inventory.get_children():
				sincronizer.set_multiplayer_authority(1)


func _ready() -> void:
	label_3d.text = str(name)
	var state_machine = get_node_or_null("StateMachine")
	if state_machine and ability_system:
		ability_system.ability_animation_triggered.connect(_on_ability_animation)
	pass
func _on_ability_animation(anim_name: String) -> void:
	var sm = get_node_or_null("StateMachine")
	if not sm: return

	# Lógica de decisión: ¿Es una animación que permite moverse?
	# Por ahora, digamos que "Throw" permite moverse.
	if anim_name == "Throw":
		sm.play_upper_body_action.rpc(anim_name)
	else:
		# Si es otra cosa, usamos la FSM completa que detiene o controla el flujo
		sm.perform_action(anim_name)


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	if ability_system.is_strafing:
		mesh_instance_3d.global_rotation.y = camera.global_rotation.y
	
	if direction:
		velocity.x = direction.x * ability_system.speed
		velocity.z = direction.z * ability_system.speed
		
		var target_rotation = atan2(direction.x, direction.z) + PI
		if not ability_system.is_strafing:
			mesh_instance_3d.rotation.y = lerp_angle(mesh_instance_3d.rotation.y, target_rotation, delta * ROTATION_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, ability_system.speed)
		velocity.z = move_toward(velocity.z, 0, ability_system.speed)

	move_and_slide()


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	
	if event.is_action_pressed("attack_primary"):
		var data = _collect_activation_data()
		ability_system.server_ability_input_pressed(AbilityManager.INPUT_PRIMARY, data)
		
	if event.is_action_released("attack_primary"):
		ability_system.server_ability_input_released(AbilityManager.INPUT_PRIMARY)

	if event.is_action_pressed("attack_secondary"):
		ability_system.server_ability_input_pressed(AbilityManager.INPUT_SECONDARY, {})
		
	if event.is_action_released("attack_secondary"):
		ability_system.server_ability_input_released(AbilityManager.INPUT_SECONDARY)
	
	# Belt slot swap inputs (1, 2, 3 keys)
	_handle_belt_slot_inputs(event)


func _handle_belt_slot_inputs(event: InputEvent) -> void:
	var equipment_manager = character_inventory_system.equipment_manager
	if equipment_manager == null:
		return
	
	if event.is_action_pressed("belt_slot_1"):
		equipment_manager.request_swap_belt_slot(0)
	elif event.is_action_pressed("belt_slot_2"):
		equipment_manager.request_swap_belt_slot(1)
	elif event.is_action_pressed("belt_slot_3"):
		equipment_manager.request_swap_belt_slot(2)


func _collect_activation_data() -> Dictionary:
	return {
		"aim_direction": -camera.global_transform.basis.z,
		"aim_position": camera.global_position
	}


func set_strafing(state: bool) -> void:
	ability_system.is_strafing = state

func on_animation_event(event_id: String) -> void:
	if not is_multiplayer_authority():
		return

	# Reenviamos el evento al sistema de habilidades
	if ability_system:
		ability_system.handle_animation_event(event_id)
