class_name AbilityManager
extends Node

const INPUT_PRIMARY = "ability.primary"
const INPUT_SECONDARY = "ability.secondary"
const INPUT_RELOAD = "ability.reload"
const INPUT_JUMP = "ability.jump"

class AbilitySpec:
	var handle: AbilitySpecHandle
	var ability: GameplayAbility
	var input_tag: String
	var is_active: bool = false
	var source_inventory: Inventory = null
	var source_slot_index: int = -1
	var active_effect_handles: Array[EffectSpecHandle] = []
	
	func _init(p_handle: AbilitySpecHandle, p_ability: GameplayAbility, p_input: String, p_inv: Inventory, p_slot: int):
		handle = p_handle
		ability = p_ability
		input_tag = p_input
		source_inventory = p_inv
		source_slot_index = p_slot

@export var default_abilities: Array[AbilityGrant]

var _effect_manager: EffectManager
var _tag_container: TagContainer
var _cast_manager: CastManager
var _actor: Node

var granted_abilities: Dictionary = {}


func _ready() -> void:
	if multiplayer.is_server():
		_ready_logic()


## Testable ready logic - call directly in tests
func _ready_logic() -> void:
	for grant in default_abilities:
		if grant and grant.ability:
			_grant_ability_logic(grant.ability, grant.input_tag)


func setup(actor: Node, effect_manager: EffectManager, tag_container: TagContainer, cast_manager: CastManager) -> void:
	_actor = actor
	_effect_manager = effect_manager
	_tag_container = tag_container
	_cast_manager = cast_manager


func grant_ability(ability_res: GameplayAbility, input_tag: String = "", source_inventory: Inventory = null, source_slot_index: int = -1) -> AbilitySpecHandle:
	if not multiplayer.is_server(): return null
	return _grant_ability_logic(ability_res, input_tag, source_inventory, source_slot_index)


## Testable grant ability logic - call directly in tests
func _grant_ability_logic(ability_res: GameplayAbility, input_tag: String = "", source_inventory: Inventory = null, source_slot_index: int = -1) -> AbilitySpecHandle:
	if ability_res == null: return null
	
	var handle = AbilitySpecHandle.new(ability_res.ability_name)
	var spec = AbilitySpec.new(handle, ability_res, input_tag, source_inventory, source_slot_index)
	granted_abilities[handle] = spec
	
	print("[AbilityManager] Granted Ability: '", ability_res.ability_name, "' | Handle: ", handle, " | Input: ", input_tag)
	
	return handle


func clear_ability(handle: AbilitySpecHandle) -> void:
	if not multiplayer.is_server(): return
	_clear_ability_logic(handle)


## Testable clear ability logic - call directly in tests
func _clear_ability_logic(handle: AbilitySpecHandle) -> void:
	if not granted_abilities.has(handle):
		print("[AbilityManager] Warning: Ability not found: ", handle)
		return
		
	var spec = granted_abilities[handle]
	
	if spec.is_active:
		spec.ability.end_ability(_actor, handle)
	
	granted_abilities.erase(handle)
	print("[AbilityManager] Cleared Ability: ", handle)


func get_ability_source(handle: AbilitySpecHandle) -> Dictionary:
	if granted_abilities.has(handle):
		var spec = granted_abilities[handle]
		return {
			"inventory": spec.source_inventory,
			"slot": spec.source_slot_index
		}
	return {}


func can_activate_ability(ability: GameplayAbility) -> bool:
	for tag in ability.activation_required_tags:
		if not _tag_container.has_tag(tag):
			return false
			
	for tag in ability.activation_blocked_tags:
		if _tag_container.has_tag(tag):
			return false
			
	return true


@rpc("any_peer", "call_local", "reliable")
func server_ability_input_pressed(input_tag: String, activation_data: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	_ability_input_pressed_logic(input_tag, activation_data)


## Testable ability input pressed logic - call directly in tests
func _ability_input_pressed_logic(input_tag: String, activation_data: Dictionary = {}) -> void:
	for handle in granted_abilities:
		var spec = granted_abilities[handle]
		if spec.input_tag == input_tag:
			if can_activate_ability(spec.ability):
				spec.ability.activate(_actor, handle, activation_data)
				if spec.ability.animation_name != "":
					var asc = _actor.get_node_or_null("AbilitySystemComponent")
					if asc:
						asc.ability_animation_triggered.emit(spec.ability.animation_name)
				spec.is_active = true
				if spec.ability.ongoing_effects.size() > 0:
					var handles = _effect_manager._apply_effects_logic(spec.ability.ongoing_effects)
					spec.active_effect_handles.append_array(handles)
			else:
				print("[AbilityManager] Ability blocked: ", spec.ability.ability_name)


@rpc("any_peer", "call_local", "reliable")
func server_ability_input_released(input_tag: String) -> void:
	if not multiplayer.is_server(): return
	_ability_input_released_logic(input_tag)


## Testable ability input released logic - call directly in tests
func _ability_input_released_logic(input_tag: String) -> void:
	for handle in granted_abilities:
		var spec: AbilitySpec = granted_abilities[handle]
		
		if spec.input_tag == input_tag:
			spec.is_active = false
			
			for effect_handle in spec.active_effect_handles:
				_effect_manager._remove_effect_logic(effect_handle)
			spec.active_effect_handles.clear()
			
			if _cast_manager.has_active_cast(handle):
				_cast_manager._cancel_cast_logic(handle)
			
			spec.ability.input_released(_actor, handle)
