extends GutTest
## Tests for data integrity - verifies all .tres files load correctly
## These tests catch breaking changes in Resource structure


func test_load_all_gameplay_effects() -> void:
	# Verify all GameplayEffect .tres files load without errors
	var effect_paths = [
		"res://items/definitions/gameplay_effects/GE_HealOverTime.tres",
		"res://items/definitions/gameplay_effects/GE_InstantDamage_10.tres",
	]
	
	for path in effect_paths:
		var effect = load(path)
		assert_not_null(effect, "Should load effect: " + path)
		if effect:
			assert_true(effect is GameplayEffect, path + " should be GameplayEffect")
			assert_ne(effect.effect_name, "", path + " should have effect_name")


func test_load_all_equipment_data() -> void:
	# Verify all EquipmentData .tres files load without errors
	var equipment_paths = [
		"res://items/definitions/equipment/EqData_Potion.tres"
	]
	
	for path in equipment_paths:
		var equipment = load(path)
		assert_not_null(equipment, "Should load equipment: " + path)
		if equipment:
			assert_true(equipment is EquipmentData, path + " should be EquipmentData")
			assert_gt(equipment.allowed_slots.size(), 0, path + " should have at least one allowed slot")


func test_load_all_potion_data() -> void:
	# Verify all PotionData .tres files load without errors
	var potion_paths = [
		"res://items/definitions/potion/FirePotionData.tres",
		"res://items/definitions/potion/HealPotionData.tres",
	]
	
	for path in potion_paths:
		var potion = load(path)
		assert_not_null(potion, "Should load potion: " + path)
		if potion:
			assert_true(potion is PotionData, path + " should be PotionData")
			assert_gt(potion.throw_force, 0.0, path + " should have positive throw_force")


func test_equipment_references_valid() -> void:
	# Verify that EquipmentData references (abilities, effects) are valid
	var equipment_paths = [
		"res://items/definitions/equipment/EqData_Potion.tres"
	]
	
	for path in equipment_paths:
		var equipment = load(path) as EquipmentData
		if not equipment:
			continue
		
		# Check passive_effects are valid GameplayEffect
		for i in range(equipment.passive_effects.size()):
			var effect = equipment.passive_effects[i]
			assert_not_null(effect, path + " passive_effects[" + str(i) + "] should not be null")
			if effect:
				assert_true(effect is GameplayEffect, path + " passive_effects[" + str(i) + "] should be GameplayEffect")
		
		# Check granted_abilities are valid AbilityGrant with valid ability
		for i in range(equipment.granted_abilities.size()):
			var grant = equipment.granted_abilities[i]
			assert_not_null(grant, path + " granted_abilities[" + str(i) + "] should not be null")
			if grant:
				assert_true(grant is AbilityGrant, path + " granted_abilities[" + str(i) + "] should be AbilityGrant")
				assert_not_null(grant.ability, path + " granted_abilities[" + str(i) + "].ability should not be null")
				if grant.ability:
					assert_true(grant.ability is GameplayAbility, path + " ability should be GameplayAbility")
					assert_ne(grant.input_tag, "", path + " should have input_tag")
