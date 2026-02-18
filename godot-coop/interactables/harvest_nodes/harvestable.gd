class_name Harvestable
extends InteractableBase

@onready var loot_generator: LootGenerator = $LootGenerator

# --- DATA ---
@export var data: HarvestableData # Drag your .tres here!

# --- STATE (Server Side) ---
var current_harvester: Node = null # Who is harvesting me
var harvest_timer: float = 0.0
var is_harvesting: bool = false
var is_looted: bool = false

# Max distance configuration to cancel if they move away
const MAX_HARVEST_DISTANCE_SQR = 3.0 * 3.0 

func _ready():
	# Initial configuration from Data
	if data and data.loot_table_id != "":
		loot_generator.loot_id = data.loot_table_id
	
	interaction_text = "Harvest"
	set_process(false) # Disable process to save CPU

func _on_interacted(character: Node):
	# Initial validations
	if is_looted or is_harvesting: return
	if not data: 
		printerr("Missing HarvestableData in ", name)
		return

	# START HARVESTING (Server)
	current_harvester = character
	is_harvesting = true
	harvest_timer = 0.0
	
	# Connect to player's damage signal to cancel if they get hit
	if current_harvester.has_signal("damaged"):
		current_harvester.damaged.connect(_on_harvester_damaged)
	
	# Activate the check loop
	set_process(true)
	
	# RPC: Notify client to show progress bar UI
	_start_harvest_visuals_rpc.rpc(data.harvest_duration)

func _process(delta: float):
	if not multiplayer.is_server(): return
	
	# 1. CANCELLATION CHECK
	if not is_instance_valid(current_harvester):
		_cancel_harvest()
		return
		
	# A. Have they moved? (Check velocity)
	# We assume character has 'velocity' property (CharacterBase has it)
	if current_harvester.velocity.length_squared() > 0.1:
		_cancel_harvest()
		return
		
	# B. Have they moved too far away? (In case they get pushed or teleport)
	if global_position.distance_squared_to(current_harvester.global_position) > MAX_HARVEST_DISTANCE_SQR:
		_cancel_harvest()
		return

	# 2. PROGRESS
	harvest_timer += delta
	
	if harvest_timer >= data.harvest_duration:
		_finish_harvest()

# Callback if player receives damage
func _on_harvester_damaged():
	_cancel_harvest()

func _cancel_harvest():
	if not is_harvesting: return
	
	is_harvesting = false
	set_process(false)
	
	# Disconnect damage signal
	if is_instance_valid(current_harvester) and current_harvester.has_signal("damaged"):
		current_harvester.damaged.disconnect(_on_harvester_damaged)
	
	current_harvester = null
	
	# RPC: Notify client to hide bar/cancel animation
	_cancel_harvest_visuals_rpc.rpc()

func _finish_harvest():
	# Detener proceso
	is_harvesting = false
	is_looted = true # Marcar como looteado
	set_process(false)
	
	if is_instance_valid(current_harvester) and current_harvester.has_signal("damaged"):
		current_harvester.damaged.disconnect(_on_harvester_damaged)
	
	# --- GENERAR LOOT (Igual que antes) ---
	var char_inv = current_harvester.get_node("CharacterInventorySystem")
	if char_inv:
		loot_generator.target_inventory_path = char_inv.main_inventory.get_path()
		loot_generator.add_loot_to_inventory()
	
	# RPCs Finales
	_success_harvest_visuals_rpc.rpc()
	
	current_harvester = null
	
	# Destruir/Respawn
	if data.respawn_time > 0:
		get_tree().create_timer(data.respawn_time).timeout.connect(_respawn)
	elif data.destroy_on_harvest:
		get_tree().create_timer(0.5).timeout.connect(queue_free)

func _respawn():
	is_looted = false
	_respawn_visuals_rpc.rpc()

# --- RPCs VISUALES (CLIENTE) ---

@rpc("call_local")
func _start_harvest_visuals_rpc(duration: float):
	# THIS IS WHERE YOU WOULD CONNECT TO YOUR UI
	# Example: GlobalUI.show_progress_bar(duration, "Harvesting...")
	print("Client: Starting to harvest... (", duration, "s)")

@rpc("call_local")
func _cancel_harvest_visuals_rpc():
	# GlobalUI.hide_progress_bar()
	print("Client: Harvest cancelled.")

@rpc("call_local")
func _success_harvest_visuals_rpc():
	# GlobalUI.hide_progress_bar()
	# FX success sound
	visible = false
	$CollisionShape3D.disabled = true
	print("Client: Harvest completed!")

@rpc("call_local")
func _respawn_visuals_rpc():
	visible = true
	$CollisionShape3D.disabled = false
