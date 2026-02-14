class_name CharacterBase
extends CharacterBody3D

@onready var attribute_set: AttributeSet = %AttributeSet






func receive_effect(data: ThrowableData) -> void:
	if attribute_set:
		attribute_set.apply_effect(data)
