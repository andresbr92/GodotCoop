@tool
class_name GameplayEffect
extends Resource

# 1. New application modes
enum ApplicationMode { INSTANT, PERIODIC, DURATION, INFINITE }
enum ModifierOp { ADD, SUBTRACT, MULTIPLY, DIVIDE } 

var target_attribute: String = "health"

@export_group("Effect Definition")
@export var operation: ModifierOp = ModifierOp.SUBTRACT
@export var value: float = 10.0

@export_group("Timing")
@export var mode: ApplicationMode = ApplicationMode.INSTANT
@export var duration: float = 0.0     
@export var tick_rate: float = 1.0    

@export_group("Visuals")
@export var effect_name: String = "Generic Effect" 
@export var vfx_tag: String = "" 

@export_group("GameplayTags")
@export var granted_tags: PackedStringArray

func _get_property_list() -> Array:
	var properties = []
	var hint_string = ",".join(GASAttributeSet.VALID_ATTRIBUTES)
	
	properties.append({
		"name": "target_attribute",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": hint_string
	})
	
	return properties
