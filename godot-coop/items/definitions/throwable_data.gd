extends Resource

class_name  ThrowableData

enum EffectType { DAMAGE, HEAL, SPEED, POISON }
enum ApplicationMode { INSTANT, OVER_TIME }


@export_group("Visuals & Physics")
@export var projectile_scene : PackedScene 
@export var throw_force : float = 15.0
@export var blast_radius : float = 1.0

@export_group("Impact Stats")
@export var effect_type : EffectType = EffectType.DAMAGE
@export var area_effect_duration : float = 0.5
@export var application_mode : ApplicationMode = ApplicationMode.INSTANT # <--- Nuevo
@export var effect_value : int = 10 # Si es Instant: Daño total. Si es DoT: Daño por tick.

@export_group("Over Time Settings")
@export var duration: float = 5.0    # Cuánto dura el veneno (ej: 5s)
@export var tick_rate: float = 1.0   # Cada cuánto aplica daño (ej: 1s)
