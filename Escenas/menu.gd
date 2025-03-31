extends Control

# Función que se ejecuta cuando pulsamos "Jugar"
func _on_button_pressed() -> void:
	# Usamos la función 'change_scene' para cambiar a la escena del juego
	GameManager.change_scene("res://Escenas/mundo.tscn")

# Función que se ejecuta cuando pulsamos "Opciones"
func _on_button_2_pressed() -> void:
	print("Opciones aún no implementadas.")

# Función que se ejecuta cuando pulsamos "Salir"
func _on_button_3_pressed() -> void:
	get_tree().quit()  # Salir del juego
