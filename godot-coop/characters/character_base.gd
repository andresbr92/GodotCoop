class_name CharacterBase
extends CharacterBody3D

@onready var attribute_set: AttributeSet = %AttributeSet






func take_damage(in_damage: int) -> void:
	attribute_set.take_damage(in_damage)
