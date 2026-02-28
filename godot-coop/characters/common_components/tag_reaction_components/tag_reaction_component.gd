class_name TagReactionComponent
extends Node

@export var target_tag: StringName
@export var ability_system: AbilitySystemComponent


func _ready() -> void:
	if ability_system:
		ability_system.tag_added.connect(_on_tag_added)
		ability_system.tag_removed.connect(_on_tag_removed)


func _on_tag_added(tag: StringName) -> void:
	if tag == target_tag:
		activate_reaction()


func _on_tag_removed(tag: StringName) -> void:
	if tag == target_tag:
		deactivate_reaction()


func activate_reaction() -> void:
	pass


func deactivate_reaction() -> void:
	pass
