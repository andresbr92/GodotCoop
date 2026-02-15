@tool
extends GridDraggableElementUI
class_name GridItemStackUI

signal activated
signal clicked
signal middle_clicked
signal context_activated(event: InputEvent)

@export var stack_style: StyleBox
@export var hover_stack_style: StyleBox
@export var selected_stack_style: StyleBox
@export var unknown_icon: Texture2D

@onready var texture_bg: Panel = $TextureBG
@onready var item_icon: TextureRect = %ItemIcon
@onready var stack_size_label: Label = $StackSizeLabel
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream_player_2: AudioStreamPlayer = $AudioStreamPlayer2

var inventory : GridInventory
var stack: ItemStack


func setup(inv: Inventory, new_stack: ItemStack):
	self.inventory = inv
	self.stack = new_stack
	if stack and inventory != null:
		var definition: ItemDefinition = inventory.database.get_item(stack.item_id)
		tooltip_text = definition.description
		var is_rotated = inventory.is_stack_rotated(stack)
		var texture = definition.icon
		if is_rotated:
			var image = texture.get_image()
			image.rotate_90(CLOCKWISE)
			texture = ImageTexture.create_from_image(image)
		%ItemIcon.texture = texture

		activate()
		_disconnect_item_signals()
		_connect_item_signals(stack)
	else:
		%ItemIcon.texture = null
		deactivate()
	_update_stack_size()


func _connect_item_signals(new_item: ItemStack) -> void:
	if new_item == null:
		return

	if !new_item.updated.is_connected(_refresh):
		new_item.updated.connect(_refresh)

	if inventory != null and !inventory.updated_stack.is_connected(_update_stack_index):
		inventory.updated_stack.connect(_update_stack_index)


func _disconnect_item_signals() -> void:
	if !is_instance_valid(stack):
		return

	if stack.updated.is_connected(_refresh):
		stack.updated.disconnect(_refresh)

	if inventory != null and inventory.updated_stack.is_connected(_update_stack_index):
		inventory.updated_stack.disconnect(_update_stack_index)


func _ready() -> void:
	_set_panel_style(stack_style)
	mouse_entered.connect(func():
		# Solo feedback visual si está activo (revelado)
		if is_active(): 
			_set_panel_style(hover_stack_style)
			audio_stream_player_2.play()
	)
	mouse_exited.connect(func():
		_set_panel_style(stack_style)
	)
	grabbed.connect(func(_offset):
		visible = false
		audio_stream_player.play()
	)
	if stack == null:
		deactivate()
	else:
		# Ejecutar lógica visual al inicio
		_update_visuals()

func _update_visuals():
	if not stack or not inventory:
		return

	# 1. Comprobamos si está revelado (por defecto true si no existe la propiedad)
	var is_revealed: bool = stack.properties.get("revealed", true)
	
	if is_revealed:
		# --- ESTADO REVELADO (Lógica Original) ---
		var definition: ItemDefinition = inventory.database.get_item(stack.item_id)
		tooltip_text = definition.description
		
		# Gestión de rotación
		var is_rotated = inventory.is_stack_rotated(stack)
		var texture = definition.icon
		if is_rotated:
			var image = texture.get_image()
			image.rotate_90(CLOCKWISE)
			texture = ImageTexture.create_from_image(image)
		
		%ItemIcon.texture = texture
		%ItemIcon.modulate = Color(1, 1, 1, 1) # Restaurar color normal
		
		# Activar arrastre e interacción
		activate() 
		
	else:
		# --- ESTADO OCULTO ("Searching...") ---
		tooltip_text = "Searching..."
		
		# Usar icono de incógnita si existe, si no, poner el del item pero oscuro
		if unknown_icon:
			%ItemIcon.texture = unknown_icon
			%ItemIcon.modulate = Color(1, 1, 1, 1)
		else:
			# Fallback: Si no has asignado icono unknown, mostramos el item muy oscuro
			var definition = inventory.database.get_item(stack.item_id)
			%ItemIcon.texture = definition.icon
			%ItemIcon.modulate = Color(0.1, 0.1, 0.1, 1) # Muy oscuro/silueta
		
		# DESACTIVAR ARRASTRE (Importante: impide robarlo)
		deactivate()

	# Actualizar etiqueta de cantidad (si está oculto, quizás quieras ocultar la cantidad también)
	_update_stack_size(is_revealed)


func _update_stack_index(_stack_index: int) -> void:
	_refresh()


func select():
	if is_instance_valid(selected_stack_style):
		_set_panel_style(selected_stack_style)


func unselect():
	_set_panel_style(stack_style)


func _notification(what) -> void:
	if what == NOTIFICATION_DRAG_END:
		visible = true


func _update_stack_size(is_revealed: bool = true) -> void:
	if !is_instance_valid(stack_size_label):
		return
		
	# Si no está revelado, ocultamos la cantidad (opcional, estilo Tarkov hardcore)
	if not is_revealed:
		stack_size_label.text = "?"
		return

	if !is_instance_valid(stack):
		stack_size_label.text = ""
		return
	var stack_size: int = stack.amount
	if stack_size <= 1:
		if stack.properties.has("durability"):
			var definition: ItemDefinition = inventory.database.get_item(stack.item_id)
			if definition != null:
				var actual : float = stack.properties["durability"]
				var total : float = definition.properties["durability"]
				stack_size_label.text = str(int(actual/total * 100.0)) + "%"
				return
	else:
		stack_size_label.text = "%d" % stack_size
		return
	stack_size_label.text = ""


func _refresh() -> void:
	# Cuando el servidor actualiza la propiedad 'revealed' a true,
	# se dispara esta función. Re-ejecutamos la lógica visual.
	_update_visuals()


func create_preview() -> Control:
	var preview = self.duplicate()
	preview.setup(inventory, stack)
	preview.visible = true
	return preview


func _gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return
		
	# BLOQUEO DE INPUT SI NO ESTÁ REVELADO
	if not is_active():
		return 

	var mb_event: InputEventMouseButton = event
	if !mb_event.pressed:
		return
	if mb_event.button_index == MOUSE_BUTTON_LEFT:
		if mb_event.double_click:
			activated.emit()
		else:
			clicked.emit()
	if mb_event.button_index == MOUSE_BUTTON_MIDDLE:
		middle_clicked.emit()
	elif mb_event.button_index == MOUSE_BUTTON_MASK_RIGHT:
		context_activated.emit(mb_event)


func _set_panel_style(style: StyleBox) -> void:
	remove_theme_stylebox_override("panel")
	if style != null:
		add_theme_stylebox_override("panel", style)
