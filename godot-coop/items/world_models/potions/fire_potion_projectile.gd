extends ProjectileBase

class_name PotionProjectile
var has_exploded: bool = false
var hit_targets: Array = []

func on_inpact(body: Node) -> void:
	if has_exploded:
		return
	if multiplayer.is_server():
		trigger_explosion_sequence()
	

func trigger_explosion_sequence() -> void:
	has_exploded = true
	freeze = true
	area_effect.monitoring = true
	
	### GAME LOGIC
	apply_area_effects()
	
	### VFX/SFX
	play_impact_effects.rpc()
	
	get_tree().create_timer(data.area_effect_duration).timeout.connect(on_effect_finished)
	

		
		

func apply_area_effects() -> void:

	var radius = data.blast_radius
	var shape = $AreaEffect/ExplosionShape.shape as SphereShape3D
	if shape:
		shape.radius = radius


func _apply_specific_effect(target: Node) -> void:
	if target.has_method("receive_gameplay_effects"):
		target.receive_gameplay_effects(data.effects)


func _on_timer_timeout() -> void:
	contact_monitor = true

@rpc("authority", "call_local", "reliable")
func play_impact_effects() -> void:
	visuals.visible = false
	$PhysicsShape.disabled = true
	impact_particles.emitting = true
	impact_sound.play()


func _on_area_effect_area_entered(area: Area3D) -> void:
	if not multiplayer.is_server(): return
	var target = area.get_parent()
	if target in hit_targets:
		return
	if not target.has_method("receive_gameplay_effects"): return
	hit_targets.append(target)
	
	_apply_specific_effect(target)

func on_effect_finished() -> void:
	area_effect.monitoring = false
	queue_free()

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
