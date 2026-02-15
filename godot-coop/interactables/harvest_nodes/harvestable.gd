class_name Harvestable
extends InteractableBase

@onready var loot_generator: LootGenerator = $LootGenerator

# --- DATA ---
@export var data: HarvestableData # ¡Arrastra aquí tu .tres!

# --- ESTADO (Server Side) ---
var current_harvester: Node = null # Quién me está recolectando
var harvest_timer: float = 0.0
var is_harvesting: bool = false
var is_looted: bool = false

# Configuración máxima distancia para cancelar si se aleja
const MAX_HARVEST_DISTANCE_SQR = 3.0 * 3.0 

func _ready():
	# Configuración inicial desde el Data
	if data and data.loot_table_id != "":
		loot_generator.loot_id = data.loot_table_id
	
	interaction_text = "Harvest"
	set_process(false) # Desactivamos process para ahorrar CPU

func _on_interacted(character: Node):
	# Validaciones iniciales
	if is_looted or is_harvesting: return
	if not data: 
		printerr("Falta HarvestableData en ", name)
		return

	# INICIO DE RECOLECCIÓN (Server)
	current_harvester = character
	is_harvesting = true
	harvest_timer = 0.0
	
	# Nos conectamos a la señal de daño del jugador para cancelar si le pegan
	if current_harvester.has_signal("damaged"):
		current_harvester.damaged.connect(_on_harvester_damaged)
	
	# Activamos el loop de chequeo
	set_process(true)
	
	# RPC: Avisar al cliente para que muestre la barra de progreso UI
	_start_harvest_visuals_rpc.rpc(data.harvest_duration)

func _process(delta: float):
	if not multiplayer.is_server(): return
	
	# 1. CHEQUEO DE CANCELACIÓN
	if not is_instance_valid(current_harvester):
		_cancel_harvest()
		return
		
	# A. ¿Se ha movido? (Chequeamos velocidad)
	# Asumimos que character tiene propiedad 'velocity' (CharacterBase la tiene)
	if current_harvester.velocity.length_squared() > 0.1:
		_cancel_harvest()
		return
		
	# B. ¿Se ha alejado demasiado? (Por si le empujan o se teletransporta)
	if global_position.distance_squared_to(current_harvester.global_position) > MAX_HARVEST_DISTANCE_SQR:
		_cancel_harvest()
		return

	# 2. PROGRESO
	harvest_timer += delta
	
	if harvest_timer >= data.harvest_duration:
		_finish_harvest()

# Callback si el jugador recibe daño
func _on_harvester_damaged():
	_cancel_harvest()

func _cancel_harvest():
	if not is_harvesting: return
	
	is_harvesting = false
	set_process(false)
	
	# Desconectar señal de daño
	if is_instance_valid(current_harvester) and current_harvester.has_signal("damaged"):
		current_harvester.damaged.disconnect(_on_harvester_damaged)
	
	current_harvester = null
	
	# RPC: Avisar al cliente que oculte la barra/cancele animación
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
	# AQUÍ ES DONDE CONECTARÍAS CON TU UI
	# Ejemplo: GlobalUI.show_progress_bar(duration, "Harvesting...")
	print("Cliente: Empezando a recolectar... (", duration, "s)")

@rpc("call_local")
func _cancel_harvest_visuals_rpc():
	# GlobalUI.hide_progress_bar()
	print("Cliente: Recolección cancelada.")

@rpc("call_local")
func _success_harvest_visuals_rpc():
	# GlobalUI.hide_progress_bar()
	# FX sonido éxito
	visible = false
	$CollisionShape3D.disabled = true
	print("Cliente: ¡Recolección completada!")

@rpc("call_local")
func _respawn_visuals_rpc():
	visible = true
	$CollisionShape3D.disabled = false
