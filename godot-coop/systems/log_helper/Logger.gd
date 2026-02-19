extends Node

# Al usar la anotación @vararg (en Godot 4) o simplemente 
# pasando un Array si prefieres, pero la forma más limpia es esta:
func log(arg1 = "", arg2 = "", arg3 = "", arg4 = "", arg5 = "") -> void:
	var id = multiplayer.get_unique_id()
	var prefijo = ""
	
	if id == 1:
		prefijo = "[SERVER]"
	else:
		prefijo = "[CLIENT %s]" % id
	
	# Metemos todos los argumentos en un array para procesarlos
	var parametros = [arg1, arg2, arg3, arg4, arg5]
	var mensaje_final = ""
	
	for p in parametros:
		if str(p) != "":
			mensaje_final += str(p) + " " # Espacio simple, o "\t" para estilo printt()
			
	print("%s %s" % [prefijo, mensaje_final.strip_edges()])
