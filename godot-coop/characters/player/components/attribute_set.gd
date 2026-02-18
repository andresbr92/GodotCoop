class_name AttributeSet
extends Node

signal health_changed(new_value, max_value)
signal died()

@export_group("Innate Abilities")
# List of abilities the character is born with.
# We use AbilityGrant to know which Input Tag to assign them.
@export var default_abilities: Array[AbilityGrant] 

# --- INPUT TAGS CONSTANTS ---
const INPUT_PRIMARY = "ability.primary"
const INPUT_SECONDARY = "ability.secondary"
const INPUT_RELOAD = "ability.reload"
const INPUT_JUMP = "ability.jump"

# VALID ATTRIBUTES (Source of truth)
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
		
		# Only emit signal and print if it actually changed
		if health != old_health:
			print("[AttributeSet] HEALTH UPDATE: ", health, " / ", current_max)
			health_changed.emit(health, current_max)
			if health == 0.0:
				print("[AttributeSet] CHARACTER DIED!")
				died.emit()
var speed: float:
	get:
		return get_total_stat("speed")

#region Internal GAS classes


# TEMPORARY MODIFIERS MANAGEMENT
class ActiveEffect:
	var handle: EffectSpecHandle
	var source_effect: GameplayEffect
	var time_left: float
	var tick_timer: float
	
	func _init(p_handle: EffectSpecHandle, effect: GameplayEffect):
		handle = p_handle
		source_effect = effect
		time_left = effect.duration
		tick_timer = 0.0

# --- INTERNAL CLASS FOR GRANTED ABILITIES ---
class AbilitySpec:
	var handle: AbilitySpecHandle
	var ability: GameplayAbility # The resource definition
	var input_tag: String # The input slot (e.g., "ability.primary")
	var is_active: bool = false
	
	func _init(p_handle: AbilitySpecHandle, p_ability: GameplayAbility, p_input: String):
		handle = p_handle
		ability = p_ability
		input_tag = p_input

#endregion



var active_effect_registry: Dictionary = {}
var active_modifiers: Dictionary = {}
var active_periodic_effects: Array[ActiveEffect] = []
var granted_abilities: Dictionary = {}



func _ready() -> void:
	for attr in VALID_ATTRIBUTES:
		active_modifiers[attr] = []
	health = base_max_health
	print("[AttributeSet] Initialized. Starting Health: ", health)
	if multiplayer.is_server():
		for grant in default_abilities:
			if grant.ability:
				grant_ability(grant.ability, grant.input_tag)

func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	_process_periodic_effects(delta)
	_process_duration_modifiers(delta)

#region Effect Functions

func apply_gameplay_effects(effects: Array[GameplayEffect]) -> Array[EffectSpecHandle]:
	if not multiplayer.is_server(): return []
	
	var created_handles: Array[EffectSpecHandle] = []
	
	for effect in effects:
		match effect.mode:
			GameplayEffect.ApplicationMode.INSTANT:
				# Instant effects don't need handles as they don't persist
				print("[AttributeSet] Applying INSTANT effect: '", effect.effect_name, "'")
				_apply_instant_change(effect)
				
			GameplayEffect.ApplicationMode.PERIODIC:
				var handle = _create_active_effect(effect)
				print("[AttributeSet] Added PERIODIC effect: '", effect.effect_name, "' Handle: ", handle)
				active_periodic_effects.append(active_effect_registry[handle])
				created_handles.append(handle)
				
			GameplayEffect.ApplicationMode.DURATION: # (And INFINITE/PASSIVE in the future)
				var handle = _create_active_effect(effect)
				print("[AttributeSet] Added DURATION modifier: '", effect.effect_name, "' Handle: ", handle)
				active_modifiers[effect.target_attribute].append(active_effect_registry[handle])
				_on_modifier_changed(effect.target_attribute)
				created_handles.append(handle)
	
	return created_handles

