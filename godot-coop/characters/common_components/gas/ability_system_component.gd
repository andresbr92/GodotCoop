class_name AbilitySystemComponent
extends Node

signal health_changed(new_value: float, max_value: float)
signal died()
signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
signal ability_animation_triggered(anim_name: String)

@onready var attribute_set: GASAttributeSet = $AttributeSet
@onready var effect_manager: EffectManager = $EffectManager
@onready var ability_manager: AbilityManager = $AbilityManager
@onready var cast_manager: CastManager = $CastManager
@onready var tag_container: TagContainer = $TagContainer

@export var is_strafing: bool:
	get:
		return attribute_set.is_strafing if attribute_set else false
	set(value):
		if attribute_set:
			attribute_set.is_strafing = value

var health: float:
	get:
		return attribute_set.health if attribute_set else 0.0
	set(value):
		if attribute_set:
			attribute_set.health = value

var speed: float:
	get:
		return attribute_set.speed if attribute_set else 0.0


func _ready() -> void:
	_setup_components()
	_connect_signals()


func _setup_components() -> void:
	var actor = get_parent()
	
	effect_manager.setup(attribute_set, tag_container)
	ability_manager.setup(actor, effect_manager, tag_container, cast_manager)


func _connect_signals() -> void:
	attribute_set.health_changed.connect(func(new_val, max_val): health_changed.emit(new_val, max_val))
	attribute_set.died.connect(func(): died.emit())
	tag_container.tag_added.connect(func(tag): tag_added.emit(tag))
	tag_container.tag_removed.connect(func(tag): tag_removed.emit(tag))


func apply_gameplay_effects(effects: Array[GameplayEffect]) -> Array[EffectSpecHandle]:
	return effect_manager.apply_effects(effects)


func remove_effect(handle: EffectSpecHandle) -> void:
	effect_manager.remove_effect(handle)


func grant_ability(ability_res: GameplayAbility, input_tag: String = "", source_inventory: Inventory = null, source_slot_index: int = -1) -> AbilitySpecHandle:
	return ability_manager.grant_ability(ability_res, input_tag, source_inventory, source_slot_index)


func clear_ability(handle: AbilitySpecHandle) -> void:
	ability_manager.clear_ability(handle)


func get_ability_source(handle: AbilitySpecHandle) -> Dictionary:
	return ability_manager.get_ability_source(handle)


func start_cast(handle: AbilitySpecHandle, duration: float, on_complete: Callable, on_cancel: Callable = Callable()) -> void:
	cast_manager.start_cast(handle, duration, on_complete, on_cancel)


func cancel_cast(handle: AbilitySpecHandle) -> void:
	cast_manager.cancel_cast(handle)


func add_tag(tag: StringName) -> void:
	tag_container.add_tag(tag)


func remove_tag(tag: StringName) -> void:
	tag_container.remove_tag(tag)


func has_tag(tag: StringName) -> bool:
	return tag_container.has_tag(tag)


func get_total_stat(stat_name: String) -> float:
	return attribute_set.get_computed_stat(stat_name)


func server_ability_input_pressed(input_tag: String, activation_data: Dictionary = {}) -> void:
	ability_manager.server_ability_input_pressed.rpc(input_tag, activation_data)


func server_ability_input_released(input_tag: String) -> void:
	ability_manager.server_ability_input_released.rpc(input_tag)
