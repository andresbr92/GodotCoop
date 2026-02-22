class_name PotionData
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


@export_group("Drink Properties")
# Optional: A specific animation or sound to play when drinking
@export var drink_animation_name: String = "drink_potion"
# Effects applied to the player who drinks it
@export var consumed_effects: Array[GameplayEffect]
@export var drink_duration: float = 1.5
