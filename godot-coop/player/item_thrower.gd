extends Node3D
class_name ItemThrower

@export var hotbar: Hotbar
@export var hand: Node3D
@export var camera: Camera3D
@export var throw_force: float = 15.0

@onready var projectile_spawner : MultiplayerSpawner = get_tree().get_first_node_in_group("ProjectileSpawner")


func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("throw"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				print("lanzar potion")
				check_and_throw()
	else:
		set_process(false)

func  check_and_throw() -> void:
	var stack = hotbar.get_stack_on_selection()
	if stack == null:
		return
	var item_id = stack.item_id
	var definition = hotbar.database.get_item(item_id)
	if definition == null:
		return
	if definition.properties.has("throwable"):
		var scene_path : String = definition.properties["throwable"]
		var potion_stats_path = definition.properties["potion_stats"]
		
		var spawn_pos = hand.global_position
		var direction = -camera.global_transform.basis.z
		var velocity = direction * throw_force
		var stack_index = hotbar.selection_index
		
		if multiplayer.is_server():
			throw_potion_rpc(stack_index, spawn_pos, camera.global_rotation, velocity, scene_path, potion_stats_path)
		else:
			throw_potion_rpc.rpc_id(1, stack_index, spawn_pos, camera.global_rotation, velocity, scene_path, potion_stats_path)
			
		
@rpc("any_peer", "call_local", "reliable")
func throw_potion_rpc(stack_index: int, pos: Vector3, rot: Vector3, vel: Vector3, scene_path: String, potion_path: String) -> void:
	if not multiplayer.is_server():
		return
	var inventory = hotbar.get_inventory()
	if stack_index >= inventory.stacks.size(): return
	
	if projectile_spawner:
		projectile_spawner.spawn([pos, rot, vel, scene_path, potion_path])
	else:
		print("No item spawner")
	var item_id = inventory.stacks[stack_index].item_id
	inventory.remove_at(stack_index, item_id, 1)
	pass
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
