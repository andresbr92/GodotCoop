extends ProjectileBase

class_name PotionProjectile
@onready var potion_particles: GPUParticles3D = $PotionParticles

func on_inpact(body: Node) -> void:
    if multiplayer.is_server():
        explode()
    

func explode() -> void:
    var radius = data.blast_radius
    var shape = $AreaEffect/ExplosionShape.shape as SphereShape3D
    if shape:
        shape.radius = radius
    potion_emite_particles.rpc()
    
    var bodies = area_effect.get_overlapping_areas()
    for body in bodies:
        var character : CharacterBase = body.get_parent()
        if character:
            character.attribute_set.tage_damage(data.effect_value)



func _on_timer_timeout() -> void:
    contact_monitor = true

@rpc("authority", "call_local", "reliable")
func potion_emite_particles() -> void:
    potion_particles.emitting = true
