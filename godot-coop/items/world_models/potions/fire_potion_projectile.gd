extends ProjectileBase

class_name PotionProjectile
@onready var potion_particles: GPUParticles3D = $PotionParticles
var is_potion_exploded = false

func on_inpact(body: Node) -> void:
	if multiplayer.is_server():
		explode()
	

func explode() -> void:
	var radius = data.blast_radius
	var shape = $AreaEffect/ExplosionShape.shape as SphereShape3D
	if shape:
		shape.radius = radius
	potion_emite_particles.rpc()

	var targets = area_effect.get_overlapping_areas()
	for target in targets:
		var parent_target = target.get_parent()
		if parent_target.has_method("take_damage"):
			parent_target.take_damage(data.effect_value)
		
		

		



func _on_timer_timeout() -> void:
	contact_monitor = true

@rpc("authority", "call_local", "reliable")
func potion_emite_particles() -> void:
	potion_particles.emitting = true
