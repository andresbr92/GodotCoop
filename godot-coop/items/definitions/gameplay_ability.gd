class_name GameplayAbility
extends Resource

@export var ability_name: String = "Base Ability"

@export_group("Activation Requirements")
@export var activation_required_tags: PackedStringArray
@export var activation_blocked_tags: PackedStringArray

@export_group("Ongoing Effects")
@export var ongoing_effects: Array[GameplayEffect]

@export_group("Animation")
## (ej: "Throw", "Drink")
@export var animation_name: String = ""


func can_activate(actor: Node) -> bool:
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if not asc: 
		return false
		
	for tag in activation_required_tags:
		if not asc.has_tag(tag):
			return false 
			
	for tag in activation_blocked_tags:
		if asc.has_tag(tag):
			return false 
			
	return true


func activate(_actor: Node, _handle: AbilitySpecHandle, _args: Dictionary = {}) -> void:
	print("Base activate")


func input_released(_actor: Node, _handle: AbilitySpecHandle) -> void:
	pass


func end_ability(_actor: Node, _handle: AbilitySpecHandle) -> void:
	pass
