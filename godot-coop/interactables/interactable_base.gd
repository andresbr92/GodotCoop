class_name InteractableBase
extends StaticBody3D

# --- CONFIGURATION ---
@export_group("Interaction Settings")
@export var object_name: String = "Interactable"
@export var interaction_text: String = "Interact"


@export var default_action: InteractAction
var current_interactor: Node = null


var is_being_used: bool = false 

# --- INTERFAZ OBLIGATORIA (Contrato con InventoryInteractor) ---


func get_interaction_position(interaction_point: Vector3) -> Vector3:
	return global_position


func get_interact_actions(interactor: Node) -> Array:
	if not _can_interact(interactor):
		return []
	
	if default_action:
		default_action.description = interaction_text + " " + object_name
		return [default_action]
	
	return []


func interact(character: Node, action_index: int = 0) -> void:

	if not _can_interact(character):
		return
	
	
	if multiplayer.is_server():
		_server_interact(character)
	else:
		_request_interact_rpc.rpc_id(1, character.get_path())



func _can_interact(_character: Node) -> bool:
	return true # By default always allowed

# This is the function that Chests and Bushes will override
func _on_interacted(character: Node) -> void:
	print("Interacted with ", object_name)

# --- RED ---

@rpc("any_peer", "call_local", "reliable")
func _request_interact_rpc(character_path: NodePath) -> void:
	# Solo el servidor ejecuta esto
	if not multiplayer.is_server(): return
	
	var character = get_node(character_path)
	if character:
		_server_interact(character)

func _server_interact(character: Node):
	if current_interactor != null and current_interactor != character:
		print("Objeto ocupado por otro jugador")
		return

	current_interactor = character
	_on_interacted(character)


func cancel_interaction():
	if current_interactor == null: return
	
	print("Interacción cancelada con ", current_interactor.name)
	_on_interaction_canceled() # Hook virtual para los hijos
	current_interactor = null

func _on_interaction_canceled():
	pass
