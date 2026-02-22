class_name CharacterBase
extends CharacterBody3D

@onready var ability_system: AbilitySystemComponent = $AbilitySystemComponent


func _enter_tree() -> void:
	pass


func receive_gameplay_effects(effects: Array[GameplayEffect]) -> void:
	if ability_system:
		ability_system.apply_gameplay_effects(effects)
