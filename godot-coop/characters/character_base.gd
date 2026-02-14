class_name CharacterBase
extends CharacterBody3D

@onready var attribute_set: AttributeSet = %AttributeSet






func receive_gameplay_effects(effects: Array[GameplayEffect]) -> void:
	if attribute_set:
		attribute_set.apply_gameplay_effects(effects)
