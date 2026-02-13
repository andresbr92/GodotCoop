extends Resource

class_name  ThrowableData

enum EffectType { DAMAGE, HEAL, SPEED, POISON }


@export_group("Visuals & Physics")
# En vez de string, usamos PackedScene para arrastrar el archivo .tscn
@export var projectile_scene : PackedScene 
@export var throw_force : float = 15.0

@export_group("Impact Stats")
@export var blast_radius : float = 3.0
@export var effect_type : EffectType = EffectType.DAMAGE
@export var effect_value : int = 10
