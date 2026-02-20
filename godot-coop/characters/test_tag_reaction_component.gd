class_name FireTagReactionComponent
extends Node

@export var target_tag: StringName
@export var ability_system: AbilitySystemComponent
@onready var mesh_instance_3d: MeshInstance3D = $"../MeshInstance3D"
@export var texture_burn: Texture2D
@export var texture_normal: Texture2D


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
	var mat = mesh_instance_3d.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_texture = texture_burn


func deactivate_reaction() -> void:
	var mat = mesh_instance_3d.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_texture = texture_normal
