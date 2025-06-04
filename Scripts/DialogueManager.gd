extends Node

signal dialogue_started
signal dialogue_ended
signal dialogue_line_changed(line_text: String)
signal choice_selected(choice_index: int)

var is_dialogue_active: bool = false
var current_dialogue: Array = []
var current_line_index: int = 0
var dialogue_ui: Control = null

# Referencias a nodos de UI
var name_label: Label = null
var dialogue_text: Label = null
var continue_button: Button = null
var portrait_sprite: AnimatedSprite2D = null
var choices_container: VBoxContainer = null

# Base de datos de diálogos mejorada con opciones
var dialogue_database = {
	"npc_merchant": {
		"name": "Mercader",
		"portrait_scene": "res://Escenas/merchant.tscn",  # Escena del NPC para el portrait
		"lines": [
			"¡Hola aventurero! Bienvenido a mi tienda.",
			"Tengo los mejores objetos de toda la región.",
			{
				"text": "¿Te interesa algo en particular?",
				"choices": [
					{"text": "Sí, quiero ver tus productos", "action": "open_shop"},
					{"text": "No, solo estoy mirando", "action": "continue"}
				]
			}
		],
		"endings": {
			"open_shop": ["¡Excelente! Aquí tienes mi inventario."],
			"continue": ["¡Que tengas un buen día!"]
		}
	},
	"npc_guard": {
		"name": "Guardia",
		"portrait_scene": "res://Escenas/guard.tscn",
		"lines": [
			"Alto ahí, forastero.",
			"Esta es una zona segura.",
			"Mantén la paz y no habrá problemas."
		]
	},
	"npc_villager": {
		"name": "Aldeano",
		"portrait_scene": "res://Escenas/villager.tscn",
		"lines": [
			"¡Qué día tan hermoso!",
			"¿Has visto algo extraño por aquí?",
			"Ten cuidado en tus aventuras."
		]
	}
}

func _ready():
	print("🗣️ DialogueManager iniciado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_create_ui_deferred")

func _create_ui_deferred():
	await get_tree().process_frame
	create_dialogue_ui_programmatically()

