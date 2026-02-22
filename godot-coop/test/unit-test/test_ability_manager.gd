extends GutTest
## Tests for AbilityManager - handles granting, clearing, and activating GameplayAbilities

var _ability_manager: AbilityManager
var _effect_manager: EffectManager
var _tag_container: TagContainer
var _cast_manager: CastManager
var _attribute_set: GASAttributeSet
var _mock_actor: Node


func before_each() -> void:
	_tag_container = TagContainer.new()
	_attribute_set = GASAttributeSet.new()
	_effect_manager = EffectManager.new()
	_cast_manager = CastManager.new()
	_ability_manager = AbilityManager.new()
	_mock_actor = Node.new()
	
	add_child(_tag_container)
	add_child(_attribute_set)
	add_child(_effect_manager)
	add_child(_cast_manager)
	add_child(_ability_manager)
	add_child(_mock_actor)
	
	# Initialize components
	_effect_manager._ready()
	_effect_manager.setup(_attribute_set, _tag_container)
	_ability_manager.setup(_mock_actor, _effect_manager, _tag_container, _cast_manager)


func after_each() -> void:
	_ability_manager.queue_free()
	_cast_manager.queue_free()
	_effect_manager.queue_free()
	_attribute_set.queue_free()
	_tag_container.queue_free()
	_mock_actor.queue_free()


# Helper to create a test GameplayAbility
func _create_ability(ability_name: String, required_tags: PackedStringArray = [], 
		blocked_tags: PackedStringArray = []) -> GameplayAbility:
	var ability = GameplayAbility.new()
	ability.ability_name = ability_name
	ability.activation_required_tags = required_tags
	ability.activation_blocked_tags = blocked_tags
	return ability


func test_grant_ability() -> void:
	# Granting an ability should register it and return a handle
	var test_ability = _create_ability("Test Ability")
	
	var handle = _ability_manager._grant_ability_logic(test_ability, "ability.primary")
	
	assert_not_null(handle, "Should return a valid handle")
	assert_true(_ability_manager.granted_abilities.has(handle), "Ability should be registered")
	
	var spec = _ability_manager.granted_abilities[handle]
	assert_eq(spec.ability, test_ability, "Stored ability should match")
	assert_eq(spec.input_tag, "ability.primary", "Input tag should match")


func test_clear_ability() -> void:
	# Clearing an ability should remove it from granted_abilities
	var test_ability = _create_ability("Test Ability")
	var handle = _ability_manager._grant_ability_logic(test_ability, "ability.primary")
	
	assert_eq(_ability_manager.granted_abilities.size(), 1, "Should have one ability")
	
	_ability_manager._clear_ability_logic(handle)
	
	assert_eq(_ability_manager.granted_abilities.size(), 0, "Should have no abilities after clear")
	assert_false(_ability_manager.granted_abilities.has(handle), "Handle should be removed")


func test_can_activate_with_required_tags() -> void:
	# Ability with required tags should only activate when tags are present
	var ability_with_requirements = _create_ability(
		"Grounded Attack",
		PackedStringArray(["state.grounded"]),  # Requires grounded tag
		PackedStringArray()
	)
	
	# Without required tag - should NOT be able to activate
	assert_false(
		_ability_manager.can_activate_ability(ability_with_requirements),
		"Should not activate without required tag"
	)
	
	# Add the required tag
	_tag_container._add_tag_logic(&"state.grounded")
	
	# With required tag - should be able to activate
	assert_true(
		_ability_manager.can_activate_ability(ability_with_requirements),
		"Should activate with required tag"
	)


func test_can_activate_with_blocked_tags() -> void:
	# Ability with blocked tags should NOT activate when those tags are present
	var ability_blocked_by_stun = _create_ability(
		"Attack",
		PackedStringArray(),
		PackedStringArray(["state.stunned"])  # Blocked by stunned
	)
	
	# Without blocking tag - should be able to activate
	assert_true(
		_ability_manager.can_activate_ability(ability_blocked_by_stun),
		"Should activate without blocking tag"
	)
	
	# Add the blocking tag
	_tag_container._add_tag_logic(&"state.stunned")
	
	# With blocking tag - should NOT be able to activate
	assert_false(
		_ability_manager.can_activate_ability(ability_blocked_by_stun),
		"Should not activate with blocking tag"
	)


func test_ability_source_tracking() -> void:
	# get_ability_source should return the inventory and slot info
	var test_ability = _create_ability("Item Ability")
	
	# Create a mock inventory (just a Node for testing)
	var mock_inventory = Inventory.new()
	add_child(mock_inventory)
	
	var handle = _ability_manager._grant_ability_logic(
		test_ability, 
		"ability.primary",
		mock_inventory,
		2  # slot index
	)
	
	var source = _ability_manager.get_ability_source(handle)
	
	assert_eq(source["inventory"], mock_inventory, "Should return correct inventory")
	assert_eq(source["slot"], 2, "Should return correct slot index")
	
	# Test with non-existent handle
	var fake_handle = AbilitySpecHandle.new("Fake")
	var empty_source = _ability_manager.get_ability_source(fake_handle)
	assert_true(empty_source.is_empty(), "Should return empty dict for invalid handle")
	
	mock_inventory.queue_free()
