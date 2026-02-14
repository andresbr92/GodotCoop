class_name ThrowableData
extends Resource

@export_group("Physics & Visuals")
@export var projectile_scene : PackedScene 
@export var throw_force : float = 15.0

@export_group("Explosion Settings")
@export var blast_radius : float = 3.0       # Mantenemos esto aquí (es propiedad de la explosión física)
@export var area_effect_duration : float = 0.5 # Cuánto tiempo dura el área de efecto activa (fuego en el suelo)

@export_group("Gameplay Effects")
# AQUÍ ESTÁ LA CLAVE: Un array de recursos
@export var effects: Array[GameplayEffect] = []
