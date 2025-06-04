extends Node2D

var player_in_range: bool = false
var indicator_ui: Control = null
var speech_bubble: Panel = null

func _ready():
	create_interaction_indicator()
	hide_indicator()

func create_interaction_indicator():
	"""Crear un bonito bocadillo de diálogo"""
	# Crear CanvasLayer para la UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "InteractionUILayer"
	canvas_layer.layer = 150
	
	# Control principal
	indicator_ui = Control.new()
	indicator_ui.name = "InteractionUI"
	indicator_ui.anchors_preset = Control.PRESET_FULL_RECT
	indicator_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Bocadillo de diálogo
	speech_bubble = Panel.new()
	speech_bubble.name = "SpeechBubble"
	speech_bubble.size = Vector2(120, 50)
	
	# Estilo del bocadillo
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color(1, 1, 1, 0.95)
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2
	bubble_style.border_color = Color(0.3, 0.3, 0.3, 1)
	bubble_style.corner_radius_top_left = 15
	bubble_style.corner_radius_top_right = 15
	bubble_style.corner_radius_bottom_left = 15
	bubble_style.corner_radius_bottom_right = 5  # Esquina para la "cola"
	bubble_style.shadow_color = Color(0, 0, 0, 0.3)
	bubble_style.shadow_size = 5
	speech_bubble.add_theme_stylebox_override("panel", bubble_style)
	
	# Texto del bocadillo
	var bubble_text = Label.new()
	bubble_text.text = "💬 Presiona E"
	bubble_text.anchors_preset = Control.PRESET_FULL_RECT
	bubble_text.add_theme_font_size_override("font_size", 14)
	bubble_text.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_bubble.add_child(bubble_text)
	
	# Cola del bocadillo (triángulo pequeño)
	var bubble_tail = ColorRect.new()
	bubble_tail.size = Vector2(10, 10)
	bubble_tail.position = Vector2(100, 45)
	bubble_tail.color = Color(1, 1, 1, 0.95)
	bubble_tail.rotation = PI / 4  # 45 grados
	speech_bubble.add_child(bubble_tail)
	
	indicator_ui.add_child(speech_bubble)
	canvas_layer.add_child(indicator_ui)
	add_child(canvas_layer)

func show_indicator():
	"""Mostrar el indicador de interacción"""
	if not indicator_ui:
		return
	
	player_in_range = true
	indicator_ui.show()
	
	# Posicionar el bocadillo encima del NPC
	var npc_screen_pos = get_global_transform_with_canvas().origin
	speech_bubble.position = Vector2(
		npc_screen_pos.x - speech_bubble.size.x / 2,
		npc_screen_pos.y - 80  # Encima del NPC
	)
	
	# Animación de aparición
	speech_bubble.scale = Vector2(0.5, 0.5)
	speech_bubble.modulate.a = 0
	
	var tween = create_tween()
	tween.parallel().tween_property(speech_bubble, "scale", Vector2(1, 1), 0.3)
	tween.parallel().tween_property(speech_bubble, "modulate:a", 1.0, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animación de flotación
	start_floating_animation()

func hide_indicator():
	"""Ocultar el indicador de interacción"""
	player_in_range = false
	if indicator_ui:
		var tween = create_tween()
		tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): indicator_ui.hide())

func start_floating_animation():
	"""Animación de flotación suave del bocadillo"""
	if not player_in_range:
		return
	
	var original_y = speech_bubble.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(speech_bubble, "position:y", original_y - 5, 1.0)
	tween.tween_property(speech_bubble, "position:y", original_y + 5, 1.0)
	tween.set_ease(Tween.EASE_IN_OUT)

func _process(delta):
	# Actualizar posición del bocadillo si el jugador está en rango
	if player_in_range and speech_bubble:
		var npc_screen_pos = get_global_transform_with_canvas().origin
		var base_x = npc_screen_pos.x - speech_bubble.size.x / 2
		speech_bubble.position.x = base_x

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		show_indicator()

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		hide_indicator()

func _on_interaction_area_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("interact") and player_in_range:
		# Iniciar diálogo
		var dialogue_manager = get_node("/root/DialogueManager")
		if dialogue_manager:
			hide_indicator()
			dialogue_manager.start_dialogue("npc_merchant")  # O el ID correspondiente
