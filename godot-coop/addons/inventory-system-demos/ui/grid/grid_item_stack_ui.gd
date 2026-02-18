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
		# Only visual feedback if active (revealed)
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
		# Execute visual logic at start
		_update_visuals()

func _update_visuals():
	if not stack or not inventory:
		return

	# CAMBIO: Lógica basada en array de IDs
	var is_revealed = true
	
	if stack.properties.has("revealed_to"):
		var revealed_list = stack.properties["revealed_to"]
		var my_id = multiplayer.get_unique_id()
		
		# Si mi ID no está, no está revelado para mí
		if my_id not in revealed_list:
			is_revealed = false
	else:
		# Retrocompatibilidad o items normales sin esta mecánica
		# Si existe la vieja propiedad 'revealed', la usamos, si no, true.
		is_revealed = stack.properties.get("revealed", true)
	
	if is_revealed:
		# --- REVEALED STATE (Lógica original) ---
		var definition: ItemDefinition = inventory.database.get_item(stack.item_id)
		tooltip_text = definition.description
		
		var is_rotated = inventory.is_stack_rotated(stack)
		var texture = definition.icon
		if is_rotated:
			var image = texture.get_image()
			image.rotate_90(CLOCKWISE)
			texture = ImageTexture.create_from_image(image)
		
		%ItemIcon.texture = texture
		%ItemIcon.modulate = Color(1, 1, 1, 1)
		
		activate() 
		
	else:
		# --- HIDDEN STATE ---
		tooltip_text = "Searching..."
		
		if unknown_icon:
			%ItemIcon.texture = unknown_icon
			%ItemIcon.modulate = Color(1, 1, 1, 1)
		else:
			var definition = inventory.database.get_item(stack.item_id)
			%ItemIcon.texture = definition.icon
			%ItemIcon.modulate = Color(0.0, 0.0, 0.0, 1) # Negro total
		
		deactivate()

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
		
	# If not revealed, hide quantity (optional, Tarkov hardcore style)
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
	# When the server updates the 'revealed' property to true,
	# this function is triggered. Re-execute visual logic.
	_update_visuals()


func create_preview() -> Control:
	var preview = self.duplicate()
	preview.setup(inventory, stack)
	preview.visible = true
	return preview


func _gui_input(event: InputEvent) -> void:
	if !(event is InputEventMouseButton):
		return
		
	# BLOCK INPUT IF NOT REVEALED
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
