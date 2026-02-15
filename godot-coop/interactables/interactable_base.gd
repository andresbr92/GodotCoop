class_name InteractableBase
extends StaticBody3D

# --- CONFIGURACIÓN ---
@export_group("Interaction Settings")
@export var object_name: String = "Interactable"
@export var interaction_text: String = "Interact"


@export var default_action: InteractAction 


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
	return true # Por defecto siempre se puede

# Esta es la función que Cofres y Arbustos sobrescribirán
func _on_interacted(character: Node) -> void:
	print("Interactuado con ", object_name)

# --- RED ---

@rpc("any_peer", "call_local", "reliable")
func _request_interact_rpc(character_path: NodePath) -> void:
	# Solo el servidor ejecuta esto
	if not multiplayer.is_server(): return
	
	var character = get_node(character_path)
	if character:
		_server_interact(character)

func _server_interact(character: Node) -> void:
	# Aquí podríamos validar distancia, obstáculos, etc.
	_on_interacted(character)
