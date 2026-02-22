extends GutTest
## Tests for EffectManager - handles GameplayEffects (instant, duration, periodic)

var _effect_manager: EffectManager
var _attribute_set: GASAttributeSet
var _tag_container: TagContainer


func before_each() -> void:
	_tag_container = TagContainer.new()
	_attribute_set = GASAttributeSet.new()
	_effect_manager = EffectManager.new()
	
	add_child(_tag_container)
	add_child(_attribute_set)
	add_child(_effect_manager)
	
	# Initialize the effect manager's modifiers dictionary
	_effect_manager._ready()
	# Setup connections between components
	_effect_manager.setup(_attribute_set, _tag_container)


func after_each() -> void:
	_effect_manager.queue_free()
	_attribute_set.queue_free()
	_tag_container.queue_free()


# Helper to create a GameplayEffect for testing
func _create_effect(effect_name: String, mode: int, target_attr: String = "health", 
		operation: int = GameplayEffect.ModifierOp.SUBTRACT, value: float = 10.0,
		duration: float = 5.0, tick_rate: float = 1.0, tags: PackedStringArray = []) -> GameplayEffect:
	var effect = GameplayEffect.new()
	effect.effect_name = effect_name
	effect.mode = mode
	effect.target_attribute = target_attr
	effect.operation = operation
	effect.value = value
	effect.duration = duration
	effect.tick_rate = tick_rate
	effect.granted_tags = tags
	return effect


func test_apply_instant_effect() -> void:
	# INSTANT effect should immediately modify health
	var initial_health = _attribute_set.health
	
	var damage_effect = _create_effect(
		"Damage",
		GameplayEffect.ApplicationMode.INSTANT,
		"health",
		GameplayEffect.ModifierOp.SUBTRACT,
		25.0
	)
	
	var effects: Array[GameplayEffect] = [damage_effect]
	_effect_manager._apply_effects_logic(effects)
	
	assert_eq(_attribute_set.health, initial_health - 25.0, "Health should be reduced by 25")


func test_apply_duration_effect() -> void:
	# DURATION effect should modify stat while active
	var base_speed = _attribute_set.base_speed
	
	var speed_buff = _create_effect(
		"Speed Boost",
		GameplayEffect.ApplicationMode.DURATION,
		"speed",
		GameplayEffect.ModifierOp.ADD,
		5.0,
		10.0  # 10 second duration
	)
	
	var effects: Array[GameplayEffect] = [speed_buff]
	var handles = _effect_manager._apply_effects_logic(effects)
	
	assert_eq(handles.size(), 1, "Should return one handle")
	assert_eq(_attribute_set.speed, base_speed + 5.0, "Speed should be increased by 5")
	
	# Remove the effect
	_effect_manager._remove_effect_logic(handles[0])
	assert_eq(_attribute_set.speed, base_speed, "Speed should return to base after removal")


func test_apply_periodic_effect() -> void:
	# PERIODIC effect should apply damage each tick
	var initial_health = _attribute_set.health
	
	var dot_effect = _create_effect(
		"Poison",
		GameplayEffect.ApplicationMode.PERIODIC,
		"health",
		GameplayEffect.ModifierOp.SUBTRACT,
		5.0,
		3.0,  # 3 second duration
		1.0   # tick every 1 second
	)
	
	var effects: Array[GameplayEffect] = [dot_effect]
	_effect_manager._apply_effects_logic(effects)
	
	# Simulate 1 second passing - should trigger one tick
	_effect_manager._process_logic(1.0)
	assert_eq(_attribute_set.health, initial_health - 5.0, "Health should be reduced by one tick")
	
	# Simulate another second
	_effect_manager._process_logic(1.0)
	assert_eq(_attribute_set.health, initial_health - 10.0, "Health should be reduced by two ticks")


