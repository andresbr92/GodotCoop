@tool
class_name GameplayEffect
extends Resource

# 1. New application modes
enum ApplicationMode { INSTANT, PERIODIC, DURATION, INFINITE }
enum ModifierOp { ADD, SUBTRACT, MULTIPLY, DIVIDE } 

## Leave empty ("") to apply only tags without modifying any attribute.
var target_attribute: String = ""

@export_group("Effect Definition")
## Only used if target_attribute is set.
@export var operation: ModifierOp = ModifierOp.SUBTRACT
## Only used if target_attribute is set.
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
	# Add "none" option at the beginning for tag-only effects
	var options = ["none"]
	options.append_array(GASAttributeSet.VALID_ATTRIBUTES)
	var hint_string = ",".join(options)
	
	properties.append({
		"name": "target_attribute",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": hint_string
	})
	
	return properties
