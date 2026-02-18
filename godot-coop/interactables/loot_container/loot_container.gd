class_name LootContainer
extends InteractableBase

# --- REFERENCIAS ---
@onready var inventory: Inventory = $GridInventory
@onready var loot_generator: LootGenerator = $LootGenerator
@onready var reveal_timer: Timer = $RevealTimer
@onready var openable: NetworkedOpenable = $NetworkedOpenable


# --- DATA ---
@export var data: LootContainerData

# --- ESTADO ---
var is_opened: bool = false
var searching_process_active: bool = false
const MAX_INTERACT_DISTANCE_SQR = 3.0 * 3.0

func _ready():
	$GridInventory.set_multiplayer_authority(1)
	$GridInventory/SyncGridInventory.set_multiplayer_authority(1)
	$NetworkedOpenable.set_multiplayer_authority(1)
	$LootGenerator.set_multiplayer_authority(1)
	interaction_text = "Search"
	
	# Configurar generador
	if data:
		loot_generator.loot_id = data.loot_table_id
		# Apuntamos el generador a NUESTRO PROPIO inventario
		loot_generator.target_inventory_path = inventory.get_path()
func _process(_delta):
	if not multiplayer.is_server(): return
	
	if current_interactor == null:
		set_process(false)
		return
		
	# If too far away -> Force cancel
	if global_position.distance_squared_to(current_interactor.global_position) > MAX_INTERACT_DISTANCE_SQR:
		# Force close UI on client (optional, but recommended)
		var char_sys = current_interactor.get_node_or_null("CharacterInventorySystem")
		if char_sys:
			char_sys.close_inventories() # This will trigger the closed_inventory signal
		
		cancel_interaction()
# Override base interaction
func _on_interacted(character: Node):
	# Previous inventory opening logic...
	if not is_opened:
		_first_time_generation()
		is_opened = true
	
	var char_sys = character.get_node_or_null("CharacterInventorySystem")
	if char_sys:
		char_sys.open_inventory(inventory)
		
		# CONNECTION: Listen if player closes inventory voluntarily
		# Connect with CONNECT_ONE_SHOT flag so it disconnects automatically when triggered
		if not char_sys.closed_inventory.is_connected(_on_player_closed_inventory):
			char_sys.closed_inventory.connect(_on_player_closed_inventory)
	
	# Activate distance check
	set_process(true)
	
	# Start search
	if data.auto_search_on_open:
		_start_revealing_sequence()

func _on_player_closed_inventory(closed_inv: Inventory):
	# Verify they closed THIS inventory (in case they have multiple open)
	if closed_inv == inventory:
		cancel_interaction()

func _on_interaction_canceled():
	# STOP THE REVEAL PROCESS
	searching_process_active = false
	reveal_timer.stop()
	set_process(false) # Stop checking distance
	
	# Disconnect signal for safety (if it wasn't one_shot or if we cancel due to distance)
	if current_interactor:
		var char_sys = current_interactor.get_node_or_null("CharacterInventorySystem")
		if char_sys and char_sys.closed_inventory.is_connected(_on_player_closed_inventory):
			char_sys.closed_inventory.disconnect(_on_player_closed_inventory)
	
	print("Search stopped. Remaining items stay hidden.")

func _first_time_generation():
	if not multiplayer.is_server(): return
	
	loot_generator.add_loot_to_inventory()
	
	for i in range(inventory.stacks.size()):
		var stack = inventory.stacks[i]
		if stack != null and stack.item_id != "":
			var unique_properties = stack.properties.duplicate(true)
			
			# CAMBIO: En lugar de 'revealed' = false, usamos un array vacío
			# Este array contendrá los Peer IDs de quienes ya lo descubrieron.
			unique_properties["revealed_to"] = [] 
			
			stack.properties = unique_properties
			inventory.update_stack(i)
	
	print("Loot generated with per-player reveal system.")

func _start_revealing_sequence():
	if not multiplayer.is_server(): return
	if searching_process_active: return
	
	# Buscamos si queda algo por revelar
	if _has_hidden_items():
		searching_process_active = true
		_schedule_next_reveal()

func _schedule_next_reveal():
	# Conectamos el timer para el siguiente "tick"
	if not reveal_timer.is_connected("timeout", _reveal_next_item):
		reveal_timer.timeout.connect(_reveal_next_item)
	
	reveal_timer.start(data.seconds_to_reveal_per_item)

func _reveal_next_item():
	if not multiplayer.is_server(): return
	if not is_instance_valid(current_interactor): return
	
	# Obtenemos la ID del jugador actual (asumiendo que el nombre es la ID, según tu setup)
	var player_id = current_interactor.name.to_int()
	
	for i in inventory.stacks.size():
		var stack = inventory.stacks[i]
		if stack != null and stack.item_id != "":
			# Recuperamos la lista (o creamos una si no existe por seguridad)
			var revealed_list: Array = stack.properties.get("revealed_to", [])
			
			# Si ESTE jugador NO está en la lista...
			if player_id not in revealed_list:
				# 2. REVEAL IT FOR THIS PLAYER
				revealed_list.append(player_id)
				stack.properties["revealed_to"] = revealed_list
				
				# Sincronizamos
				inventory.update_stack(i) 
				
				print("Item revealed in slot ", i, " for player ", player_id)
				
				_schedule_next_reveal()
				return 

	searching_process_active = false
	print("Search completed for player ", player_id)

func _has_hidden_items() -> bool:
	if not is_instance_valid(current_interactor): return false
	var player_id = current_interactor.name.to_int()
	
	for stack in inventory.stacks:
		if stack != null and stack.item_id != "":
			var revealed_list: Array = stack.properties.get("revealed_to", [])
			# Si el jugador NO está en la lista, significa que para él está oculto
			if player_id not in revealed_list:
				return true
	return false

func open(character : Node):
	openable.open(character)


func close(character : Node):
	openable.close(character)
