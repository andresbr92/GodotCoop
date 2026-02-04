extends Node

const PORT := 4000
const IP_ADDRESS := "localhost"
var peer : ENetMultiplayerPeer

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	
	
func connect_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	
func on_peer_connected(_client_id : int) -> void:
	print("client conected")

func on_peer_disconnected(_client_id : int) -> void:
	print("client disconnected")
