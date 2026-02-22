extends GutTest
## Tests for GameplayEffect Resource structure and data integrity


func test_effect_default_values() -> void:
	# Verify default values are correct for a new GameplayEffect
	var effect = GameplayEffect.new()
	
	assert_eq(effect.target_attribute, "", "Default target_attribute should be empty string")
	assert_eq(effect.operation, GameplayEffect.ModifierOp.SUBTRACT, "Default operation should be SUBTRACT")
	assert_eq(effect.value, 10.0, "Default value should be 10.0")
	assert_eq(effect.mode, GameplayEffect.ApplicationMode.INSTANT, "Default mode should be INSTANT")
	assert_eq(effect.duration, 0.0, "Default duration should be 0.0")
	assert_eq(effect.tick_rate, 1.0, "Default tick_rate should be 1.0")
	assert_eq(effect.effect_name, "Generic Effect", "Default effect_name should be 'Generic Effect'")
	assert_eq(effect.vfx_tag, "", "Default vfx_tag should be empty")
	assert_true(effect.granted_tags is PackedStringArray, "granted_tags should be PackedStringArray")
	assert_eq(effect.granted_tags.size(), 0, "Default granted_tags should be empty")


func test_effect_modes_enum() -> void:
	# Verify ApplicationMode enum has all expected values
	assert_eq(GameplayEffect.ApplicationMode.INSTANT, 0, "INSTANT should be 0")
	assert_eq(GameplayEffect.ApplicationMode.PERIODIC, 1, "PERIODIC should be 1")
	assert_eq(GameplayEffect.ApplicationMode.DURATION, 2, "DURATION should be 2")
	assert_eq(GameplayEffect.ApplicationMode.INFINITE, 3, "INFINITE should be 3")
	
	# Test that we can create effects with each mode
	var effect = GameplayEffect.new()
	
	effect.mode = GameplayEffect.ApplicationMode.INSTANT
	assert_eq(effect.mode, GameplayEffect.ApplicationMode.INSTANT, "Should accept INSTANT mode")
	
	effect.mode = GameplayEffect.ApplicationMode.PERIODIC
	assert_eq(effect.mode, GameplayEffect.ApplicationMode.PERIODIC, "Should accept PERIODIC mode")
	
	effect.mode = GameplayEffect.ApplicationMode.DURATION
	assert_eq(effect.mode, GameplayEffect.ApplicationMode.DURATION, "Should accept DURATION mode")
	
	effect.mode = GameplayEffect.ApplicationMode.INFINITE
	assert_eq(effect.mode, GameplayEffect.ApplicationMode.INFINITE, "Should accept INFINITE mode")


func test_effect_operations_enum() -> void:
	# Verify ModifierOp enum has all expected values
	assert_eq(GameplayEffect.ModifierOp.ADD, 0, "ADD should be 0")
	assert_eq(GameplayEffect.ModifierOp.SUBTRACT, 1, "SUBTRACT should be 1")
	assert_eq(GameplayEffect.ModifierOp.MULTIPLY, 2, "MULTIPLY should be 2")
	assert_eq(GameplayEffect.ModifierOp.DIVIDE, 3, "DIVIDE should be 3")
	
	# Test that we can create effects with each operation
	var effect = GameplayEffect.new()
	
	effect.operation = GameplayEffect.ModifierOp.ADD
	assert_eq(effect.operation, GameplayEffect.ModifierOp.ADD, "Should accept ADD operation")
	
	effect.operation = GameplayEffect.ModifierOp.SUBTRACT
	assert_eq(effect.operation, GameplayEffect.ModifierOp.SUBTRACT, "Should accept SUBTRACT operation")
	
	effect.operation = GameplayEffect.ModifierOp.MULTIPLY
	assert_eq(effect.operation, GameplayEffect.ModifierOp.MULTIPLY, "Should accept MULTIPLY operation")
	
	effect.operation = GameplayEffect.ModifierOp.DIVIDE
	assert_eq(effect.operation, GameplayEffect.ModifierOp.DIVIDE, "Should accept DIVIDE operation")


func test_effect_valid_attributes() -> void:
	# Verify that valid attributes are defined in GASAttributeSet
	var valid_attrs = GASAttributeSet.VALID_ATTRIBUTES
	
	assert_true(valid_attrs is PackedStringArray, "VALID_ATTRIBUTES should be PackedStringArray")
	assert_true(valid_attrs.size() > 0, "Should have at least one valid attribute")
	
	# Check expected attributes exist
	assert_true("health" in valid_attrs, "health should be a valid attribute")
	assert_true("max_health" in valid_attrs, "max_health should be a valid attribute")
	assert_true("speed" in valid_attrs, "speed should be a valid attribute")
	
	# Test setting target_attribute to valid values
	var effect = GameplayEffect.new()
	
	effect.target_attribute = "health"
	assert_eq(effect.target_attribute, "health", "Should accept 'health' as target")
	
	effect.target_attribute = "none"
	assert_eq(effect.target_attribute, "none", "Should accept 'none' for tag-only effects")
	
	effect.target_attribute = ""
	assert_eq(effect.target_attribute, "", "Should accept empty string for tag-only effects")


func test_effect_tag_only_mode() -> void:
	# Verify effects can work without targeting an attribute (tag-only)
	var tag_effect = GameplayEffect.new()
	tag_effect.effect_name = "Burning Status"
	tag_effect.target_attribute = "none"
	tag_effect.mode = GameplayEffect.ApplicationMode.DURATION
	tag_effect.duration = 5.0
	tag_effect.granted_tags = PackedStringArray(["state.burning", "debuff.fire"])
	
	assert_eq(tag_effect.target_attribute, "none", "Tag-only effect should have 'none' as target")
	assert_eq(tag_effect.granted_tags.size(), 2, "Should have 2 granted tags")
	assert_true("state.burning" in tag_effect.granted_tags, "Should contain burning tag")
	assert_true("debuff.fire" in tag_effect.granted_tags, "Should contain fire debuff tag")
	
	# Also test with empty string
	var tag_effect2 = GameplayEffect.new()
	tag_effect2.target_attribute = ""
	tag_effect2.granted_tags = PackedStringArray(["state.stunned"])
	
	assert_eq(tag_effect2.target_attribute, "", "Tag-only effect can use empty string")
	assert_eq(tag_effect2.granted_tags.size(), 1, "Should have 1 granted tag")
