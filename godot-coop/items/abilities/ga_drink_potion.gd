class_name GA_Drink_Potion
extends GameplayAbility


func activate(actor: Node, handle: AbilitySpecHandle, _args: Dictionary = {}) -> void:
	var asc: AttributeSet = actor.get_node_or_null("AttributeSet")
	if not asc: return
	
	var potion_data = _get_potion_data_from_source(asc, handle)
	if not potion_data: 
		GlobalLogger.log("[GA_Drink_Potion] No potion_data found in item properties")
		return
	
	GlobalLogger.log("[GA_Drink_Potion] Starting to drink potion... Hold for ", potion_data.drink_duration, "s")
	
	# Start the cast - player must hold the button for drink_duration seconds
	var on_complete = func(): _on_drink_complete(actor, handle, potion_data)
	var on_cancel = func(): _on_drink_cancelled(actor, handle)
	
	asc.start_cast(handle, potion_data.drink_duration, on_complete, on_cancel)


func _on_drink_complete(actor: Node, handle: AbilitySpecHandle, potion_data: PotionData) -> void:
	GlobalLogger.log("[GA_Drink_Potion] Drink complete! Applying effects...")
	
	var asc: AttributeSet = actor.get_node_or_null("AttributeSet")
	if not asc: return
	
	if potion_data.consumed_effects.size() > 0:
		asc.apply_gameplay_effects(potion_data.consumed_effects)
	
	if potion_data.consume_on_use:
		_consume_source_item(asc, handle)


func _on_drink_cancelled(_actor: Node, _handle: AbilitySpecHandle) -> void:
	GlobalLogger.log("[GA_Drink_Potion] Drink cancelled! Potion not consumed.")


func _get_potion_data_from_source(asc: AttributeSet, handle: AbilitySpecHandle) -> PotionData:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if not inventory or slot_index == -1: return null
	
	var stack = inventory.stacks[slot_index]
	if not stack: return null
	
	var item_def = inventory.database.get_item(stack.item_id)
	if not item_def: return null
	
	if not item_def.properties.has("potion_data"): return null
	return load(item_def.properties["potion_data"]) as PotionData


func _consume_source_item(asc: AttributeSet, handle: AbilitySpecHandle) -> void:
	var source = asc.get_ability_source(handle)
	var inventory: Inventory = source.get("inventory")
	var slot_index: int = source.get("slot", -1)
	
	if inventory and slot_index != -1:
		inventory.remove_at(slot_index, inventory.stacks[slot_index].item_id, 1)