func create_dialogue_ui_programmatically():
	print("🔨 Creando UI de diálogo en la parte inferior...")
	
	# Crear CanvasLayer con layer muy alto
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DialogueUILayer"
	canvas_layer.layer = 200
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crear Control principal
	dialogue_ui = Control.new()
	dialogue_ui.name = "DialogueUI"
	dialogue_ui.anchors_preset = Control.PRESET_FULL_RECT
	dialogue_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fondo semi-transparente solo en la parte superior
	var background_overlay = ColorRect.new()
	background_overlay.name = "BackgroundOverlay"
	background_overlay.anchors_preset = Control.PRESET_FULL_RECT
	background_overlay.color = Color(0, 0, 0, 0.4)  # Más sutil
	background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_ui.add_child(background_overlay)
	
	# Panel principal del diálogo - EN LA PARTE INFERIOR
	var dialogue_panel = Panel.new()
	dialogue_panel.name = "DialoguePanel"
	
	# Configurar para que esté en la parte inferior
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_width = viewport_size.x * 0.95  # 95% del ancho de pantalla
	var panel_height = 200  # Altura fija
	
	dialogue_panel.size = Vector2(panel_width, panel_height)
	# Posicionar en la parte inferior con un pequeño margen
	dialogue_panel.position = Vector2(
		(viewport_size.x - panel_width) / 2,  # Centrado horizontalmente
		viewport_size.y - panel_height - 20   # En la parte inferior con margen
	)
	
	# Estilo del panel mejorado
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.05, 0.1, 0.95)  # Más oscuro y opaco
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.8, 0.6, 0.2, 1)
	style_box.shadow_color = Color(0, 0, 0, 0.8)
	style_box.shadow_size = 15
	dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
	# Crear contenedor principal
	var margin_container = MarginContainer.new()
	margin_container.anchors_preset = Control.PRESET_FULL_RECT
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_top", 15)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_bottom", 15)
	
	# Contenedor horizontal principal
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 20)
	
	# PORTRAIT ANIMADO
	var portrait_container = Panel.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.custom_minimum_size = Vector2(120, 120)
	portrait_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	portrait_style.border_width_left = 2
	portrait_style.border_width_top = 2
	portrait_style.border_width_right = 2
	portrait_style.border_width_bottom = 2
	portrait_style.border_color = Color(0.8, 0.6, 0.2, 1)
	portrait_style.corner_radius_top_left = 10
	portrait_style.corner_radius_top_right = 10
	portrait_style.corner_radius_bottom_left = 10
	portrait_style.corner_radius_bottom_right = 10
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	
	# Sprite animado para el portrait
	portrait_sprite = AnimatedSprite2D.new()
	portrait_sprite.name = "PortraitSprite"
	portrait_sprite.position = Vector2(60, 60)  # Centro del contenedor
	portrait_sprite.scale = Vector2(0.8, 0.8)  # Escala apropiada
	portrait_container.add_child(portrait_sprite)
	
	# Contenedor de texto y opciones
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 10)
	
	# Nombre del personaje
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "Nombre del NPC"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Texto del diálogo - OCUPA TODO EL ESPACIO
	dialogue_text = Label.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.text = "Texto del diálogo aparecerá aquí..."
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_font_size_override("font_size", 16)
	dialogue_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
	dialogue_text.add_theme_constant_override("outline_size", 1)
	dialogue_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Contenedor para opciones de diálogo
	choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 8)
	choices_container.hide()  # Oculto por defecto
	
	# Contenedor para el botón de continuar
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_END
	
	# Botón de continuar mejorado
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "▶ ENTER para continuar"
	continue_button.add_theme_font_size_override("font_size", 14)
	continue_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	
	# Estilo del botón mejorado
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.2, 0.1, 0.8)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.8, 0.6, 0.2, 1)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	continue_button.add_theme_stylebox_override("normal", button_style)
	
	# Ensamblar la UI
	text_container.add_child(name_label)
	text_container.add_child(dialogue_text)
	text_container.add_child(choices_container)
	
	button_container.add_child(continue_button)
	text_container.add_child(button_container)
	
	main_hbox.add_child(portrait_container)
	main_hbox.add_child(text_container)
	
	margin_container.add_child(main_hbox)
	dialogue_panel.add_child(margin_container)
	dialogue_ui.add_child(dialogue_panel)
	canvas_layer.add_child(dialogue_ui)
	
	# Añadir a la escena
	get_tree().root.call_deferred("add_child", canvas_layer)
	
	# Conectar señales
	call_deferred("_connect_signals")
	
	# Ocultar inicialmente
	dialogue_ui.hide()
	
	print("✅ UI de diálogo creada en la parte inferior")

func _connect_signals():
	if continue_button and is_instance_valid(continue_button):
		continue_button.pressed.connect(_on_continue_button_pressed)
		print("✅ Señales del diálogo conectadas")

func load_portrait_animation(portrait_scene_path: String):
	"""Cargar animación del NPC para el portrait"""
	if not portrait_sprite or not is_instance_valid(portrait_sprite):
		return
	
	# Lista de posibles rutas para encontrar el NPC
	var possible_paths = [
		portrait_scene_path,
		"res://Escenas/merchant.tscn",
		"res://Escenas/guard.tscn", 
		"res://Escenas/villager.tscn",
		"res://Scenes/merchant.tscn",
		"res://Scenes/guard.tscn",
		"res://Scenes/villager.tscn"
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			var npc_scene = load(path)
			var npc_instance = npc_scene.instantiate()
			var npc_sprite = npc_instance.get_node_or_null("AnimatedSprite2D")
			
			if npc_sprite and npc_sprite.sprite_frames:
				portrait_sprite.sprite_frames = npc_sprite.sprite_frames
				
				# Intentar reproducir animación idle
				var idle_animations = ["idleFront", "idle", "default"]
				var animation_found = false
				
				for anim in idle_animations:
					if portrait_sprite.sprite_frames.has_animation(anim):
						portrait_sprite.play(anim)
						animation_found = true
						print("✅ Portrait animado cargado:", path, "- Animación:", anim)
						break
				
				if not animation_found:
					# Si no hay animaciones idle, usar la primera disponible
					var animations = portrait_sprite.sprite_frames.get_animation_names()
					if animations.size() > 0:
						portrait_sprite.play(animations[0])
						print("✅ Portrait cargado con animación:", animations[0])
				
				npc_instance.queue_free()
				return
			
			npc_instance.queue_free()
	
	print("❌ No se encontró ninguna escena de NPC válida")
	create_fallback_portrait()

func create_fallback_portrait():
	"""Crear portrait de respaldo si no se puede cargar la animación"""
	if not portrait_sprite:
		return
	
	# Crear SpriteFrames de respaldo
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("default")
	
	# Crear una textura simple de respaldo
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.5, 0.4, 1))  # Color piel
	var texture = ImageTexture.create_from_image(image)
	
	# Añadir frame a la animación
	sprite_frames.add_frame("default", texture)
	
	# Asignar al AnimatedSprite2D
	portrait_sprite.sprite_frames = sprite_frames
	portrait_sprite.play("default")
	
	print("✅ Portrait de respaldo creado")

