extends CharacterBase



func _enter_tree() -> void:
	$BTPlayer.set_multiplayer_authority(1)
	
	if not multiplayer.is_server():
		$BTPlayer.active = false
		set_physics_process(false)
		set_process(false)
