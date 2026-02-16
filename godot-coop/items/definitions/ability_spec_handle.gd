class_name AbilitySpecHandle
extends Resource

# Static counter for unique IDs across the session
static var _id_counter: int = 0

# Unique ID for this specific grant of an ability
var id: int
var ability_name: String

func _init(p_name: String = "UnknownAbility"):
	id = _id_counter
	_id_counter += 1
	ability_name = p_name

func _to_string() -> String:
	return "AbilityHandle[%s:%s]" % [id, ability_name]
