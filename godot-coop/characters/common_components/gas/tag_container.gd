class_name TagContainer
extends Node

signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)

var active_tags: Dictionary = {}


func add_tag(tag: StringName) -> void:
	if multiplayer.is_server():
		_add_tag_logic(tag)
		_add_tag_rpc.rpc(tag)


func remove_tag(tag: StringName) -> void:
	if multiplayer.is_server():
		_remove_tag_logic(tag)
		_remove_tag_rpc.rpc(tag)


func has_tag(tag: StringName) -> bool:
	return active_tags.get(tag, 0) > 0


func _add_tag_logic(tag: StringName) -> void:
	var current_count = active_tags.get(tag, 0)
	active_tags[tag] = current_count + 1
	GlobalLogger.log("[TagContainer] Tag count for '", tag, "': ", current_count + 1)
	
	if current_count == 0:
		GlobalLogger.log("[TagContainer] Gained Tag: ", tag)
		tag_added.emit(tag)


func _remove_tag_logic(tag: StringName) -> void:
	var current_count = active_tags.get(tag, 0)
	
	if current_count > 0:
		active_tags[tag] = current_count - 1
		GlobalLogger.log("[TagContainer] Tag count for '", tag, "': ", current_count - 1)
		
		if active_tags[tag] == 0:
			active_tags.erase(tag)
			GlobalLogger.log("[TagContainer] Lost Tag: ", tag)
			tag_removed.emit(tag)


@rpc("authority", "call_remote", "reliable")
func _add_tag_rpc(tag: StringName) -> void:
	if not multiplayer.is_server():
		_add_tag_logic(tag)


@rpc("authority", "call_remote", "reliable")
func _remove_tag_rpc(tag: StringName) -> void:
	if not multiplayer.is_server():
		_remove_tag_logic(tag)
