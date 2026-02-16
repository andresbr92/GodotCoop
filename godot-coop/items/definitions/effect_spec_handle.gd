extends Resource
class_name EffectSpecHandle

static var _id_counter : int = 0

var id : int

var effect_name : String

func _init(p_effect_name : String) -> void:
	id = _id_counter
	_id_counter += 1
	effect_name = p_effect_name


func _to_string() -> String:
	return "Handle[%s:%s]" % [id, effect_name]
