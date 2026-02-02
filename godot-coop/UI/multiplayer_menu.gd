extends Control

@onready var multiplayer_spawner: MultiplayerSpawner = %MultiplayerSpawner


func _on_host_button_pressed() -> void:
	NetworkManager.start_server()
	multiplayer_spawner.spawn_player(1)
	hide()
	


func _on_client_button_pressed() -> void:
	NetworkManager.connect_client()
	hide()
	
