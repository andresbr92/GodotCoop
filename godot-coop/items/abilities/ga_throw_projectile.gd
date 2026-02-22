extends GameplayAbility
class_name GA_ThrowProjectile


func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
	
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if not asc: return
	
	var potion_data = _get_potion_data_from_source(asc, handle)
	if not potion_data:
		GlobalLogger.log("[GA_ThrowProjectile] No potion_data found in item properties")
		return
	
	var direction = Vector3.FORWARD
	var spawn_pos = actor.global_position + Vector3(0, 1.5, 0)
	
	if args.has("aim_direction"):
		direction = args["aim_direction"]
	else:
		direction = -actor.global_transform.basis.z

	var velocity = direction * potion_data.throw_force
	
	var spawner = actor.get_tree().get_first_node_in_group("ProjectileSpawner")
	if spawner:
		var hand_node = actor.get_node_or_null("MeshInstance3D/FakeSkeleton/RightHand")
		var real_spawn_pos = hand_node.global_position if hand_node else spawn_pos
		
		spawner.spawn([real_spawn_pos, Basis.looking_at(direction), velocity, potion_data.resource_path, actor.name.to_int()])
		if potion_data.consume_on_use:
			_consume_source_item(asc, handle)


func _get_potion_data_from_source(asc: AbilitySystemComponent, handle: AbilitySpecHandle) -> PotionData:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if not inventory or slot_index == -1: return null
	
	var stack = inventory.stacks[slot_index]
	if not stack: return null
	
	var item_def = inventory.database.get_item(stack.item_id)
	if not item_def: return null
	print(item_def.properties)
	if item_def.properties.has("potion_data"):
		return load(item_def.properties["potion_data"]) as PotionData
	
	return null


func _consume_source_item(asc: AbilitySystemComponent, handle: AbilitySpecHandle) -> void:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if inventory and slot_index != -1:
		inventory.remove_at(slot_index, inventory.stacks[slot_index].item_id, 1)
