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
	
	# 1. Generate loot (The generator fills the inventory)
	loot_generator.add_loot_to_inventory()
	
	# 2. POST-PROCESSING (Here's the fix)
	# Iterate through EACH slot independently
	for i in range(inventory.stacks.size()):
		var stack = inventory.stacks[i]
		
		# Verify there's an item in this slot
		if stack != null and stack.item_id != "":
			
			# SAFETY TRICK:
			# Duplicate the existing properties dictionary.
			# The 'true' means "Deep Copy" (also copies sub-dictionaries if any).
			# This ensures this stack has ITS OWN dictionary, unique in the world.
			var unique_properties = stack.properties.duplicate(true)
			
			# Now modify the unique copy
			unique_properties["revealed"] = false
			
			# And reassign it to the stack.
			# By reassigning, we break any previous reference.
			stack.properties = unique_properties
			
			# IMPORTANT: Force inventory update so the system knows it changed
			# (Depending on the addon, sometimes reassigning properties doesn't trigger the signal automatically)
			inventory.update_stack(i)
	
	print("Loot generated and hidden individually.")

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
	
	# 1. Find the first hidden item (Sequential: top to bottom, left to right)
	var found_hidden = false
	
	for i in inventory.stacks.size():
		var stack = inventory.stacks[i]
		if stack != null and stack.item_id != "":
			if stack.properties.get("revealed", true) == false:
				# 2. REVEAL IT
				stack.properties["revealed"] = true
				
				# Notify system to sync this specific slot
				inventory.update_stack(i) 
				# Or inventory.updated_stack.emit(i) depending on your addon
				
				found_hidden = true
				print("Item revealed in slot ", i)
				
				# 3. SCHEDULE THE NEXT ONE
				_schedule_next_reveal()
				return # Exit, we only reveal one per tick

	# If we reach here, no hidden items remain
	searching_process_active = false
	print("Search completed.")

func _has_hidden_items() -> bool:
	for stack in inventory.stacks:
		if stack != null and stack.item_id != "":
			print(stack.properties.get("revealed"))
			if stack.properties.get("revealed", true) == false:
				return true
	return false

func open(character : Node):
	openable.open(character)


func close(character : Node):
	openable.close(character)
