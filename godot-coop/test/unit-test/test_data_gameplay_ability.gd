extends GutTest
## Tests for GameplayAbility Resource structure and data integrity


func test_ability_default_values() -> void:
	# Verify default values are correct for a new GameplayAbility
	var ability = GameplayAbility.new()
	
	assert_eq(ability.ability_name, "Base Ability", "Default ability_name should be 'Base Ability'")
	assert_true(ability.activation_required_tags is PackedStringArray, "activation_required_tags should be PackedStringArray")
	assert_eq(ability.activation_required_tags.size(), 0, "Default activation_required_tags should be empty")
	assert_true(ability.activation_blocked_tags is PackedStringArray, "activation_blocked_tags should be PackedStringArray")
	assert_eq(ability.activation_blocked_tags.size(), 0, "Default activation_blocked_tags should be empty")


func test_ability_tags_are_arrays() -> void:
	# Verify tags can be set and are proper PackedStringArray
	var ability = GameplayAbility.new()
	
	# Set required tags
	ability.activation_required_tags = PackedStringArray(["state.grounded", "state.alive"])
	assert_eq(ability.activation_required_tags.size(), 2, "Should have 2 required tags")
	assert_true("state.grounded" in ability.activation_required_tags, "Should contain grounded tag")
	assert_true("state.alive" in ability.activation_required_tags, "Should contain alive tag")
	
	# Set blocked tags
	ability.activation_blocked_tags = PackedStringArray(["state.stunned", "state.dead", "state.casting"])
	assert_eq(ability.activation_blocked_tags.size(), 3, "Should have 3 blocked tags")
	assert_true("state.stunned" in ability.activation_blocked_tags, "Should contain stunned tag")
	assert_true("state.dead" in ability.activation_blocked_tags, "Should contain dead tag")
	assert_true("state.casting" in ability.activation_blocked_tags, "Should contain casting tag")


func test_ability_ongoing_effects_type() -> void:
	# Verify ongoing_effects is properly typed array
	var ability = GameplayAbility.new()
	
	# Default should be empty array
	assert_true(ability.ongoing_effects is Array, "ongoing_effects should be an Array")
	assert_eq(ability.ongoing_effects.size(), 0, "Default ongoing_effects should be empty")
	
	# Create and add effects
	var effect1 = GameplayEffect.new()
	effect1.effect_name = "Ongoing Buff"
	effect1.mode = GameplayEffect.ApplicationMode.INFINITE
	effect1.target_attribute = "speed"
	effect1.operation = GameplayEffect.ModifierOp.ADD
	effect1.value = 2.0
	
	var effect2 = GameplayEffect.new()
	effect2.effect_name = "Ongoing Tag"
	effect2.mode = GameplayEffect.ApplicationMode.INFINITE
	effect2.target_attribute = "none"
	effect2.granted_tags = PackedStringArray(["state.aiming"])
	
	ability.ongoing_effects.append(effect1)
	ability.ongoing_effects.append(effect2)
	
	assert_eq(ability.ongoing_effects.size(), 2, "Should have 2 ongoing effects")
	assert_eq(ability.ongoing_effects[0].effect_name, "Ongoing Buff", "First effect should be Ongoing Buff")
	assert_eq(ability.ongoing_effects[1].effect_name, "Ongoing Tag", "Second effect should be Ongoing Tag")


func test_ability_virtual_methods_exist() -> void:
	# Verify that virtual methods exist and can be called
	var ability = GameplayAbility.new()
	
	# Check methods exist
	assert_true(ability.has_method("can_activate"), "Should have can_activate method")
	assert_true(ability.has_method("activate"), "Should have activate method")
	assert_true(ability.has_method("input_released"), "Should have input_released method")
	assert_true(ability.has_method("end_ability"), "Should have end_ability method")
	
	# Create a mock actor node for testing
	var mock_actor = Node.new()
	add_child(mock_actor)
	
	# Test that methods can be called without crashing
	# Note: can_activate needs an AbilitySystemComponent, so it will return false
	var can_activate_result = ability.can_activate(mock_actor)
	assert_false(can_activate_result, "can_activate should return false without ASC")
	
	# Create a mock handle
	var mock_handle = AbilitySpecHandle.new("TestAbility")
	
	# These should not crash when called (they are virtual/base implementations)
	ability.activate(mock_actor, mock_handle, {})
	ability.input_released(mock_actor, mock_handle)
	ability.end_ability(mock_actor, mock_handle)
	
	# If we got here without crashing, the methods work
	assert_true(true, "Virtual methods can be called without crashing")
	
	mock_actor.queue_free()