func remove_effect(handle: EffectSpecHandle) -> void:
	if not multiplayer.is_server(): return
	
	if not active_effect_registry.has(handle):
		print("[AttributeSet] Warning: Check to remove effect ", handle, " failed. Not found.")
		return
	
	var active_effect = active_effect_registry[handle]
	var source_data = active_effect.source_effect
	
	print("[AttributeSet] Removing effect manually: ", handle)
	
	# 1. Clean up from logic lists
	match source_data.mode:
		GameplayEffect.ApplicationMode.PERIODIC:
			active_periodic_effects.erase(active_effect)
			
		GameplayEffect.ApplicationMode.DURATION:
			var attr_name = source_data.target_attribute
			if active_modifiers.has(attr_name):
				active_modifiers[attr_name].erase(active_effect)
				_on_modifier_changed(attr_name) # Recalculate stats immediately
	
	# 2. Remove from central registry
	active_effect_registry.erase(handle)

#endregion


#region Ability Functions
func grant_ability(ability_res: GameplayAbility, input_tag: String = "") -> AbilitySpecHandle:
	if not multiplayer.is_server(): return null
	if ability_res == null: return null
	
	# 1. Generate the unique ID (Receipt)
	var handle = AbilitySpecHandle.new(ability_res.ability_name)
	
	# 2. Create the runtime specification (Instance data)
	var spec = AbilitySpec.new(handle, ability_res, input_tag)
	
	# 3. Store in the registry
	granted_abilities[handle] = spec
	
	print("[AttributeSet] Granted Ability: '", ability_res.ability_name, "' | Handle: ", handle, " | Input: ", input_tag)
	
	return handle

func clear_ability(handle: AbilitySpecHandle) -> void:
	if not multiplayer.is_server(): return
	
	if not granted_abilities.has(handle):
		print("[AttributeSet] Warning: Check to clear ability ", handle, " failed. Not found.")
		return
		
	var spec = granted_abilities[handle]
	
	# Force end if running
	if spec.is_active:
		# We pass 'get_parent()' assuming AttributeSet is child of CharacterBase
		spec.ability.end_ability(get_parent(), handle)
	
	granted_abilities.erase(handle)
	print("[AttributeSet] Cleared Ability: ", handle)



# RPC called by the client when a button is pressed
@rpc("any_peer", "call_local", "reliable")
func server_ability_input_pressed(input_tag: String, activation_data: Dictionary = {}) -> void:
	if not multiplayer.is_server(): return
	
	for handle in granted_abilities:
		var spec = granted_abilities[handle]
		if spec.input_tag == input_tag:
			# Pasamos los datos a la habilidad
			spec.ability.activate(get_parent(), handle, activation_data)

# RPC called by the client when a button is released
@rpc("any_peer", "call_local", "reliable")
func server_ability_input_released(input_tag: String) -> void:
	if not multiplayer.is_server(): return
	
	for handle in granted_abilities:
		var spec: AbilitySpec = granted_abilities[handle]
		
		if spec.input_tag == input_tag:
			# Notify the ability that input was released (useful for charged attacks, bows, etc)
			var actor = get_parent()
			spec.ability.input_released(actor, handle)
			# Note: We don't set is_active = false here automatically. 
			# The ability should decide when to end itself callind end_ability().


#endregion



# Helper to create the ActiveEffect and register it
func _create_active_effect(effect: GameplayEffect) -> EffectSpecHandle:
	var handle = EffectSpecHandle.new(effect.effect_name)
	var active = ActiveEffect.new(handle, effect)
	active_effect_registry[handle] = active
	return handle

# --- 2. TOTAL STATS CALCULATION ---

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

# --- 1. APPLICATION LOGIC ---

func _process_periodic_effects(delta: float) -> void:
	for i in range(active_periodic_effects.size() - 1, -1, -1):
		var active = active_periodic_effects[i]
		active.time_left -= delta
		active.tick_timer += delta
		
		if active.tick_timer >= active.source_effect.tick_rate:
			active.tick_timer = 0.0
			_apply_instant_change(active.source_effect)
			
		if active.time_left <= 0:
			# Cleanup
			active_effect_registry.erase(active.handle) # <--- REMOVE FROM REGISTRY
			active_periodic_effects.remove_at(i)

func _process_duration_modifiers(delta: float) -> void:
	for attr in active_modifiers.keys():
		var modifiers_list = active_modifiers[attr]
		var changed = false
		for i in range(modifiers_list.size() - 1, -1, -1):
			var active = modifiers_list[i]
			active.time_left -= delta
			if active.time_left <= 0:
				# Cleanup
				active_effect_registry.erase(active.handle) # <--- REMOVE FROM REGISTRY
				modifiers_list.remove_at(i)
				changed = true
		
		if changed:
			_on_modifier_changed(attr)
