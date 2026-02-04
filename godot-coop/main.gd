extends Node
class_name MainCoopScene

@export var player : PackedScene


var connected_peer_ids : Array
var players : Array
var peer : ENetMultiplayerPeer



func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)

func _player_connected(new_peer_id : int):
	pass
	#if multiplayer.is_server():
		#add_newly_connected_player_character.rpc(new_peer_id)
		#add_previously_connected_player_characters.rpc_id(new_peer_id, connected_peer_ids)
		#create_player(new_peer_id)


func _player_disconnected(peer_id : int):
	pass
	#var pos = connected_peer_ids.find(peer_id)
	#if pos > 0 and pos < connected_peer_ids.size():
		#connected_peer_ids.remove_at(pos)
		#var player = players[pos]
		#players.remove_at(pos)
		#player.queue_free()
