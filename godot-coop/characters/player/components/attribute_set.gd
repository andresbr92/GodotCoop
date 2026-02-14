class_name AttributeSet
extends Node


signal health_changed(new_value, max_value)
signal died()


@export_group("Stats")
@export var max_health: int = 100
@export var health: int = 100:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health, max_health)
		if health == 0:
			died.emit()

func _ready() -> void:
	health = max_health



func take_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	self.health -= amount
	print(get_parent().name, " recibió ", amount, " de daño.")
