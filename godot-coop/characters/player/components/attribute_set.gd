class_name AttributeSet
extends Node


signal health_changed(new_value, max_value)
signal died()


class ActiveEffect:
	var id : String
	var type : int
	var value : int
	var time_left : float
	var tick_rate : float
	var tick_timer: float
	
	func _init(p_type, p_value, p_duration, p_rate) -> void:
		type = p_type
		value = p_value
		time_left = p_duration
		tick_rate = p_rate
		tick_timer = 0.0 # Aplicar el primer tick inmediatamente o esperar? (Empezamos en 0 para esperar)


var active_effects : Array[ActiveEffect] = []


@export_group("Stats")
@export var max_health: int = 100
@export var health: int = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health, max_health)
		print("new health", health)
		if health == 0:
			died.emit()

func _ready() -> void:
	health = max_health


func _process(delta: float) -> void:
	if not multiplayer.is_server():
		set_process(false)
		return
	
	if active_effects.is_empty(): 
		return
	
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		
		effect.time_left -= delta
		
		effect.tick_timer += delta
		
		if effect.tick_timer >= effect.tick_rate:
			effect.tick_timer = 0.0 # Reset timer
			_execute_instant_effect(effect.type, effect.value) # Aplicar valor
		if effect.time_left <= 0:
			active_effects.remove_at(i)
			print("Effect ended.")
	



func apply_effect(data: ThrowableData) -> void:
	if not multiplayer.is_server():
		return
	match data.application_mode:
		ThrowableData.ApplicationMode.INSTANT:
			_execute_instant_effect(data.effect_type, data.effect_value)
		ThrowableData.ApplicationMode.OVER_TIME:
			var new_effect = ActiveEffect.new(
				data.effect_type,
				data.effect_value,
				data.duration,
				data.tick_rate
			)
			active_effects.append(new_effect)
			print("Over time effect aplying: ", data.duration)
	
	
func _execute_instant_effect(type: int, amount: int) -> void:
	match type:
		ThrowableData.EffectType.DAMAGE:
			self.health -= amount
		ThrowableData.EffectType.HEAL:
			self.health += amount
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
