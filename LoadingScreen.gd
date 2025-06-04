extends Control

# Pantalla de carga con animaciones y tips

var config = {}
var tips = []
var current_tip_index = 0
var tip_timer = 0.0
var tip_change_interval = 3.0

# Referencias a nodos
var background: ColorRect
var main_container: VBoxContainer
var title_label: Label
var progress_container: VBoxContainer
var progress_bar: ProgressBar
var progress_label: Label
var spinner: Control
var tip_label: Label
var loading_icon: Label

# Colores del tema
var colors = {
	"background": Color(0.05, 0.05, 0.08, 1.0),
	"accent": Color(0.8, 0.6, 0.2, 1),
	"text_primary": Color(0.95, 0.95, 0.95, 1),
	"text_secondary": Color(0.7, 0.7, 0.7, 1),
	"progress_bg": Color(0.2, 0.2, 0.25, 1),
	"progress_fill": Color(0.8, 0.6, 0.2, 1)
}

func _ready():
	name = "LoadingScreen"
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	create_loading_ui()

func setup(loading_config: Dictionary, loading_tips: Array):
	config = loading_config
	tips = loading_tips
	current_tip_index = randi() % tips.size()
	
	# Configurar visibilidad según configuración
	if progress_container:
		progress_container.visible = config.get("show_progress", true)
	
	if tip_label:
		tip_label.visible = config.get("show_tips", true)
		update_tip()

func create_loading_ui():
	# Fondo principal
	background = ColorRect.new()
	background.name = "Background"
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.color = colors.background
	add_child(background)
	
	# Contenedor principal centrado
	main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchors_preset = Control.PRESET_CENTER
	main_container.add_theme_constant_override("separation", 40)
	add_child(main_container)
	
	# Título
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "🎮 CARGANDO..."
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", colors.accent)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Icono de carga animado
	loading_icon = Label.new()
	loading_icon.name = "LoadingIcon"
	loading_icon.text = "⚡"
	loading_icon.add_theme_font_size_override("font_size", 64)
	loading_icon.add_theme_color_override("font_color", colors.accent)
	loading_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(loading_icon)
	
	# Contenedor de progreso
	progress_container = VBoxContainer.new()
	progress_container.name = "ProgressContainer"
	progress_container.add_theme_constant_override("separation", 15)
	main_container.add_child(progress_container)
	
	# Barra de progreso
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(400, 20)
	progress_bar.value = 0
	progress_bar.max_value = 100
	
	# Estilo de la barra de progreso
	var progress_style_bg = StyleBoxFlat.new()
	progress_style_bg.bg_color = colors.progress_bg
	progress_style_bg.corner_radius_top_left = 10
	progress_style_bg.corner_radius_top_right = 10
	progress_style_bg.corner_radius_bottom_left = 10
	progress_style_bg.corner_radius_bottom_right = 10
	
	var progress_style_fill = StyleBoxFlat.new()
	progress_style_fill.bg_color = colors.progress_fill
	progress_style_fill.corner_radius_top_left = 10
	progress_style_fill.corner_radius_top_right = 10
	progress_style_fill.corner_radius_bottom_left = 10
	progress_style_fill.corner_radius_bottom_right = 10
	
	progress_bar.add_theme_stylebox_override("background", progress_style_bg)
	progress_bar.add_theme_stylebox_override("fill", progress_style_fill)
	
	progress_container.add_child(progress_bar)
	
	# Etiqueta de progreso
	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Preparando..."
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", colors.text_secondary)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_container.add_child(progress_label)
	
	# Separador
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color.TRANSPARENT)
	separator.custom_minimum_size = Vector2(0, 20)
	main_container.add_child(separator)
	
	# Etiqueta de tips
	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.add_theme_font_size_override("font_size", 18)
	tip_label.add_theme_color_override("font_color", colors.text_primary)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.custom_minimum_size = Vector2(600, 0)
	main_container.add_child(tip_label)
	
	# Iniciar animaciones
	start_animations()

func start_animations():
	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Animación del icono de carga
	animate_loading_icon()
	
	# Animación del título
	animate_title()

func animate_loading_icon():
	if not loading_icon:
		return
	
	var icons = ["⚡", "🔄", "⭐", "✨", "🌟"]
	var icon_index = 0
	
	var tween = create_tween()
	tween.set_loops()
	
	for i in range(icons.size()):
		tween.tween_callback(func(): 
			if loading_icon and is_instance_valid(loading_icon):
				loading_icon.text = icons[icon_index]
				icon_index = (icon_index + 1) % icons.size()
		)
		tween.tween_interval(0.3)

func animate_title():
	if not title_label:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate:a", 0.6, 1.0)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)

func update_progress(progress: float):
	if not progress_bar or not progress_label:
		return
	
	var percentage = progress * 100
	progress_bar.value = percentage
	
	# Actualizar texto según el progreso
	var status_text = ""
	if percentage < 25:
		status_text = "Inicializando..."
	elif percentage < 50:
		status_text = "Cargando recursos..."
	elif percentage < 75:
		status_text = "Preparando escena..."
	elif percentage < 95:
		status_text = "Finalizando..."
	else:
		status_text = "¡Casi listo!"
	
	progress_label.text = status_text + " " + str(int(percentage)) + "%"

func update_tip():
	if not tip_label or tips.size() == 0:
		return
	
	tip_label.text = tips[current_tip_index]
	
	# Animación de cambio de tip
	var tween = create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		if tip_label and is_instance_valid(tip_label):
			tip_label.text = tips[current_tip_index]
	)
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3)

func _process(delta):
	# Cambiar tips periódicamente
	if config.get("show_tips", true) and tips.size() > 1:
		tip_timer += delta
		if tip_timer >= tip_change_interval:
			tip_timer = 0.0
			current_tip_index = (current_tip_index + 1) % tips.size()
			update_tip()

func hide_with_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): hide())
