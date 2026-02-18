class_name ThrowableData
extends Resource

@export_group("Physics & Visuals")
@export var projectile_scene : PackedScene 
@export var throw_force : float = 15.0

@export_group("Explosion Settings")
@export var blast_radius : float = 3.0       # We keep this here (it's a physical explosion property)
@export var area_effect_duration : float = 0.5 # How long the area effect stays active (fire on the ground)

@export_group("Gameplay Effects")
# HERE'S THE KEY: An array of resources
@export var effects: Array[GameplayEffect] = []

@export_group("Inventory Item Settings")
@export var consume_on_use : bool = true