func start_dialogue(dialogue_id: String):
	if is_dialogue_active:
		print("⚠️ Ya hay un diálogo activo")
		return
	
	if not dialogue_database.has(dialogue_id):
		print("❌ Diálogo no encontrado: ", dialogue_id)
		return
	
	if not dialogue_ui or not is_instance_valid(dialogue_ui):
		print("❌ No hay UI de diálogo disponible")
		return
	
	var dialogue_data = dialogue_database[dialogue_id]
	current_dialogue = dialogue_data.lines
	current_line_index = 0
	is_dialogue_active = true
	
	# Configurar nombre del personaje
	if name_label and is_instance_valid(name_label):
		name_label.text = dialogue_data.name
	
	# Cargar portrait animado
	if dialogue_data.has("portrait_scene"):
		load_portrait_animation(dialogue_data.portrait_scene)
	
	# Mostrar UI
	dialogue_ui.show()
	
	# Reposicionar el panel en la parte inferior
	var dialogue_panel = dialogue_ui.get_node("DialoguePanel")
	if dialogue_panel:
		var viewport_size = get_viewport().get_visible_rect().size
		var panel_width = viewport_size.x * 0.95
		var panel_height = 200
		
		dialogue_panel.size = Vector2(panel_width, panel_height)
		dialogue_panel.position = Vector2(
			(viewport_size.x - panel_width) / 2,
			viewport_size.y - panel_height - 20
		)
		
		# Animación de entrada desde abajo
		dialogue_panel.position.y += panel_height
		dialogue_panel.modulate.a = 0
		
		var tween = create_tween()
		tween.parallel().tween_property(dialogue_panel, "position:y", viewport_size.y - panel_height - 20, 0.4)
		tween.parallel().tween_property(dialogue_panel, "modulate:a", 1.0, 0.4)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
	
	show_current_line()
	
	# Pausar el juego
	get_tree().paused = true
	
	# Emitir señales
	dialogue_started.emit()
	
	print("🗣️ Diálogo iniciado: ", dialogue_id)

func show_current_line():
	if current_line_index >= current_dialogue.size():
		end_dialogue()
		return
	
	var current_line = current_dialogue[current_line_index]
	
	# Limpiar opciones anteriores
	clear_choices()
	
	if typeof(current_line) == TYPE_STRING:
		# Línea simple de texto
		show_text_line(current_line)
	elif typeof(current_line) == TYPE_DICTIONARY:
		# Línea con opciones
		show_choice_line(current_line)

func show_text_line(text: String):
	if dialogue_text and is_instance_valid(dialogue_text):
		dialogue_text.text = ""
		start_typing_effect(dialogue_text, text)
		continue_button.show()
		choices_container.hide()

func show_choice_line(line_data: Dictionary):
	if dialogue_text and is_instance_valid(dialogue_text):
		dialogue_text.text = ""
		start_typing_effect(dialogue_text, line_data.text)
		continue_button.hide()
		
		# Mostrar opciones después del efecto de escritura
		await get_tree().create_timer(line_data.text.length() * 0.03 + 0.5).timeout
		show_choices(line_data.choices)

