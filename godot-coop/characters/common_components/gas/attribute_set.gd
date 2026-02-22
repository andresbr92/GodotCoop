class_name GASAttributeSet
extends Node

signal health_changed(new_value: float, max_value: float)
signal died()

const VALID_ATTRIBUTES: PackedStringArray = ["health", "max_health", "speed", "stamina", "mana", "swap_time"]

@export_group("Base Stats")
@export var base_max_health: float = 100.0
@export var base_speed: float = 5.0
@export var base_stamina: float = 50.0
@export var base_swap_time: float = 0.5  ## Time in seconds to swap items between hand and belt

var is_strafing: bool = false

var _health: float
var health: float:
	set(value):
		var current_max = get_max_health()
		var old_health = _health
		_health = clamp(value, 0.0, current_max)
		
		if _health != old_health:
			print("[GASAttributeSet] HEALTH UPDATE: ", _health, " / ", current_max)
			health_changed.emit(_health, current_max)
			if _health == 0.0:
				print("[GASAttributeSet] CHARACTER DIED!")
				died.emit()
	get:
		return _health

var speed: float:
	get:
		return get_computed_stat("speed")

var swap_time: float:
	get:
		return get_computed_stat("swap_time")

var _effect_manager: EffectManager


func _ready() -> void:
	_health = base_max_health


func set_effect_manager(effect_manager: EffectManager) -> void:
	_effect_manager = effect_manager


func get_max_health() -> float:
	return get_computed_stat("max_health")


func get_computed_stat(stat_name: String) -> float:
	if stat_name == "health": 
		return _health
	
	var base_val = get("base_" + stat_name)
	if base_val == null: 
		return 0.0
	
	if not _effect_manager:
		return base_val
	
	return _effect_manager.compute_stat_with_modifiers(stat_name, base_val)


func apply_instant_change(attribute: String, value: float, operation: int) -> void:
	var final_value = value
	if operation == GameplayEffect.ModifierOp.SUBTRACT:
		final_value = -value
	
	if attribute == "health":
		self.health += final_value
	else:
		printerr("[GASAttributeSet] WARNING: INSTANT effects are usually for 'health' or 'mana'. Check attribute: ", attribute)


func on_max_health_changed() -> void:
	self.health = self.health
