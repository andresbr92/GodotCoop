class_name AbilityGrant
extends Resource

@export var ability: GameplayAbility
# We use a string enum hint to make it easy to select in the inspector
@export_enum("None", "ability.primary", "ability.secondary", "ability.interact") var input_tag: String = "ability.primary"
