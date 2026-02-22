class_name EffectManager
extends Node

class ActiveEffect:
	var handle: EffectSpecHandle
	var source_effect: GameplayEffect
	var time_left: float
	var tick_timer: float
	
	func _init(p_handle: EffectSpecHandle, effect: GameplayEffect):
		handle = p_handle
		source_effect = effect
		time_left = effect.duration
		tick_timer = 0.0

var _attribute_set: GASAttributeSet
var _tag_container: TagContainer

var active_effect_registry: Dictionary = {}
var active_modifiers: Dictionary = {}
var active_periodic_effects: Array[ActiveEffect] = []
## Duration effects that only apply tags (no attribute modification)
var active_duration_tag_effects: Array[ActiveEffect] = []


func _ready() -> void:
	for attr in GASAttributeSet.VALID_ATTRIBUTES:
		active_modifiers[attr] = []


func setup(attribute_set: GASAttributeSet, tag_container: TagContainer) -> void:
	_attribute_set = attribute_set
	_tag_container = tag_container
	_attribute_set.set_effect_manager(self)


func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	_process_periodic_effects(delta)
	_process_duration_modifiers(delta)
	_process_duration_tag_effects(delta)


## Returns true if the effect has a valid target attribute (not "none" or empty)
func _has_valid_attribute(effect: GameplayEffect) -> bool:
	return effect.target_attribute != "" and effect.target_attribute != "none"


func apply_effects(effects: Array[GameplayEffect]) -> Array[EffectSpecHandle]:
	if not multiplayer.is_server(): return []
	
	var created_handles: Array[EffectSpecHandle] = []
	
	for effect in effects:
		var has_attribute = _has_valid_attribute(effect)
		
		match effect.mode:
			GameplayEffect.ApplicationMode.INSTANT:
				GlobalLogger.log("[EffectManager] Applying INSTANT effect: '", effect.effect_name, "'")
				if has_attribute:
					_apply_instant_effect(effect)
				# For INSTANT tag-only effects, just apply tags (they stay until manually removed)
				for tag in effect.granted_tags:
					_tag_container.add_tag(tag)
				
			GameplayEffect.ApplicationMode.PERIODIC:
				var handle = _create_active_effect(effect)
				GlobalLogger.log("[EffectManager] Added PERIODIC effect: '", effect.effect_name, "' Handle: ", handle)
				if has_attribute:
					active_periodic_effects.append(active_effect_registry[handle])
				created_handles.append(handle)
				
			GameplayEffect.ApplicationMode.DURATION, GameplayEffect.ApplicationMode.INFINITE:
				var handle = _create_active_effect(effect)
				GlobalLogger.log("[EffectManager] Added DURATION effect: '", effect.effect_name, "' Handle: ", handle)
				if has_attribute:
					active_modifiers[effect.target_attribute].append(active_effect_registry[handle])
					_on_modifier_changed(effect.target_attribute)
				else:
					# Tag-only duration effect - track separately for expiration
					active_duration_tag_effects.append(active_effect_registry[handle])
				created_handles.append(handle)
	
	return created_handles


func remove_effect(handle: EffectSpecHandle) -> void:
	if not multiplayer.is_server(): return
	
	if not active_effect_registry.has(handle):
		GlobalLogger.log("[EffectManager] Warning: Effect not found: ", handle)
		return
	
	var active_effect = active_effect_registry[handle]
	var source_data = active_effect.source_effect
	
	for tag in source_data.granted_tags:
		_tag_container.remove_tag(tag)
	
	GlobalLogger.log("[EffectManager] Removing effect: ", handle)
	
	var has_attribute = _has_valid_attribute(source_data)
	
	match source_data.mode:
		GameplayEffect.ApplicationMode.PERIODIC:
			active_periodic_effects.erase(active_effect)
			
		GameplayEffect.ApplicationMode.DURATION, GameplayEffect.ApplicationMode.INFINITE:
			if has_attribute:
				var attr_name = source_data.target_attribute
				if active_modifiers.has(attr_name):
					active_modifiers[attr_name].erase(active_effect)
					_on_modifier_changed(attr_name)
			else:
				# Tag-only duration effect
				active_duration_tag_effects.erase(active_effect)
	
	active_effect_registry.erase(handle)


