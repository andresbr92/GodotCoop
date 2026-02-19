class_name GameplayAbility
extends Resource

# Display name for UI/Debug
@export var ability_name: String = "Base Ability"

@export_group("Activation Requirements")
@export var activation_required_tags: PackedStringArray
@export var activation_blocked_tags: PackedStringArray

@export_group("Ongoing Effects")
@export var ongoing_effects: Array[GameplayEffect]

# --- VIRTUAL METHODS (To be overridden by specific abilities) ---

# Called when the ability is activated via input or event
# 'actor' is the CharacterBase who owns this ability
func can_activate(actor: Node) -> bool:
	var attribute_set = actor.get_node_or_null("AttributeSet")
	if not attribute_set: 
		return false
		
	# 1. Comprobamos si nos falta algún tag obligatorio
	for tag in activation_required_tags:
		if not attribute_set.has_tag(tag):
			return false 
			
	# 2. Comprobamos si tenemos algún tag prohibido
	for tag in activation_blocked_tags:
		if attribute_set.has_tag(tag):
			return false 
			
	# Si pasa ambas pruebas, luz verde
	return true

func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	print("Base activate")

# Called when input is released (for charged abilities like bows)
func input_released(actor: Node, handle: AbilitySpecHandle) -> void:
	pass

# Called when the ability ends (cleanup)
func end_ability(actor: Node, handle: AbilitySpecHandle) -> void:
	pass
