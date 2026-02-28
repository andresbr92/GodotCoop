extends CharacterBase




func _enter_tree() -> void:
	#$BTPlayer.set_multiplayer_authority(1)

	$Visuals/Skeleton/HarvestAttachmentSocket/HarvestMarker/HumanHarvestable/CollisionShape3D.set_deferred("disabled", true)
	if not multiplayer.is_server():
		#$BTPlayer.active = false
		set_physics_process(false)
		set_process(false)
