extends TagReactionComponent
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"../../Visuals/Skeleton/PhysicalBoneSimulator3D"
@onready var collision_shape_3d: CollisionShape3D = $"../../Visuals/Skeleton/HarvestAttachmentSocket/HarvestMarker/HumanHarvestable/CollisionShape3D"



func _on_tag_added(tag: StringName) -> void:
	GlobalLogger.log("tag added", tag)
	if multiplayer.is_server():
		activate_ragdoll.rpc()
		activate_harvestable_node.rpc()

func _on_tag_removed(tag: StringName) -> void:
	if multiplayer.is_server():
		wake_up_ragdoll.rpc()
	pass
		

#region Harvest
func _activate_harvestable_logic() -> void:
	await get_tree().create_timer(2.0).timeout
	collision_shape_3d.set_deferred("disabled", false)

#endregion



#region Ragdoll
func _wake_up_ragdoll_logic() -> void:
	if has_node("AnimationTree"): 
		$AnimationTree.active = true

	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", false)

	set_physics_process(true)
	
	physical_bone_simulator_3d.physical_bones_stop_simulation()



func _ragdoll_logic() -> void:
	if has_node("AnimationTree"): 
		$AnimationTree.active = false

	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

	set_physics_process(false)
	
	physical_bone_simulator_3d.physical_bones_start_simulation()
	
	get_tree().create_timer(2).timeout.connect(freeze_ragdoll)


func freeze_ragdoll() -> void:
	var skeleton = %Skeleton
	
	if not is_instance_valid(skeleton):
		return
	
	for child in skeleton.get_children():
		if child is PhysicalBone3D:
			# Setting freeze to true stops physics calculations 
			# but keeps the bone exactly in its current transform/pose
			child.freeze = true
			physical_bone_simulator_3d.physical_bones_stop_simulation()


#endregion

#region RPC

@rpc("authority", "call_local", "reliable")
func activate_ragdoll() -> void:
	_ragdoll_logic()


@rpc("authority", "call_local", "reliable")
func activate_harvestable_node() -> void:
	_activate_harvestable_logic()


@rpc("authority", "call_local", "reliable")
func wake_up_ragdoll() -> void:
	_wake_up_ragdoll_logic()

	
#endregion
