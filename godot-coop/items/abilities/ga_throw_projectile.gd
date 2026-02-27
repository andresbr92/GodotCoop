extends GameplayAbility
class_name GA_ThrowProjectile

## Cached handle to access inventory source in _execute_payload
var _cached_handle: AbilitySpecHandle


func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	_cached_handle = handle
	super.activate(actor, handle, args)


## Spawns the projectile. Called immediately or on animation event based on wait_for_animation_event
func _execute_payload(actor: Node, _data: Dictionary, args: Dictionary = {}) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if not asc: return
	
	var potion_data = _get_potion_data_from_source(asc, _cached_handle)
	if not potion_data:
		GlobalLogger.log("[GA_ThrowProjectile] No potion_data found in item properties")
		return
	
	# Calculate throw direction
	var direction: Vector3
	if args.has("aim_direction"):
		direction = args["aim_direction"]
	else:
		direction = -actor.global_transform.basis.z

	var velocity = direction * potion_data.throw_force
	
	# Get spawn position from character's hand
	var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
	if not spawner: return
	
	var spawn_pos = actor.global_position + Vector3(0, 1.5, 0)
	var hand_node = actor.get_node_or_null("Visuals/X_Bot/Mesh/Skeleton/RightHand/RightHandPotionSpawn")
	var real_spawn_pos = hand_node.global_position if hand_node else spawn_pos
	
	spawner.spawn([real_spawn_pos, Basis.looking_at(direction), velocity, potion_data.resource_path, actor.name.to_int()])
	
	if potion_data.consume_on_use:
		_consume_source_item(asc, _cached_handle)


func _get_potion_data_from_source(asc: AbilitySystemComponent, handle: AbilitySpecHandle) -> PotionData:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if not inventory or slot_index == -1: return null
	
	var stack = inventory.stacks[slot_index]
	if not stack: return null
	
	var item_def = inventory.database.get_item(stack.item_id)
	if not item_def: return null
	if item_def.properties.has("potion_data"):
		return load(item_def.properties["potion_data"]) as PotionData
	
	return null


func _consume_source_item(asc: AbilitySystemComponent, handle: AbilitySpecHandle) -> void:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if inventory and slot_index != -1:
		inventory.remove_at(slot_index, inventory.stacks[slot_index].item_id, 1)
