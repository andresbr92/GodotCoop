extends MultiplayerSpawner




func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	
	


func spawn_player(client_id : int) -> void:
	
	if not multiplayer.is_server(): return
	
	var player = preload("res://characters/player/player.tscn").instantiate()
	player.name = str(client_id)
	
	get_node(spawn_path).call_deferred("add_child", player)
