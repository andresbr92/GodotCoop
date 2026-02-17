class_name GameplayAbility
extends Resource

# Display name for UI/Debug
@export var ability_name: String = "Base Ability"

# Tags that this ability owns (e.g., "ability.attack.fire")
# Useful for cooldowns or cancelling other abilities in the future
@export var ability_tags: PackedStringArray

# --- VIRTUAL METHODS (To be overridden by specific abilities) ---

# Called when the ability is activated via input or event
# 'actor' is the CharacterBase who owns this ability
func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	print("Base activate")

# Called when input is released (for charged abilities like bows)
func input_released(actor: Node, handle: AbilitySpecHandle) -> void:
	pass

# Called when the ability ends (cleanup)
func end_ability(actor: Node, handle: AbilitySpecHandle) -> void:
	pass
