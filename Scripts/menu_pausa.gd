extends Control

# Referencias a los botones
@onready var resume_button = $MarginContainer/VBoxContainer/Button
@onready var options_button = $MarginContainer/VBoxContainer/Button2
@onready var main_menu_button = $MarginContainer/VBoxContainer/Button3
@onready var quit_game_button = $MarginContainer/VBoxContainer/Button4

# Función que se ejecuta cuando se inicia la escena
func _ready():
	self.process_mode = PROCESS_MODE_ALWAYS  # Asegurarse de que el menú de pausa siempre procese
	for child in get_children():
		child.process_mode = PROCESS_MODE_ALWAYS  # Asegurar que los hijos también procesen

	# Conectar las señales de los botones
	resume_button.pressed.connect(_on_resume_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_game_button.pressed.connect(_on_quit_game_button_pressed)

	# Ocultar el menú al inicio
	self.visible = false

# Detectar la tecla Escape para alternar el menú de pausa
func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		toggle_show_menu()

# Mostrar u ocultar el menú de pausa
func toggle_show_menu():
	if not self.visible:
		self.visible = true
		get_tree().paused = true  # Pausar el resto del juego
		print("Menú de pausa visible:", self.visible)
	else:
		self.visible = false
		get_tree().paused = false  # Reanudar el resto del juego
		print("Menú de pausa visible:", self.visible)

# Funciones de los botones
func _on_resume_button_pressed():
	toggle_show_menu()

func _on_options_button_pressed():
	print("Opciones aún no implementadas.")  # Placeholder para opciones

func _on_main_menu_button_pressed():
	get_tree().paused = false  # Reanudar el juego antes de cambiar de escena

	# Obtener la escena actual
	var current_scene = get_tree().current_scene

	# Verificar si la escena actual es el mundo y eliminarlo
	if current_scene and current_scene.scene_file_path == "res://Escenas/mundo.tscn":
		current_scene.free()  # Eliminar completamente la escena del mundo

	# Alternativa: eliminar todos los nodos hijos excepto el menú de pausa
	var root = get_tree().get_root()
	for child in root.get_children():
		if child != self:  # No eliminar el menú de pausa
			child.queue_free()

	# Cambiar a la escena del menú principal
	get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")
	



func _on_quit_game_button_pressed():
	get_tree().quit()
