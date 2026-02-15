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

func _ready():
	interaction_text = "Search"
	
	# Configurar generador
	if data:
		loot_generator.loot_id = data.loot_table_id
		# Apuntamos el generador a NUESTRO PROPIO inventario
		loot_generator.target_inventory_path = inventory.get_path()

# Sobrescribimos la interacción base
func _on_interacted(character: Node):
	# 1. ABRIR (Generar Loot si es la primera vez)
	if not is_opened:
		_first_time_generation()
		is_opened = true
	
	# 2. ABRIR UI DEL JUGADOR
	# Llamamos al sistema del personaje para que abra este inventario
	var char_sys = character.get_node_or_null("CharacterInventorySystem")
	if char_sys:
		char_sys.open_inventory(inventory)
	
	# 3. INICIAR PROCESO DE BÚSQUEDA (Secuencial)
	if data.auto_search_on_open and not searching_process_active:
		_start_revealing_sequence()

func _first_time_generation():
	if not multiplayer.is_server(): return
	
	# 1. Generar el loot (El generador llena el inventario)
	loot_generator.add_loot_to_inventory()
	
	# 2. POST-PROCESADO (Aquí está el arreglo)
	# Iteramos por CADA slot independientemente
	for i in range(inventory.stacks.size()):
		var stack = inventory.stacks[i]
		
		# Verificamos que hay un item en este slot
		if stack != null and stack.item_id != "":
			
			# TRUCO DE SEGURIDAD:
			# Duplicamos el diccionario de propiedades existente.
			# El 'true' significa "Deep Copy" (copia también sub-diccionarios si los hubiera).
			# Esto asegura que este stack tenga SU PROPIO diccionario, único en el mundo.
			var unique_properties = stack.properties.duplicate(true)
			
			# Ahora modificamos la copia única
			unique_properties["revealed"] = false
			
			# Y la reasignamos al stack.
			# Al reasignar, rompemos cualquier referencia anterior.
			stack.properties = unique_properties
			
			# IMPORTANTE: Forzar actualización del inventario para que el sistema sepa que cambió
			# (Dependiendo del addon, a veces reasignar properties no dispara la señal automáticamente)
			inventory.update_stack(i)
	
	print("Loot generado y ocultado individualmente.")

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
	
	# 1. Buscar el primer item oculto (Secuencial: de arriba a abajo, izq a der)
	var found_hidden = false
	
	for i in inventory.stacks.size():
		var stack = inventory.stacks[i]
		if stack != null and stack.item_id != "":
			if stack.properties.get("revealed", true) == false:
				# 2. REVELARLO
				stack.properties["revealed"] = true
				
				# Avisar al sistema para sincronizar este slot específico
				inventory.update_stack(i) 
				# O inventory.updated_stack.emit(i) dependiendo de tu addon
				
				found_hidden = true
				print("Item revelado en slot ", i)
				
				# 3. PROGRAMAR EL SIGUIENTE
				_schedule_next_reveal()
				return # Salimos, solo revelamos uno por tick

	# Si llegamos aquí, no quedan items ocultos
	searching_process_active = false
	print("Búsqueda completada.")

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
