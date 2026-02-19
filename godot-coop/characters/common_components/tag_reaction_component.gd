class_name TagReactionComponent
extends Node

@export var target_tag: StringName
@export var attribute_set: AttributeSet

func _ready() -> void:
	if attribute_set:
		attribute_set.tag_added.connect(_on_tag_added)
		attribute_set.tag_removed.connect(_on_tag_removed)

func _on_tag_added(tag: StringName) -> void:
	if tag == target_tag:
		activate_reaction()

func _on_tag_removed(tag: StringName) -> void:
	if tag == target_tag:
		deactivate_reaction()

# Métodos virtuales para ser sobrescritos por los hijos
func activate_reaction() -> void:
	pass

func deactivate_reaction() -> void:
	pass
