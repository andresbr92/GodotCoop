extends ProjectileBase

class_name PotionProjectile
@onready var potion_particles: GPUParticles3D = $PotionParticles

func on_inpact(body: Node) -> void:
	if multiplayer.is_server():
		explode()
	

func explode() -> void:
	print(data.effect_type)
	var radius = data.blast_radius
	var shape = $ExplosionArea/ExplosionShape.shape as SphereShape3D
	if shape:
		shape.radius = radius
	potion_emite_particles.rpc()



func _on_timer_timeout() -> void:
	contact_monitor = true

@rpc("authority", "call_local", "unreliable")
func potion_emite_particles() -> void:
	potion_particles.emitting = true