func show_choices(choices: Array):
	if not choices_container:
		return
	
	choices_container.show()
	
	for i in range(choices.size()):
		var choice = choices[i]
		var choice_button = Button.new()
		choice_button.text = "► " + choice.text
		choice_button.add_theme_font_size_override("font_size", 14)
		choice_button.add_theme_color_override("font_color", Color.WHITE)
		choice_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Estilo del botón de opción
		var choice_style = StyleBoxFlat.new()
		choice_style.bg_color = Color(0.2, 0.15, 0.1, 0.8)
		choice_style.border_width_left = 1
		choice_style.border_width_top = 1
		choice_style.border_width_right = 1
		choice_style.border_width_bottom = 1
		choice_style.border_color = Color(0.6, 0.4, 0.2, 1)
		choice_style.corner_radius_top_left = 5
		choice_style.corner_radius_top_right = 5
		choice_style.corner_radius_bottom_left = 5
		choice_style.corner_radius_bottom_right = 5
		choice_button.add_theme_stylebox_override("normal", choice_style)
		
		var choice_hover_style = choice_style.duplicate()
		choice_hover_style.bg_color = Color(0.3, 0.2, 0.1, 0.9)
		choice_hover_style.border_color = Color(0.8, 0.6, 0.2, 1)
		choice_button.add_theme_stylebox_override("hover", choice_hover_style)
		
		# Conectar la señal
		choice_button.pressed.connect(_on_choice_selected.bind(i, choice))
		choices_container.add_child(choice_button)

func _on_choice_selected(choice_index: int, choice_data: Dictionary):
	print("🎯 Opción seleccionada:", choice_data.text)
	
	# Limpiar opciones
	clear_choices()
	
	# Ejecutar acción según la elección
	match choice_data.action:
		"open_shop":
			end_dialogue()
			# Aquí abrir la tienda
			open_merchant_shop()
		"continue":
			# Continuar con el final correspondiente
			show_dialogue_ending("continue")
		_:
			# Acción por defecto
			end_dialogue()

func show_dialogue_ending(ending_key: String):
	var dialogue_data = dialogue_database[get_current_dialogue_id()]
	if dialogue_data.has("endings") and dialogue_data.endings.has(ending_key):
		var ending_lines = dialogue_data.endings[ending_key]
		current_dialogue = ending_lines
		current_line_index = 0
		show_current_line()

func get_current_dialogue_id() -> String:
	# Función auxiliar para obtener el ID del diálogo actual
	# Por simplicidad, asumimos que es el mercader si hay endings
	return "npc_merchant"

func open_merchant_shop():
	print("🏪 Abriendo tienda del mercader...")
	
	# Cerrar diálogo primero
	end_dialogue()
	
	# Abrir tienda
	var shop_manager = get_node_or_null("/root/ShopManager")
	if shop_manager:
		shop_manager.open_shop("merchant_general")
	else:
		print("❌ ShopManager no encontrado")

func clear_choices():
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()

func start_typing_effect(label: Label, text: String):
	if not is_instance_valid(label):
		return
		
	label.text = ""
	var tween = create_tween()
	
	for i in range(text.length() + 1):
		tween.tween_callback(func(): 
			if is_instance_valid(label):
				label.text = text.substr(0, i)
		)
		tween.tween_interval(0.03)

func next_line():
	if not is_dialogue_active:
		return
	
	current_line_index += 1
	show_current_line()

func end_dialogue():
	if not is_dialogue_active:
		return
	
	is_dialogue_active = false
	current_dialogue = []
	current_line_index = 0
	
	# Animación de salida hacia abajo
	if dialogue_ui and is_instance_valid(dialogue_ui):
		var dialogue_panel = dialogue_ui.get_node("DialoguePanel")
		if dialogue_panel:
			var tween = create_tween()
			tween.parallel().tween_property(dialogue_panel, "position:y", dialogue_panel.position.y + dialogue_panel.size.y, 0.3)
			tween.parallel().tween_property(dialogue_panel, "modulate:a", 0.0, 0.3)
			tween.tween_callback(func(): dialogue_ui.hide())
	
	# Reanudar el juego
	get_tree().paused = false
	
	dialogue_ended.emit()
	print("🔚 Diálogo terminado")

func _on_continue_button_pressed():
	next_line()

func _input(event):
	if is_dialogue_active and event.is_action_pressed("ui_accept"):
		if continue_button.visible:
			next_line()
