extends GutTest
## Tests for PotionData Resource structure and data integrity


func test_potion_default_values() -> void:
	# Verify default values are correct for a new PotionData
	var potion = PotionData.new()
	
	# Physics & Visuals
	assert_null(potion.projectile_scene, "Default projectile_scene should be null")
	assert_eq(potion.throw_force, 15.0, "Default throw_force should be 15.0")
	
	# Explosion Settings
	assert_eq(potion.blast_radius, 3.0, "Default blast_radius should be 3.0")
	assert_eq(potion.area_effect_duration, 0.5, "Default area_effect_duration should be 0.5")
	
	# Gameplay Effects
	assert_true(potion.effects is Array, "effects should be an Array")
	assert_eq(potion.effects.size(), 0, "Default effects should be empty")
	
	# Inventory Item Settings
	assert_true(potion.consume_on_use, "Default consume_on_use should be true")
	
	# Drink Properties
	assert_eq(potion.drink_animation_name, "drink_potion", "Default drink_animation_name should be 'drink_potion'")
	assert_true(potion.consumed_effects is Array, "consumed_effects should be an Array")
	assert_eq(potion.consumed_effects.size(), 0, "Default consumed_effects should be empty")
	assert_eq(potion.drink_duration, 1.5, "Default drink_duration should be 1.5")


func test_potion_effects_arrays() -> void:
	# Verify effects and consumed_effects accept GameplayEffect
	var potion = PotionData.new()
	
	# Create throw/splash effects (applied to targets hit)
	var fire_effect = GameplayEffect.new()
	fire_effect.effect_name = "Fire Damage"
	fire_effect.mode = GameplayEffect.ApplicationMode.PERIODIC
	fire_effect.target_attribute = "health"
	fire_effect.operation = GameplayEffect.ModifierOp.SUBTRACT
	fire_effect.value = 5.0
	fire_effect.duration = 3.0
	fire_effect.tick_rate = 1.0
	fire_effect.granted_tags = PackedStringArray(["state.burning"])
	
	var burn_tag = GameplayEffect.new()
	burn_tag.effect_name = "Burning Status"
	burn_tag.mode = GameplayEffect.ApplicationMode.DURATION
	burn_tag.target_attribute = "none"
	burn_tag.duration = 5.0
	burn_tag.granted_tags = PackedStringArray(["state.fire", "debuff.dot"])
	
	potion.effects.append(fire_effect)
	potion.effects.append(burn_tag)
	assert_eq(potion.effects.size(), 2, "Should have 2 throw effects")
	assert_eq(potion.effects[0].effect_name, "Fire Damage", "First effect should be Fire Damage")
	assert_eq(potion.effects[1].effect_name, "Burning Status", "Second effect should be Burning Status")
	
	# Create drink/consumed effects (applied to self)
	var heal_effect = GameplayEffect.new()
	heal_effect.effect_name = "Heal"
	heal_effect.mode = GameplayEffect.ApplicationMode.INSTANT
	heal_effect.target_attribute = "health"
	heal_effect.operation = GameplayEffect.ModifierOp.ADD
	heal_effect.value = 50.0
	
	potion.consumed_effects.append(heal_effect)
	assert_eq(potion.consumed_effects.size(), 1, "Should have 1 consumed effect")
	assert_eq(potion.consumed_effects[0].effect_name, "Heal", "Consumed effect should be Heal")


func test_potion_physics_properties() -> void:
	# Verify physics properties are valid positive values
	var potion = PotionData.new()
	
	# Test default values are positive
	assert_gt(potion.throw_force, 0.0, "throw_force should be positive")
	assert_gt(potion.blast_radius, 0.0, "blast_radius should be positive")
	assert_gt(potion.area_effect_duration, 0.0, "area_effect_duration should be positive")
	
	# Test custom values can be set
	potion.throw_force = 25.0
	assert_eq(potion.throw_force, 25.0, "Should accept custom throw_force")
	
	potion.blast_radius = 5.0
	assert_eq(potion.blast_radius, 5.0, "Should accept custom blast_radius")
	
	potion.area_effect_duration = 2.0
	assert_eq(potion.area_effect_duration, 2.0, "Should accept custom area_effect_duration")


func test_potion_drink_properties() -> void:
	# Verify drink properties are valid
	var potion = PotionData.new()
	
	# Test default drink_duration is positive
	assert_gt(potion.drink_duration, 0.0, "drink_duration should be positive")
	
	# Test custom drink duration
	potion.drink_duration = 3.0
	assert_eq(potion.drink_duration, 3.0, "Should accept custom drink_duration")
	
	# Test drink animation name
	potion.drink_animation_name = "custom_drink"
	assert_eq(potion.drink_animation_name, "custom_drink", "Should accept custom drink_animation_name")
	
	# Test consume_on_use can be toggled
	potion.consume_on_use = false
	assert_false(potion.consume_on_use, "consume_on_use should be false")
	
	potion.consume_on_use = true
	assert_true(potion.consume_on_use, "consume_on_use should be true")