func test_remove_effect() -> void:
	# Removing an effect should clean up modifiers and tags
	var speed_buff = _create_effect(
		"Speed Boost",
		GameplayEffect.ApplicationMode.DURATION,
		"speed",
		GameplayEffect.ModifierOp.ADD,
		10.0,
		60.0,
		1.0,
		PackedStringArray(["buff.speed"])
	)
	
	var effects: Array[GameplayEffect] = [speed_buff]
	var handles = _effect_manager._apply_effects_logic(effects)
	
	assert_true(_tag_container.has_tag(&"buff.speed"), "Tag should be granted")
	assert_eq(_effect_manager.active_effect_registry.size(), 1, "Effect should be registered")
	
	_effect_manager._remove_effect_logic(handles[0])
	
	assert_false(_tag_container.has_tag(&"buff.speed"), "Tag should be removed")
	assert_eq(_effect_manager.active_effect_registry.size(), 0, "Effect should be unregistered")


func test_effect_grants_tags() -> void:
	# Effects should grant their tags when applied
	var tag_effect = _create_effect(
		"Burning",
		GameplayEffect.ApplicationMode.DURATION,
		"none",  # Tag-only effect
		GameplayEffect.ModifierOp.ADD,
		0.0,
		5.0,
		1.0,
		PackedStringArray(["state.burning", "debuff.fire"])
	)
	
	var effects: Array[GameplayEffect] = [tag_effect]
	_effect_manager._apply_effects_logic(effects)
	
	assert_true(_tag_container.has_tag(&"state.burning"), "Should have burning tag")
	assert_true(_tag_container.has_tag(&"debuff.fire"), "Should have fire debuff tag")


func test_compute_stat_modifiers() -> void:
	# Test all modifier operations: ADD, SUBTRACT, MULTIPLY, DIVIDE
	var base_speed = _attribute_set.base_speed  # 5.0
	
	# ADD modifier
	var add_effect = _create_effect("Add", GameplayEffect.ApplicationMode.INFINITE, "speed", 
		GameplayEffect.ModifierOp.ADD, 3.0)
	var effects: Array[GameplayEffect] = [add_effect]
	var handles = _effect_manager._apply_effects_logic(effects)
	assert_eq(_attribute_set.speed, base_speed + 3.0, "ADD should increase speed")
	_effect_manager._remove_effect_logic(handles[0])
	
	# MULTIPLY modifier
	var mult_effect = _create_effect("Multiply", GameplayEffect.ApplicationMode.INFINITE, "speed",
		GameplayEffect.ModifierOp.MULTIPLY, 2.0)
	effects = [mult_effect]
	handles = _effect_manager._apply_effects_logic(effects)
	assert_eq(_attribute_set.speed, base_speed * 2.0, "MULTIPLY should double speed")
	_effect_manager._remove_effect_logic(handles[0])
	
	# DIVIDE modifier
	var div_effect = _create_effect("Divide", GameplayEffect.ApplicationMode.INFINITE, "speed",
		GameplayEffect.ModifierOp.DIVIDE, 2.0)
	effects = [div_effect]
	handles = _effect_manager._apply_effects_logic(effects)
	assert_eq(_attribute_set.speed, base_speed / 2.0, "DIVIDE should halve speed")
	_effect_manager._remove_effect_logic(handles[0])


func test_duration_effect_expires() -> void:
	# DURATION effects should expire after their duration
	var buff = _create_effect(
		"Temp Buff",
		GameplayEffect.ApplicationMode.DURATION,
		"speed",
		GameplayEffect.ModifierOp.ADD,
		10.0,
		2.0  # 2 second duration
	)
	
	var effects: Array[GameplayEffect] = [buff]
	_effect_manager._apply_effects_logic(effects)
	
	var base_speed = _attribute_set.base_speed
	assert_eq(_attribute_set.speed, base_speed + 10.0, "Speed should be buffed initially")
	
	# Simulate time passing (not enough to expire)
	_effect_manager._process_logic(1.0)
	assert_eq(_attribute_set.speed, base_speed + 10.0, "Speed should still be buffed")
	
	# Simulate more time (effect should expire)
	_effect_manager._process_logic(1.5)
	assert_eq(_attribute_set.speed, base_speed, "Speed should return to base after expiration")
	assert_eq(_effect_manager.active_effect_registry.size(), 0, "Effect should be removed from registry")
