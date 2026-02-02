extends Control



func _on_host_button_pressed() -> void:
	NetworkManager.start_server()
	hide()
	


func _on_client_button_pressed() -> void:
	NetworkManager.connect_client()
	hide()
	