func compute_stat_with_modifiers(stat_name: String, base_value: float) -> float:
	var final_value = base_value
	var multiplier = 1.0
	
	if not active_modifiers.has(stat_name):
		return base_value
	
	for active in active_modifiers[stat_name]:
		var eff = active.source_effect
		match eff.operation:
			GameplayEffect.ModifierOp.ADD: 
				final_value += eff.value
			GameplayEffect.ModifierOp.SUBTRACT: 
				final_value -= eff.value
			GameplayEffect.ModifierOp.MULTIPLY: 
				multiplier *= eff.value
			GameplayEffect.ModifierOp.DIVIDE: 
				if eff.value != 0: 
					multiplier /= eff.value
			
	return final_value * multiplier


func _create_active_effect(effect: GameplayEffect) -> EffectSpecHandle:
	var handle = EffectSpecHandle.new(effect.effect_name)
	var active = ActiveEffect.new(handle, effect)
	active_effect_registry[handle] = active
	
	for tag in effect.granted_tags:
		_tag_container.add_tag(tag)

	return handle


func _apply_instant_effect(effect: GameplayEffect) -> void:
	_attribute_set.apply_instant_change(effect.target_attribute, effect.value, effect.operation)


func _on_modifier_changed(stat_name: String) -> void:
	GlobalLogger.log("[EffectManager] Recalculating stat: ", stat_name, " | New Total: ", _attribute_set.get_computed_stat(stat_name))
	if stat_name == "max_health":
		_attribute_set.on_max_health_changed()


func _process_periodic_effects(delta: float) -> void:
	for i in range(active_periodic_effects.size() - 1, -1, -1):
		var active = active_periodic_effects[i]
		active.time_left -= delta
		active.tick_timer += delta
		
		if active.tick_timer >= active.source_effect.tick_rate:
			active.tick_timer = 0.0
			# Only apply attribute change if target_attribute is valid
			if _has_valid_attribute(active.source_effect):
				_apply_instant_effect(active.source_effect)
			
		if active.time_left <= 0:
			active_effect_registry.erase(active.handle)
			active_periodic_effects.remove_at(i)
			for tag in active.source_effect.granted_tags:
				_tag_container.remove_tag(tag)


func _process_duration_modifiers(delta: float) -> void:
	for attr in active_modifiers.keys():
		var modifiers_list = active_modifiers[attr]
		var changed = false
		
		for i in range(modifiers_list.size() - 1, -1, -1):
			var active = modifiers_list[i]
			if active.source_effect.mode == GameplayEffect.ApplicationMode.INFINITE:
				continue
			
			active.time_left -= delta
			if active.time_left <= 0:
				for tag in active.source_effect.granted_tags:
					_tag_container.remove_tag(tag)
				active_effect_registry.erase(active.handle)
				modifiers_list.remove_at(i)
				changed = true
		
		if changed:
			_on_modifier_changed(attr)


## Process duration effects that only have tags (no attribute modification)
func _process_duration_tag_effects(delta: float) -> void:
	for i in range(active_duration_tag_effects.size() - 1, -1, -1):
		var active = active_duration_tag_effects[i]
		if active.source_effect.mode == GameplayEffect.ApplicationMode.INFINITE:
			continue
		
		active.time_left -= delta
		if active.time_left <= 0:
			GlobalLogger.log("[EffectManager] Duration tag effect expired: '", active.source_effect.effect_name, "'")
			for tag in active.source_effect.granted_tags:
				_tag_container.remove_tag(tag)
			active_effect_registry.erase(active.handle)
			active_duration_tag_effects.remove_at(i)
