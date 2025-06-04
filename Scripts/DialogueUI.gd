extends Control

@onready var dialogue_panel: Panel = $DialoguePanel
@onready var character_name: Label = $DialoguePanel/VBox/NameLabel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/VBox/HBox/DialogueText
@onready var choices_container: VBoxContainer = $DialoguePanel/VBox/ChoicesContainer
@onready var portrait: TextureRect = $DialoguePanel/VBox/HBox/Portrait
@onready var continue_button: Button = $DialoguePanel/VBox/ContinueButton

var current_choices: Array = []
var text_speed: float = 0.03
var is_text_complete: bool = false

signal choice_selected(choice_index: int)

func _ready():
	hide_dialogue()
	
	# Configurar botón continuar
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Configurar estilos
	setup_ui_styles()
	
	print("✅ DialogueUI inicializado correctamente")

func setup_ui_styles():
	# Estilo del panel principal
	if dialogue_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
		panel_style.border_width_left = 3
		panel_style.border_width_right = 3
		panel_style.border_width_top = 3
		panel_style.border_width_bottom = 3
		panel_style.border_color = Color(0.8, 0.6, 0.3, 1.0)
		panel_style.corner_radius_top_left = 10
		panel_style.corner_radius_top_right = 10
		panel_style.corner_radius_bottom_left = 10
		panel_style.corner_radius_bottom_right = 10
		dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Estilo del nombre del personaje
	if character_name:
		character_name.add_theme_color_override("font_color", Color.YELLOW)
		character_name.add_theme_font_size_override("font_size", 18)
	
	# Estilo del texto de diálogo
	if dialogue_text:
		dialogue_text.add_theme_color_override("default_color", Color.WHITE)
		dialogue_text.add_theme_font_size_override("normal_font_size", 14)

func show_dialogue(speaker_name: String, text: String, choices: Array):
	current_choices = choices
	is_text_complete = false
	
	print("🗣️ Mostrando diálogo:", speaker_name, "-", text.substr(0, 30) + "...")
	
	# Configurar UI
	if character_name:
		character_name.text = speaker_name
	
	if dialogue_text:
		dialogue_text.text = ""
	
	# Limpiar opciones anteriores
	clear_choices()
	
	# Mostrar panel y pausar juego
	if dialogue_panel:
		dialogue_panel.show()
	
	show()
	get_tree().paused = true
	
	# Animar texto
	animate_text(text)

func animate_text(text: String):
	if not dialogue_text:
		return
	
	dialogue_text.text = ""
	
	for i in range(text.length()):
		if not is_inside_tree():
			break
		
		dialogue_text.text += text[i]
		await get_tree().create_timer(text_speed).timeout
	
	is_text_complete = true
	show_choices()

func show_choices():
	if current_choices.is_empty():
		# Solo mostrar botón continuar
		if continue_button:
			continue_button.show()
			continue_button.text = "Continuar"
	else:
		if continue_button:
			continue_button.hide()
		
		# Crear botones para cada opción
		for i in range(current_choices.size()):
			var choice = current_choices[i]
			create_choice_button(choice, i)

func create_choice_button(choice: Dictionary, index: int):
	if not choices_container:
		return
	
	var button = Button.new()
	button.text = choice.text
	button.custom_minimum_size = Vector2(400, 40)
	
	# Aplicar estilos
	button.add_theme_stylebox_override("normal", create_choice_button_style())
	button.add_theme_stylebox_override("hover", create_choice_button_hover_style())
	button.add_theme_stylebox_override("pressed", create_choice_button_pressed_style())
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	button.add_theme_font_size_override("font_size", 12)
	
	# Verificar requisitos
	if choice.has("requirement") and choice.requirement:
		if not check_requirement(choice.requirement):
			button.disabled = true
			button.text += " (Requisito no cumplido)"
			button.add_theme_color_override("font_color", Color.GRAY)
	
	# Conectar señal
	button.pressed.connect(_on_choice_selected.bind(index))
	choices_container.add_child(button)

func check_requirement(requirement: String) -> bool:
	# Acceder al DialogueManager para verificar requisitos
	if has_node("/root/DialogueManager"):
		var dialogue_manager = get_node("/root/DialogueManager")
		return dialogue_manager.check_requirement(requirement)
	return true

func create_choice_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.4, 0.2, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func create_choice_button_hover_style() -> StyleBoxFlat:
	var style = create_choice_button_style()
	style.bg_color = Color(0.3, 0.3, 0.4, 0.9)
	style.border_color = Color(0.8, 0.6, 0.3, 1.0)
	return style

func create_choice_button_pressed_style() -> StyleBoxFlat:
	var style = create_choice_button_style()
	style.bg_color = Color(0.4, 0.4, 0.5, 0.9)
	style.border_color = Color(1.0, 0.8, 0.4, 1.0)
	return style

func _on_choice_selected(choice_index: int):
	print("🎯 Opción seleccionada:", choice_index)
	choice_selected.emit(choice_index)

func _on_continue_pressed():
	hide_dialogue()

func hide_dialogue():
	print("❌ Ocultando diálogo")
	
	if dialogue_panel:
		dialogue_panel.hide()
	
	hide()
	get_tree().paused = false
	
	# Notificar al DialogueManager
	if has_node("/root/DialogueManager"):
		var dialogue_manager = get_node("/root/DialogueManager")
		dialogue_manager.end_dialogue()

func clear_choices():
	if not choices_container:
		return
	
	for child in choices_container.get_children():
		child.queue_free()

func show_message(message: String):
	print("📢 Mensaje:", message)
	# Crear label temporal para mostrar mensajes
	var temp_label = Label.new()
	temp_label.text = message
	temp_label.add_theme_color_override("font_color", Color.RED)
	temp_label.position = Vector2(50, 50)
	add_child(temp_label)
	
	await get_tree().create_timer(2.0).timeout
	if temp_label and is_instance_valid(temp_label):
		temp_label.queue_free()

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		if not is_text_complete:
			# Completar texto inmediatamente
			is_text_complete = true
			if dialogue_text:
				# Aquí podrías completar el texto instantáneamente
				pass
		elif current_choices.is_empty():
			_on_continue_pressed()
