class_name AttributeSet
extends Node

signal health_changed(new_value, max_value)
signal died()

# ATRIBUTOS VÁLIDOS (Fuente de verdad)
const VALID_ATTRIBUTES: PackedStringArray = ["health", "max_health", "speed", "stamina", "mana"]

@export_group("Base Stats")
@export var base_max_health: float = 100.0
@export var base_speed: float = 5.0
@export var base_stamina: float = 50.0

# CURRENT STATS (Valores actuales)
var health: float:
	set(value):
		var current_max = get_total_stat("max_health")
		var old_health = health
		health = clamp(value, 0.0, current_max)
		
		# Solo disparamos la señal y el print si realmente cambió
		if health != old_health:
			print("[AttributeSet] HEALTH UPDATE: ", health, " / ", current_max)
			health_changed.emit(health, current_max)
			if health == 0.0:
				print("[AttributeSet] CHARACTER DIED!")
				died.emit()
var speed: float:
	get:
		return get_total_stat("speed")


# GESTIÓN DE MODIFICADORES TEMPORALES
class ActiveEffect:
	var source_effect: GameplayEffect
	var time_left: float
	var tick_timer: float
	
	func _init(effect: GameplayEffect):
		source_effect = effect
		time_left = effect.duration
		tick_timer = 0.0

var active_modifiers: Dictionary = {}
var active_periodic_effects: Array[ActiveEffect] = []

func _ready() -> void:
	for attr in VALID_ATTRIBUTES:
		active_modifiers[attr] = []
	health = base_max_health
	print("[AttributeSet] Initialized. Starting Health: ", health)

func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	_process_periodic_effects(delta)
	_process_duration_modifiers(delta)

# --- 1. LÓGICA DE APLICACIÓN ---

func apply_gameplay_effects(effects: Array[GameplayEffect]) -> void:
	if not multiplayer.is_server(): return
	
	for effect in effects:
		match effect.mode:
			GameplayEffect.ApplicationMode.INSTANT:
				print("[AttributeSet] Applying INSTANT effect: '", effect.effect_name, "' on ", effect.target_attribute)
				_apply_instant_change(effect)
				
			GameplayEffect.ApplicationMode.PERIODIC:
				print("[AttributeSet] Added PERIODIC effect: '", effect.effect_name, "' (Duration: ", effect.duration, "s, Tick: ", effect.tick_rate, "s)")
				active_periodic_effects.append(ActiveEffect.new(effect))
				
			GameplayEffect.ApplicationMode.DURATION:
				print("[AttributeSet] Added DURATION modifier to '", effect.target_attribute, "': '", effect.effect_name, "' (Duration: ", effect.duration, "s)")
				active_modifiers[effect.target_attribute].append(ActiveEffect.new(effect))
				_on_modifier_changed(effect.target_attribute)

# --- 2. CÁLCULO DE STATS TOTALES ---

func get_total_stat(stat_name: String) -> float:
	if stat_name == "health": return health 
	
	var base_val = get("base_" + stat_name)
	if base_val == null: return 0.0
	
	var final_value = base_val
	var multiplier = 1.0
	
	for active in active_modifiers[stat_name]:
		var eff = active.source_effect
		match eff.operation:
			GameplayEffect.ModifierOp.ADD: final_value += eff.value
			GameplayEffect.ModifierOp.SUBTRACT: final_value -= eff.value
			GameplayEffect.ModifierOp.MULTIPLY: multiplier *= eff.value
			GameplayEffect.ModifierOp.DIVIDE: if eff.value != 0: multiplier /= eff.value
			
	return final_value * multiplier

# --- 3. MANEJO INTERNO DE EFECTOS ---

func _apply_instant_change(effect: GameplayEffect) -> void:
	var val = effect.value
	if effect.operation == GameplayEffect.ModifierOp.SUBTRACT: val = -val
	
	if effect.target_attribute == "health":
		var old_h = health
		self.health += val
		print("[AttributeSet] Instant change applied: ", effect.value, " | Health went from ", old_h, " to ", health)
	else:
		printerr("[AttributeSet] WARNING: INSTANT effects are usually for current stats (health, mana). Check effect: ", effect.effect_name)

func _on_modifier_changed(stat_name: String) -> void:
	print("[AttributeSet] Recalculating TOTAL stat for: ", stat_name, " | New Total: ", get_total_stat(stat_name))
	if stat_name == "max_health":
		self.health = self.health 

func _process_periodic_effects(delta: float) -> void:
	for i in range(active_periodic_effects.size() - 1, -1, -1):
		var active = active_periodic_effects[i]
		active.time_left -= delta
		active.tick_timer += delta
		
		if active.tick_timer >= active.source_effect.tick_rate:
			active.tick_timer = 0.0
			print("[AttributeSet] TICK! Periodic effect '", active.source_effect.effect_name, "' applied.")
			_apply_instant_change(active.source_effect)
			
		if active.time_left <= 0:
			print("[AttributeSet] Periodic effect '", active.source_effect.effect_name, "' EXPIRED.")
			active_periodic_effects.remove_at(i)

func _process_duration_modifiers(delta: float) -> void:
	for attr in active_modifiers.keys():
		var modifiers_list = active_modifiers[attr]
		var changed = false
		for i in range(modifiers_list.size() - 1, -1, -1):
			var active = modifiers_list[i]
			active.time_left -= delta
			if active.time_left <= 0:
				print("[AttributeSet] DURATION modifier '", active.source_effect.effect_name, "' EXPIRED on '", attr, "'.")
				modifiers_list.remove_at(i)
				changed = true
		
		if changed:
			_on_modifier_changed(attr)
