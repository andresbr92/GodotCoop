extends Node
class_name MainCoopScene

@export var player_scene : PackedScene
@export var database : InventoryDatabase

var connected_peer_ids : Array
var players : Array
var peer : ENetMultiplayerPeer



func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)




func host_game() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(4242)
	multiplayer.set_multiplayer_peer(peer)
	create_player(multiplayer.get_unique_id())
	$"UI/Connect Panel".visible = false
	await get_tree().create_timer(1).timeout
	make_scene_objects_to_network()

func create_player(client_id) -> void:
	connected_peer_ids.append(client_id)
	var player = player_scene.instantiate()
	player.name = str(client_id)
	players.append(player)
	player.position = Vector3(0,2,0)
	add_child(player)
	#if multiplayer.get_unique_id() == peer_id:
		#$"UI/Inventory System UI".setup(player.get_node("CharacterInventorySystem"))

func make_scene_objects_to_network() -> void:
	pass
	#var items = $Level/Items
	#var spawner = get_node("DroppedItemSpawner")
	#for i in items.get_child_count():
		#var item_dropped = items.get_child(i) as DroppedItem3D
		#var item_id : String = item_dropped.item_id
		#var definition = database.get_item(item_id)
		#var position = item_dropped.position
		#var rotation = item_dropped.rotation
		#var amount = item_dropped.amount
		#item_dropped.queue_free()
		#var dropped_item_path = definition.properties["dropped_item"]
		#var _obj = spawner.spawn([position, rotation, dropped_item_path, amount])

func _player_connected(new_peer_id : int):
	pass



func _player_disconnected(peer_id : int):
	pass



func _on_host_button_button_down() -> void:
	host_game()
	pass # Replace with function body.


func _on_connect_button_button_down() -> void:
	pass # Replace with function body.
