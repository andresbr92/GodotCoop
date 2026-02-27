extends GutTest
## Tests for EquipmentData Resource structure and data integrity


func test_equipment_slot_types_enum() -> void:
	# Verify SlotType enum has all expected values
	assert_eq(EquipmentData.SlotType.HEAD, 0, "HEAD should be 0")
	assert_eq(EquipmentData.SlotType.CHEST, 1, "CHEST should be 1")
	assert_eq(EquipmentData.SlotType.HAND, 2, "HAND should be 2")
	assert_eq(EquipmentData.SlotType.BELT, 3, "BELT should be 3")
	
	# Test that equipment can use each slot type
	var equipment = EquipmentData.new()
	
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.HEAD)
	assert_true(EquipmentData.SlotType.HEAD in equipment.allowed_slots, "Should accept HEAD slot")
	
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.CHEST)
	assert_true(EquipmentData.SlotType.CHEST in equipment.allowed_slots, "Should accept CHEST slot")
	
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.HAND)
	assert_true(EquipmentData.SlotType.HAND in equipment.allowed_slots, "Should accept HAND slot")
	
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.BELT)
	assert_true(EquipmentData.SlotType.BELT in equipment.allowed_slots, "Should accept BELT slot")


func test_equipment_default_values() -> void:
	# Verify default values are correct for a new EquipmentData
	var equipment = EquipmentData.new()
	
	assert_true(equipment.allowed_slots is Array, "allowed_slots should be an Array")
	assert_eq(equipment.allowed_slots.size(), 0, "Default allowed_slots should be empty")
	# NOTE: visual_scene and bone_name removed - visuals now come from ItemDefinition.properties["hand_item"]
	assert_true(equipment.passive_effects is Array, "passive_effects should be an Array")
	assert_eq(equipment.passive_effects.size(), 0, "Default passive_effects should be empty")
	assert_true(equipment.granted_abilities is Array, "granted_abilities should be an Array")
	assert_eq(equipment.granted_abilities.size(), 0, "Default granted_abilities should be empty")


func test_equipment_arrays_typed() -> void:
	# Verify arrays accept correct types
	var equipment = EquipmentData.new()
	
	# Test passive_effects accepts GameplayEffect
	var effect = GameplayEffect.new()
	effect.effect_name = "Armor Buff"
	effect.mode = GameplayEffect.ApplicationMode.INFINITE
	effect.target_attribute = "max_health"
	effect.operation = GameplayEffect.ModifierOp.ADD
	effect.value = 50.0
	
	equipment.passive_effects.append(effect)
	assert_eq(equipment.passive_effects.size(), 1, "Should have 1 passive effect")
	assert_eq(equipment.passive_effects[0].effect_name, "Armor Buff", "Effect should be Armor Buff")
	
	# Test granted_abilities accepts AbilityGrant
	var ability = GameplayAbility.new()
	ability.ability_name = "Sword Slash"
	
	var grant = AbilityGrant.new()
	grant.ability = ability
	grant.input_tag = "ability.primary"
	
	equipment.granted_abilities.append(grant)
	assert_eq(equipment.granted_abilities.size(), 1, "Should have 1 granted ability")
	assert_eq(equipment.granted_abilities[0].ability.ability_name, "Sword Slash", "Ability should be Sword Slash")
	assert_eq(equipment.granted_abilities[0].input_tag, "ability.primary", "Input tag should be ability.primary")


func test_equipment_can_have_multiple_slots() -> void:
	# Verify equipment can be assigned to multiple slot types (e.g., potion can go in HAND or BELT)
	var equipment = EquipmentData.new()
	
	# Single slot
	equipment.allowed_slots.append(EquipmentData.SlotType.HEAD)
	assert_eq(equipment.allowed_slots.size(), 1, "Should have 1 allowed slot")
	
	# Multiple slots (like a potion that can go in hand or belt)
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.HAND)
	equipment.allowed_slots.append(EquipmentData.SlotType.BELT)
	assert_eq(equipment.allowed_slots.size(), 2, "Should have 2 allowed slots")
	assert_true(EquipmentData.SlotType.HAND in equipment.allowed_slots, "Should allow HAND slot")
	assert_true(EquipmentData.SlotType.BELT in equipment.allowed_slots, "Should allow BELT slot")
	
	# All slots (hypothetical universal item)
	equipment.allowed_slots.clear()
	equipment.allowed_slots.append(EquipmentData.SlotType.HEAD)
	equipment.allowed_slots.append(EquipmentData.SlotType.CHEST)
	equipment.allowed_slots.append(EquipmentData.SlotType.HAND)
	equipment.allowed_slots.append(EquipmentData.SlotType.BELT)
	assert_eq(equipment.allowed_slots.size(), 4, "Should have 4 allowed slots")
