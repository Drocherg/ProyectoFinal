extends Node

signal inventory_updated
signal item_equipped(item_data, slot)
signal item_unequipped(slot)

# Constantes
const MAX_INVENTORY_SLOTS = 24
const MAX_EQUIP_SLOTS = 6

# Tipos de ranuras de equipamiento
enum EquipSlot {
	HEAD,
	BODY,
	LEGS,
	WEAPON,
	SHIELD,
	ACCESSORY
}

# Datos del inventario
var inventory_items = []
var equipped_items = {
	EquipSlot.HEAD: null,
	EquipSlot.BODY: null,
	EquipSlot.LEGS: null,
	EquipSlot.WEAPON: null,
	EquipSlot.SHIELD: null,
	EquipSlot.ACCESSORY: null
}

# Referencia a la UI
var inventory_ui = null
var is_inventory_open = false

# Variables para arrastrar la ventana
var is_dragging = false
var drag_offset = Vector2.ZERO
var draggable_areas = []
var drag_border_width = 15

# Colores del tema
var colors = {
	"background": Color(0.08, 0.08, 0.12, 0.95),
	"panel": Color(0.12, 0.12, 0.18, 0.9),
	"border": Color(0.3, 0.25, 0.2, 1),
	"accent": Color(0.8, 0.6, 0.2, 1),
	"text_primary": Color(0.95, 0.95, 0.95, 1),
	"text_secondary": Color(0.7, 0.7, 0.7, 1),
	"slot_empty": Color(0.15, 0.15, 0.2, 0.8),
	"slot_filled": Color(0.2, 0.2, 0.25, 0.9),
	"slot_selected": Color(0.4, 0.3, 0.2, 0.9),
	"rarity_common": Color(0.6, 0.6, 0.6, 1),
	"rarity_uncommon": Color(0.3, 0.8, 0.3, 1),
	"rarity_rare": Color(0.3, 0.3, 0.9, 1),
	"rarity_epic": Color(0.7, 0.3, 0.9, 1),
	"rarity_legendary": Color(1, 0.6, 0.1, 1)
}

# Base de datos de objetos
var item_database = {
	"sword": {
		"id": "sword",
		"name": "Espada de Hierro",
		"icon": "res://Assets/Items/sword.png",
		"type": "weapon",
		"equip_slot": EquipSlot.WEAPON,
		"rarity": "common",
		"stats": {
			"attack": 5
		},
		"description": "Una espada básica de hierro forjada por herreros novatos."
	},
	"shield": {
		"id": "shield",
		"name": "Escudo de Roble",
		"icon": "res://Assets/Items/shield.png",
		"type": "shield",
		"equip_slot": EquipSlot.SHIELD,
		"rarity": "common",
		"stats": {
			"defense": 3
		},
		"description": "Un escudo resistente tallado en madera de roble."
	},
	"helmet": {
		"id": "helmet",
		"name": "Yelmo del Guardián",
		"icon": "res://Assets/Items/helmet.png",
		"type": "armor",
		"equip_slot": EquipSlot.HEAD,
		"rarity": "uncommon",
		"stats": {
			"defense": 4,
			"health": 5
		},
		"description": "Un yelmo usado por los guardianes del reino."
	},
	"chest": {
		"id": "chest",
		"name": "Armadura de Placas",
		"icon": "res://Assets/Items/chest.png",
		"type": "armor",
		"equip_slot": EquipSlot.BODY,
		"rarity": "rare",
		"stats": {
			"defense": 8,
			"health": 10
		},
		"description": "Una armadura de placas que ofrece excelente protección."
	},
	"potion": {
		"id": "potion",
		"name": "Poción de Salud",
		"icon": "res://Assets/Items/potion.png",
		"type": "consumable",
		"rarity": "common",
		"stats": {
			"health": 20
		},
		"description": "Una poción mágica que restaura la vitalidad."
	}
}

var selected_inventory_slot = -1
var selected_equip_slot = -1

func _ready():
	print("🎒 InventoryManager iniciado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Añadir algunos objetos de prueba
	add_item("sword")
	add_item("shield")
	add_item("helmet")
	add_item("chest")
	add_item("potion", 3)
	
	# Usar call_deferred para crear la UI después de que el árbol esté listo
	call_deferred("_create_ui_deferred")

func _create_ui_deferred():
	await get_tree().process_frame
	create_enhanced_inventory_ui()

func create_enhanced_inventory_ui():
	print("🔨 Creando UI de inventario mejorada...")
	
	# Crear CanvasLayer para la UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "InventoryUILayer"
	canvas_layer.layer = 50
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crear el control principal
	inventory_ui = Control.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.anchors_preset = Control.PRESET_FULL_RECT
	inventory_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.name = "Background"
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.color = Color(0, 0, 0, 0.6)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_ui.add_child(background)
	
	# Panel principal del inventario
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.anchors_preset = Control.PRESET_CENTER
	main_panel.size = Vector2(900, 650)
	main_panel.position = Vector2(-450, -325)
	
	# Estilo principal
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = colors.background
	main_style.border_width_left = 3
	main_style.border_width_top = 3
	main_style.border_width_right = 3
	main_style.border_width_bottom = 3
	main_style.border_color = colors.accent
	main_style.corner_radius_top_left = 12
	main_style.corner_radius_top_right = 12
	main_style.corner_radius_bottom_left = 12
	main_style.corner_radius_bottom_right = 12
	main_style.shadow_color = Color(0, 0, 0, 0.5)
	main_style.shadow_size = 8
	main_panel.add_theme_stylebox_override("panel", main_style)
	
	# Crear áreas arrastrables en todos los bordes ANTES del contenido
	create_draggable_borders(main_panel)
	
	# Título del inventario
	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.anchors_preset = Control.PRESET_TOP_WIDE
	title_container.offset_top = 15
	title_container.offset_bottom = 55
	title_container.offset_left = 20
	title_container.offset_right = -20
	
	var title_label = Label.new()
	title_label.text = "⚔️ INVENTARIO ⚔️"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", colors.accent)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(title_label)
	
	# Botón de cerrar
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_color_override("font_color", colors.text_primary)
	close_button.flat = true
	close_button.pressed.connect(_on_close_button_pressed)
	title_container.add_child(close_button)
	
	main_panel.add_child(title_container)
	
	# Contenedor principal (SIN el texto de instrucciones)
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.offset_top = 70  # Reducido desde 70 ya que no hay texto de instrucciones
	main_container.offset_bottom = -20
	main_container.offset_left = 20
	main_container.offset_right = -20
	main_container.add_theme_constant_override("separation", 20)
	
	# Crear paneles
	create_equipment_panel(main_container)
	create_inventory_panel(main_container)
	create_info_panel(main_container)
	
	main_panel.add_child(main_container)
	inventory_ui.add_child(main_panel)
	canvas_layer.add_child(inventory_ui)
	
	# Añadir a la escena usando call_deferred
	get_tree().root.call_deferred("add_child", canvas_layer)
	
	# Configurar la UI después de que se añada
	call_deferred("_setup_ui_deferred")
	inventory_ui.hide()
	
	print("✅ UI de inventario creada con arrastre desde todos los bordes")

func create_draggable_borders(main_panel: Panel):
	# Limpiar áreas anteriores
	draggable_areas.clear()
	
	# Crear áreas arrastrables en todos los bordes
	var border_areas = [
		# Borde superior
		{
			"name": "DragTop",
			"preset": Control.PRESET_TOP_WIDE,
			"offset_top": 0,
			"offset_bottom": drag_border_width,
			"cursor": Input.CURSOR_MOVE
		},
		# Borde inferior
		{
			"name": "DragBottom",
			"preset": Control.PRESET_BOTTOM_WIDE,
			"offset_top": -drag_border_width,
			"offset_bottom": 0,
			"cursor": Input.CURSOR_MOVE
		},
		# Borde izquierdo
		{
			"name": "DragLeft",
			"preset": Control.PRESET_LEFT_WIDE,
			"offset_left": 0,
			"offset_right": drag_border_width,
			"cursor": Input.CURSOR_MOVE
		},
		# Borde derecho
		{
			"name": "DragRight",
			"preset": Control.PRESET_RIGHT_WIDE,
			"offset_left": -drag_border_width,
			"offset_right": 0,
			"cursor": Input.CURSOR_MOVE
		}
	]
	
	for area_data in border_areas:
		var drag_area = Control.new()
		drag_area.name = area_data.name
		drag_area.anchors_preset = area_data.preset
		drag_area.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Configurar offsets según el área
		if area_data.has("offset_top"):
			drag_area.offset_top = area_data.offset_top
		if area_data.has("offset_bottom"):
			drag_area.offset_bottom = area_data.offset_bottom
		if area_data.has("offset_left"):
			drag_area.offset_left = area_data.offset_left
		if area_data.has("offset_right"):
			drag_area.offset_right = area_data.offset_right
		
		# Conectar eventos
		drag_area.mouse_entered.connect(_on_drag_area_mouse_entered)
		drag_area.mouse_exited.connect(_on_drag_area_mouse_exited)
		drag_area.gui_input.connect(_on_drag_area_input)
		
		# Añadir al panel y a la lista
		main_panel.add_child(drag_area)
		draggable_areas.append(drag_area)

func _on_drag_area_mouse_entered():
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func _on_drag_area_mouse_exited():
	if not is_dragging:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_drag_area_input(event: InputEvent):
	var main_panel = inventory_ui.get_node_or_null("MainPanel")
	if not main_panel:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = event.global_position - main_panel.global_position
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
				
				var tween = create_tween()
				tween.tween_property(main_panel, "scale", Vector2(1.02, 1.02), 0.1)
				highlight_draggable_borders(true)
			else:
				is_dragging = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				
				var tween = create_tween()
				tween.tween_property(main_panel, "scale", Vector2(1.0, 1.0), 0.1)
				highlight_draggable_borders(false)
				clamp_window_to_screen(main_panel)
	
	elif event is InputEventMouseMotion and is_dragging:
		var new_position = event.global_position - drag_offset
		main_panel.global_position = new_position

func highlight_draggable_borders(highlight: bool):
	var main_panel = inventory_ui.get_node_or_null("MainPanel")
	if not main_panel:
		return
	
	if highlight:
		var border_highlight = Panel.new()
		border_highlight.name = "BorderHighlight"
		border_highlight.anchors_preset = Control.PRESET_FULL_RECT
		border_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var highlight_style = StyleBoxFlat.new()
		highlight_style.bg_color = Color.TRANSPARENT
		highlight_style.border_width_left = 2
		highlight_style.border_width_top = 2
		highlight_style.border_width_right = 2
		highlight_style.border_width_bottom = 2
		highlight_style.border_color = Color(colors.accent.r, colors.accent.g, colors.accent.b, 0.8)
		highlight_style.corner_radius_top_left = 12
		highlight_style.corner_radius_top_right = 12
		highlight_style.corner_radius_bottom_left = 12
		highlight_style.corner_radius_bottom_right = 12
		border_highlight.add_theme_stylebox_override("panel", highlight_style)
		
		main_panel.add_child(border_highlight)
		
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(border_highlight, "modulate:a", 0.3, 0.5)
		tween.tween_property(border_highlight, "modulate:a", 0.8, 0.5)
	else:
		var border_highlight = main_panel.get_node_or_null("BorderHighlight")
		if border_highlight:
			border_highlight.queue_free()

func clamp_window_to_screen(main_panel: Panel):
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = main_panel.size
	
	var min_x = -panel_size.x + 100
	var max_x = viewport_size.x - 100
	var min_y = 0
	var max_y = viewport_size.y - 100
	
	var clamped_position = Vector2(
		clamp(main_panel.global_position.x, min_x, max_x),
		clamp(main_panel.global_position.y, min_y, max_y)
	)
	
	if main_panel.global_position != clamped_position:
		var tween = create_tween()
		tween.tween_property(main_panel, "global_position", clamped_position, 0.2)
		tween.set_ease(Tween.EASE_OUT)

func _setup_ui_deferred():
	await get_tree().process_frame
	setup_inventory_ui()

func create_equipment_panel(parent):
	var equipment_panel = Panel.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.custom_minimum_size = Vector2(220, 0)
	
	var equipment_style = StyleBoxFlat.new()
	equipment_style.bg_color = colors.panel
	equipment_style.border_width_left = 2
	equipment_style.border_width_top = 2
	equipment_style.border_width_right = 2
	equipment_style.border_width_bottom = 2
	equipment_style.border_color = colors.border
	equipment_style.corner_radius_top_left = 8
	equipment_style.corner_radius_top_right = 8
	equipment_style.corner_radius_bottom_left = 8
	equipment_style.corner_radius_bottom_right = 8
	equipment_panel.add_theme_stylebox_override("panel", equipment_style)
	
	var equipment_margin = MarginContainer.new()
	equipment_margin.name = "MarginContainer"
	equipment_margin.anchors_preset = Control.PRESET_FULL_RECT
	equipment_margin.add_theme_constant_override("margin_left", 15)
	equipment_margin.add_theme_constant_override("margin_top", 15)
	equipment_margin.add_theme_constant_override("margin_right", 15)
	equipment_margin.add_theme_constant_override("margin_bottom", 15)
	
	var equipment_vbox = VBoxContainer.new()
	equipment_vbox.name = "VBoxContainer"
	equipment_vbox.add_theme_constant_override("separation", 15)
	
	# Título del equipamiento
	var equipment_title = Label.new()
	equipment_title.text = "🛡️ EQUIPAMIENTO"
	equipment_title.add_theme_font_size_override("font_size", 16)
	equipment_title.add_theme_color_override("font_color", colors.accent)
	equipment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_vbox.add_child(equipment_title)
	
	# Contenedor de slots de equipamiento
	var equipment_slots = VBoxContainer.new()
	equipment_slots.name = "EquipmentSlots"
	equipment_slots.add_theme_constant_override("separation", 10)
	equipment_vbox.add_child(equipment_slots)
	
	# Estadísticas del jugador
	var stats_separator = HSeparator.new()
	stats_separator.add_theme_color_override("separator", colors.border)
	equipment_vbox.add_child(stats_separator)
	
	var stats_title = Label.new()
	stats_title.text = "📊 ESTADÍSTICAS"
	stats_title.add_theme_font_size_override("font_size", 14)
	stats_title.add_theme_color_override("font_color", colors.accent)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_vbox.add_child(stats_title)
	
	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 5)
	equipment_vbox.add_child(stats_container)
	
	equipment_margin.add_child(equipment_vbox)
	equipment_panel.add_child(equipment_margin)
	parent.add_child(equipment_panel)

func create_inventory_panel(parent):
	var inventory_panel = Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var inventory_style = StyleBoxFlat.new()
	inventory_style.bg_color = colors.panel
	inventory_style.border_width_left = 2
	inventory_style.border_width_top = 2
	inventory_style.border_width_right = 2
	inventory_style.border_width_bottom = 2
	inventory_style.border_color = colors.border
	inventory_style.corner_radius_top_left = 8
	inventory_style.corner_radius_top_right = 8
	inventory_style.corner_radius_bottom_left = 8
	inventory_style.corner_radius_bottom_right = 8
	inventory_panel.add_theme_stylebox_override("panel", inventory_style)
	
	var inventory_margin = MarginContainer.new()
	inventory_margin.name = "MarginContainer"
	inventory_margin.anchors_preset = Control.PRESET_FULL_RECT
	inventory_margin.add_theme_constant_override("margin_left", 15)
	inventory_margin.add_theme_constant_override("margin_top", 15)
	inventory_margin.add_theme_constant_override("margin_right", 15)
	inventory_margin.add_theme_constant_override("margin_bottom", 15)
	
	var inventory_vbox = VBoxContainer.new()
	inventory_vbox.name = "VBoxContainer"
	inventory_vbox.add_theme_constant_override("separation", 15)
	
	# Título del inventario
	var inventory_title = Label.new()
	inventory_title.text = "🎒 OBJETOS"
	inventory_title.add_theme_font_size_override("font_size", 16)
	inventory_title.add_theme_color_override("font_color", colors.accent)
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_vbox.add_child(inventory_title)
	
	# Grid de inventario
	var inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = 6
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	inventory_vbox.add_child(inventory_grid)
	
	inventory_margin.add_child(inventory_vbox)
	inventory_panel.add_child(inventory_margin)
	parent.add_child(inventory_panel)

func create_info_panel(parent):
	var info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.custom_minimum_size = Vector2(300, 0)
	info_panel.hide()
	
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = colors.panel
	info_style.border_width_left = 2
	info_style.border_width_top = 2
	info_style.border_width_right = 2
	info_style.border_width_bottom = 2
	info_style.border_color = colors.border
	info_style.corner_radius_top_left = 8
	info_style.corner_radius_top_right = 8
	info_style.corner_radius_bottom_left = 8
	info_style.corner_radius_bottom_right = 8
	info_panel.add_theme_stylebox_override("panel", info_style)
	
	# Contenedor principal con márgenes
	var main_container = MarginContainer.new()
	main_container.name = "MainContainer"
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.add_theme_constant_override("margin_left", 15)
	main_container.add_theme_constant_override("margin_top", 15)
	main_container.add_theme_constant_override("margin_right", 15)
	main_container.add_theme_constant_override("margin_bottom", 15)
	
	# Contenedor vertical principal
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 10)
	
	# Header con título y botón de cerrar
	var header_container = HBoxContainer.new()
	header_container.name = "HeaderContainer"
	
	var header_title = Label.new()
	header_title.text = "📋 INFORMACIÓN"
	header_title.add_theme_font_size_override("font_size", 14)
	header_title.add_theme_color_override("font_color", colors.accent)
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(header_title)
	
	# Botón X para cerrar el panel de información
	var close_info_button = Button.new()
	close_info_button.name = "CloseInfoButton"
	close_info_button.text = "✕"
	close_info_button.custom_minimum_size = Vector2(30, 30)
	close_info_button.add_theme_font_size_override("font_size", 16)
	close_info_button.add_theme_color_override("font_color", colors.text_primary)
	close_info_button.flat = true
	close_info_button.pressed.connect(_on_close_info_button_pressed)
	header_container.add_child(close_info_button)
	
	main_vbox.add_child(header_container)
	
	# Separador después del header
	var header_separator = HSeparator.new()
	header_separator.add_theme_color_override("separator", colors.border)
	main_vbox.add_child(header_separator)
	
	# Contenido con scroll
	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.add_theme_constant_override("separation", 15)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Nombre del objeto
	var item_name = Label.new()
	item_name.name = "ItemName"
	item_name.add_theme_font_size_override("font_size", 20)
	item_name.add_theme_color_override("font_color", colors.accent)
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_container.add_child(item_name)
	
	# Tipo y rareza
	var item_type = Label.new()
	item_type.name = "ItemType"
	item_type.add_theme_font_size_override("font_size", 14)
	item_type.add_theme_color_override("font_color", colors.text_secondary)
	item_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_type.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_container.add_child(item_type)
	
	# Separador
	var separator1 = HSeparator.new()
	separator1.add_theme_color_override("separator", colors.border)
	content_container.add_child(separator1)
	
	# Descripción
	var description_label = Label.new()
	description_label.text = "📖 DESCRIPCIÓN"
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.add_theme_color_override("font_color", colors.accent)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(description_label)
	
	var item_description = Label.new()
	item_description.name = "ItemDescription"
	item_description.add_theme_font_size_override("font_size", 13)
	item_description.add_theme_color_override("font_color", colors.text_primary)
	item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content_container.add_child(item_description)
	
	# Separador
	var separator2 = HSeparator.new()
	separator2.add_theme_color_override("separator", colors.border)
	content_container.add_child(separator2)
	
	# Estadísticas
	var stats_label = Label.new()
	stats_label.text = "📈 ESTADÍSTICAS"
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", colors.accent)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(stats_label)
	
	var item_stats = Label.new()
	item_stats.name = "ItemStats"
	item_stats.add_theme_font_size_override("font_size", 13)
	item_stats.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))
	item_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content_container.add_child(item_stats)
	
	# Separador
	var separator3 = HSeparator.new()
	separator3.add_theme_color_override("separator", colors.border)
	content_container.add_child(separator3)
	
	# Botones de acción
	var buttons_label = Label.new()
	buttons_label.text = "⚡ ACCIONES"
	buttons_label.add_theme_font_size_override("font_size", 14)
	buttons_label.add_theme_color_override("font_color", colors.accent)
	buttons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(buttons_label)
	
	var buttons_container = VBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.add_theme_constant_override("separation", 8)
	
	var equip_button = Button.new()
	equip_button.name = "EquipButton"
	equip_button.text = "⚔️ EQUIPAR"
	equip_button.add_theme_font_size_override("font_size", 14)
	equip_button.pressed.connect(_on_equip_button_pressed)
	style_action_button(equip_button, Color(0.2, 0.6, 0.2, 1))
	buttons_container.add_child(equip_button)
	
	var unequip_button = Button.new()
	unequip_button.name = "UnequipButton"
	unequip_button.text = "🛡️ DESEQUIPAR"
	unequip_button.add_theme_font_size_override("font_size", 14)
	unequip_button.pressed.connect(_on_unequip_button_pressed)
	style_action_button(unequip_button, Color(0.6, 0.4, 0.2, 1))
	buttons_container.add_child(unequip_button)
	
	var use_button = Button.new()
	use_button.name = "UseButton"
	use_button.text = "🧪 USAR"
	use_button.add_theme_font_size_override("font_size", 14)
	use_button.pressed.connect(_on_use_button_pressed)
	style_action_button(use_button, Color(0.2, 0.4, 0.6, 1))
	buttons_container.add_child(use_button)
	
	content_container.add_child(buttons_container)
	main_vbox.add_child(content_container)
	main_container.add_child(main_vbox)
	info_panel.add_child(main_container)
	parent.add_child(info_panel)

func style_action_button(button: Button, base_color: Color):
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = base_color
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = base_color.lightened(0.3)
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	
	var button_style_hover = button_style.duplicate()
	button_style_hover.bg_color = base_color.lightened(0.2)
	
	var button_style_pressed = button_style.duplicate()
	button_style_pressed.bg_color = base_color.darkened(0.2)
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_style_hover)
	button.add_theme_stylebox_override("pressed", button_style_pressed)
	button.add_theme_color_override("font_color", Color.WHITE)

func setup_inventory_ui():
	if not inventory_ui or not is_instance_valid(inventory_ui):
		print("❌ UI de inventario no disponible para configurar")
		return
	
	var equipment_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/EquipmentPanel/MarginContainer/VBoxContainer/EquipmentSlots")
	var inventory_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/InventoryPanel/MarginContainer/VBoxContainer/InventoryGrid")
	
	if not equipment_container:
		print("❌ No se encontró el contenedor de equipamiento")
		return
	
	if not inventory_container:
		print("❌ No se encontró el contenedor de inventario")
		return
	
	# Crear ranuras de equipamiento
	var equipment_slots_data = [
		{"type": EquipSlot.HEAD, "name": "HEAD", "icon": "🪖", "label": "Cabeza"},
		{"type": EquipSlot.BODY, "name": "BODY", "icon": "🛡️", "label": "Pecho"},
		{"type": EquipSlot.LEGS, "name": "LEGS", "icon": "👖", "label": "Piernas"},
		{"type": EquipSlot.WEAPON, "name": "WEAPON", "icon": "⚔️", "label": "Arma"},
		{"type": EquipSlot.SHIELD, "name": "SHIELD", "icon": "🛡️", "label": "Escudo"},
		{"type": EquipSlot.ACCESSORY, "name": "ACCESSORY", "icon": "💍", "label": "Accesorio"}
	]
	
	for slot_data in equipment_slots_data:
		var slot = create_enhanced_equipment_slot(slot_data.type, slot_data.name, slot_data.icon, slot_data.label)
		equipment_container.add_child(slot)
	
	# Crear ranuras de inventario
	for i in range(MAX_INVENTORY_SLOTS):
		var slot = create_enhanced_inventory_slot(i)
		inventory_container.add_child(slot)
	
	# Crear estadísticas del jugador
	update_player_stats()
	
	# Actualizar visualización
	update_inventory_display()
	
	print("✅ UI de inventario configurada correctamente")

func create_enhanced_equipment_slot(equip_type: int, slot_name: String, icon: String, label: String) -> Panel:
	var slot = Panel.new()
	slot.name = "EquipmentSlot_" + slot_name
	slot.custom_minimum_size = Vector2(180, 50)
	slot.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Estilo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_empty
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = colors.border
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Contenedor horizontal
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.add_theme_constant_override("margin_left", 10)
	hbox.add_theme_constant_override("margin_top", 8)
	hbox.add_theme_constant_override("margin_right", 10)
	hbox.add_theme_constant_override("margin_bottom", 8)
	hbox.add_theme_constant_override("separation", 10)
	
	# Icono del tipo de slot
	var type_icon = Label.new()
	type_icon.text = icon
	type_icon.add_theme_font_size_override("font_size", 20)
	type_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(type_icon)
	
	# Información del slot
	var info_vbox = VBoxContainer.new()
	info_vbox.name = "VBoxContainer"
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var slot_label = Label.new()
	slot_label.name = "SlotLabel"
	slot_label.text = label
	slot_label.add_theme_font_size_override("font_size", 12)
	slot_label.add_theme_color_override("font_color", colors.text_secondary)
	info_vbox.add_child(slot_label)
	
	var item_name = Label.new()
	item_name.name = "ItemName"
	item_name.text = "Vacío"
	item_name.add_theme_font_size_override("font_size", 14)
	item_name.add_theme_color_override("font_color", colors.text_primary)
	info_vbox.add_child(item_name)
	
	hbox.add_child(info_vbox)
	
	# Icono del objeto equipado
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.custom_minimum_size = Vector2(32, 32)
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(item_icon)
	
	slot.add_child(hbox)
	
	# Conectar señal de clic
	slot.gui_input.connect(_on_equipment_slot_input.bind(equip_type))
	
	# Añadir propiedades personalizadas
	slot.set_meta("equip_type", equip_type)
	slot.set_meta("item_data", null)
	
	return slot

func create_enhanced_inventory_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.name = "InventorySlot_" + str(index)
	slot.custom_minimum_size = Vector2(70, 70)
	slot.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Estilo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_empty
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = colors.border
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Icono del objeto
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchors_preset = Control.PRESET_FULL_RECT
	item_icon.offset_left = 6
	item_icon.offset_top = 6
	item_icon.offset_right = -6
	item_icon.offset_bottom = -6
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(item_icon)
	
	# Borde de rareza
	var rarity_border = Panel.new()
	rarity_border.name = "RarityBorder"
	rarity_border.anchors_preset = Control.PRESET_FULL_RECT
	rarity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_border.hide()
	slot.add_child(rarity_border)
	
	# Etiqueta de cantidad
	var quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	quantity_label.offset_right = -4
	quantity_label.offset_bottom = -4
	quantity_label.add_theme_font_size_override("font_size", 12)
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_constant_override("outline_size", 1)
	quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
	quantity_label.hide()
	slot.add_child(quantity_label)
	
	# Conectar señal de clic
	slot.gui_input.connect(_on_inventory_slot_input.bind(index))
	
	# Añadir propiedades personalizadas
	slot.set_meta("slot_index", index)
	slot.set_meta("item_data", null)
	
	return slot

func toggle_inventory():
	if not inventory_ui:
		print("❌ UI de inventario no disponible")
		return
	
	is_inventory_open = !is_inventory_open
	
	if is_inventory_open:
		inventory_ui.show()
		update_inventory_display()
		update_player_stats()
		
		# Centrar la ventana en la pantalla
		var main_panel = inventory_ui.get_node("MainPanel")
		var viewport_size = get_viewport().get_visible_rect().size
		var panel_size = main_panel.size
		
		# Calcular posición centrada
		var centered_position = Vector2(
			(viewport_size.x - panel_size.x) / 2,
			(viewport_size.y - panel_size.y) / 2
		)
		
		# Aplicar posición centrada
		main_panel.global_position = centered_position
		
		# Animación de entrada
		main_panel.scale = Vector2(0.8, 0.8)
		main_panel.modulate.a = 0
		
		var tween = create_tween()
		tween.parallel().tween_property(main_panel, "scale", Vector2(1, 1), 0.3)
		tween.parallel().tween_property(main_panel, "modulate:a", 1.0, 0.3)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		print("✅ Inventario abierto")
	else:
		# Animación de salida
		var main_panel = inventory_ui.get_node("MainPanel")
		var tween = create_tween()
		tween.parallel().tween_property(main_panel, "scale", Vector2(0.8, 0.8), 0.2)
		tween.parallel().tween_property(main_panel, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): inventory_ui.hide())
		
		print("✅ Inventario cerrado")

# Resto de funciones (mantener las funciones existentes)
func add_item(item_id: String, quantity: int = 1):
	if not item_database.has(item_id):
		print("❌ Objeto no encontrado en la base de datos: ", item_id)
		return false
	
	# Comprobar si ya tenemos este objeto (para objetos apilables)
	for item in inventory_items:
		if item.id == item_id and item.has("quantity"):
			item.quantity += quantity
			inventory_updated.emit()
			return true
	
	# Si no existe o no es apilable, añadir nuevo
	if inventory_items.size() < MAX_INVENTORY_SLOTS:
		var item_data = item_database[item_id].duplicate()
		if item_data.type == "consumable":
			item_data.quantity = quantity
		
		inventory_items.append(item_data)
		inventory_updated.emit()
		return true
	
	print("❌ Inventario lleno")
	return false

func remove_item(inventory_index: int, quantity: int = 1):
	if inventory_index < 0 or inventory_index >= inventory_items.size():
		return false
	
	var item = inventory_items[inventory_index]
	
	if item.has("quantity"):
		item.quantity -= quantity
		if item.quantity <= 0:
			inventory_items.remove_at(inventory_index)
	else:
		inventory_items.remove_at(inventory_index)
	
	inventory_updated.emit()
	return true

func equip_item(inventory_index: int):
	if inventory_index < 0 or inventory_index >= inventory_items.size():
		return false
	
	var item = inventory_items[inventory_index]
	
	# Verificar si es equipable
	if not item.has("equip_slot"):
		print("❌ Este objeto no es equipable")
		return false
	
	# Desequipar objeto actual en esa ranura si existe
	if equipped_items[item.equip_slot] != null:
		unequip_item(item.equip_slot)
	
	# Equipar nuevo objeto
	equipped_items[item.equip_slot] = item
	inventory_items.remove_at(inventory_index)
	
	# Emitir señal
	item_equipped.emit(item, item.equip_slot)
	inventory_updated.emit()
	
	print("✅ Objeto equipado: ", item.name)
	return true

func unequip_item(equip_slot):
	if equipped_items[equip_slot] == null:
		return false
	
	var item = equipped_items[equip_slot]
	
	# Verificar espacio en inventario
	if inventory_items.size() >= MAX_INVENTORY_SLOTS:
		print("❌ Inventario lleno, no se puede desequipar")
		return false
	
	# Desequipar y añadir al inventario
	equipped_items[equip_slot] = null
	inventory_items.append(item)
	
	# Emitir señal
	item_unequipped.emit(equip_slot)
	inventory_updated.emit()
	
	print("✅ Objeto desequipado: ", item.name)
	return true

func use_item(inventory_index: int):
	if inventory_index < 0 or inventory_index >= inventory_items.size():
		return false
	
	var item = inventory_items[inventory_index]
	
	# Verificar si es consumible
	if item.type != "consumable":
		print("❌ Este objeto no es consumible")
		return false
	
	# Aplicar efectos del objeto
	if item.stats.has("health"):
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("heal"):
			player.heal(item.stats.health)
	
	# Reducir cantidad o eliminar
	remove_item(inventory_index, 1)
	
	print("✅ Objeto usado: ", item.name)
	return true

func get_equipped_stats():
	var total_stats = {
		"attack": 0,
		"defense": 0,
		"health": 0
	}
	
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item and item.has("stats"):
			for stat in item.stats:
				if total_stats.has(stat):
					total_stats[stat] += item.stats[stat]
				else:
					total_stats[stat] = item.stats[stat]
	
	return total_stats

func update_player_stats():
	if not inventory_ui or not is_instance_valid(inventory_ui):
		return
		
	var stats_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/EquipmentPanel/MarginContainer/VBoxContainer/StatsContainer")
	if not stats_container:
		return
	
	# Limpiar estadísticas anteriores
	for child in stats_container.get_children():
		child.queue_free()
	
	# Calcular estadísticas totales
	var total_stats = get_equipped_stats()
	
	# Crear labels de estadísticas
	var stats_data = [
		{"name": "⚔️ Ataque", "value": total_stats.get("attack", 0)},
		{"name": "🛡️ Defensa", "value": total_stats.get("defense", 0)},
		{"name": "❤️ Salud Extra", "value": total_stats.get("health", 0)}
	]
	
	for stat in stats_data:
		var stat_container = HBoxContainer.new()
		
		var stat_name = Label.new()
		stat_name.text = stat.name
		stat_name.add_theme_font_size_override("font_size", 12)
		stat_name.add_theme_color_override("font_color", colors.text_secondary)
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_container.add_child(stat_name)
		
		var stat_value = Label.new()
		stat_value.text = str(stat.value)
		stat_value.add_theme_font_size_override("font_size", 12)
		stat_value.add_theme_color_override("font_color", colors.accent)
		stat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_container.add_child(stat_value)
		
		stats_container.add_child(stat_container)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return colors.rarity_common
		"uncommon":
			return colors.rarity_uncommon
		"rare":
			return colors.rarity_rare
		"epic":
			return colors.rarity_epic
		"legendary":
			return colors.rarity_legendary
		_:
			return colors.rarity_common

func animate_slot_selection(slot: Panel):
	var tween = create_tween()
	var original_scale = slot.scale
	tween.tween_property(slot, "scale", original_scale * 1.1, 0.1)
	tween.tween_property(slot, "scale", original_scale, 0.1)

func show_item_info(item):
	var info_panel = inventory_ui.get_node_or_null("MainPanel/MainContainer/InfoPanel")
	if not info_panel:
		return
	
	var item_name = info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemName")
	var item_type = info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemType")
	var item_description = info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemDescription")
	var item_stats = info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemStats")
	var buttons_container = info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ButtonsContainer")
	
	if item_name:
		item_name.text = item.name
		item_name.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "common")))
	
	if item_type:
		var rarity_text = item.get("rarity", "common").capitalize()
		item_type.text = rarity_text + " " + item.type.capitalize()
	
	if item_description:
		item_description.text = item.description
	
	var stats_text = ""
	if item.has("stats"):
		for stat in item.stats:
			var stat_name = stat.capitalize()
			var stat_value = item.stats[stat]
			var prefix = "+" if stat_value > 0 else ""
			stats_text += stat_name + ": " + prefix + str(stat_value) + "\n"
	
	if item_stats:
		item_stats.text = stats_text.strip_edges()
	
	# Mostrar/ocultar botones según el tipo de objeto
	if buttons_container:
		var equip_button = buttons_container.get_node_or_null("EquipButton")
		var unequip_button = buttons_container.get_node_or_null("UnequipButton")
		var use_button = buttons_container.get_node_or_null("UseButton")
		
		if equip_button:
			equip_button.visible = item.has("equip_slot") and selected_inventory_slot >= 0
		
		if unequip_button:
			unequip_button.visible = selected_equip_slot >= 0
		
		if use_button:
			use_button.visible = item.type == "consumable" and selected_inventory_slot >= 0
	
	# Animar la aparición del panel
	info_panel.show()
	var tween = create_tween()
	info_panel.modulate.a = 0
	tween.tween_property(info_panel, "modulate:a", 1.0, 0.2)

func hide_item_info():
	var info_panel = inventory_ui.get_node_or_null("MainPanel/MainContainer/InfoPanel")
	if info_panel:
		var tween = create_tween()
		tween.tween_property(info_panel, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func(): info_panel.hide())

func _on_inventory_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var inventory_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/InventoryPanel/MarginContainer/VBoxContainer/InventoryGrid")
		if inventory_container and slot_index < inventory_container.get_child_count():
			var slot = inventory_container.get_child(slot_index)
			animate_slot_selection(slot)
			on_inventory_slot_clicked(slot_index)

func _on_equipment_slot_input(event: InputEvent, equip_type: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var equipment_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/EquipmentPanel/MarginContainer/VBoxContainer/EquipmentSlots")
		if equipment_container:
			for child in equipment_container.get_children():
				if child.get_meta("equip_type") == equip_type:
					animate_slot_selection(child)
					break
			on_equipment_slot_clicked(equip_type)

func on_inventory_slot_clicked(slot_index):
	selected_inventory_slot = slot_index
	selected_equip_slot = -1
	
	if slot_index < inventory_items.size():
		var item = inventory_items[slot_index]
		show_item_info(item)
	else:
		hide_item_info()

func on_equipment_slot_clicked(slot_type):
	selected_inventory_slot = -1
	selected_equip_slot = slot_type
	
	if equipped_items[slot_type] != null:
		var item = equipped_items[slot_type]
		show_item_info(item)
	else:
		hide_item_info()

func update_inventory_display():
	if not inventory_ui or not is_instance_valid(inventory_ui):
		return
	
	var inventory_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/InventoryPanel/MarginContainer/VBoxContainer/InventoryGrid")
	var equipment_container = inventory_ui.get_node_or_null("MainPanel/MainContainer/EquipmentPanel/MarginContainer/VBoxContainer/EquipmentSlots")
	
	if not inventory_container or not equipment_container:
		return
	
	# Actualizar ranuras de inventario
	for i in range(inventory_container.get_child_count()):
		var slot = inventory_container.get_child(i)
		var item_icon = slot.get_node_or_null("ItemIcon")
		var quantity_label = slot.get_node_or_null("QuantityLabel")
		var rarity_border = slot.get_node_or_null("RarityBorder")
		
		if i < inventory_items.size():
			var item = inventory_items[i]
			set_enhanced_slot_item(slot, item_icon, quantity_label, rarity_border, item)
		else:
			clear_enhanced_slot_item(slot, item_icon, quantity_label, rarity_border)
	
	# Actualizar ranuras de equipamiento
	for child in equipment_container.get_children():
		var equip_type = child.get_meta("equip_type")
		var item_icon = child.get_node_or_null("HBoxContainer/ItemIcon")
		var item_name = child.get_node_or_null("HBoxContainer/VBoxContainer/ItemName")
		
		if equipped_items[equip_type] != null:
			var item = equipped_items[equip_type]
			set_enhanced_equipment_slot_item(child, item_icon, item_name, item)
		else:
			clear_enhanced_equipment_slot_item(child, item_icon, item_name)

func set_enhanced_slot_item(slot: Panel, item_icon: TextureRect, quantity_label: Label, rarity_border: Panel, item):
	if not item_icon:
		return
	
	# Crear textura por defecto con color según el tipo
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var item_color = Color(0.5, 0.5, 0.5, 1)
	
	match item.type:
		"weapon":
			item_color = Color(0.8, 0.6, 0.4, 1)
		"armor":
			item_color = Color(0.6, 0.6, 0.8, 1)
		"shield":
			item_color = Color(0.7, 0.7, 0.5, 1)
		"consumable":
			item_color = Color(0.8, 0.4, 0.4, 1)
	
	image.fill(item_color)
	item_icon.texture = ImageTexture.create_from_image(image)
	
	# Configurar borde de rareza
	if rarity_border:
		var rarity_color = get_rarity_color(item.get("rarity", "common"))
		var rarity_style = StyleBoxFlat.new()
		rarity_style.bg_color = Color.TRANSPARENT
		rarity_style.border_width_left = 3
		rarity_style.border_width_top = 3
		rarity_style.border_width_right = 3
		rarity_style.border_width_bottom = 3
		rarity_style.border_color = rarity_color
		rarity_style.corner_radius_top_left = 6
		rarity_style.corner_radius_top_right = 6
		rarity_style.corner_radius_bottom_left = 6
		rarity_style.corner_radius_bottom_right = 6
		rarity_border.add_theme_stylebox_override("panel", rarity_style)
		rarity_border.show()
	
	# Mostrar cantidad si es apilable
	if quantity_label and item.has("quantity") and item.quantity > 1:
		quantity_label.text = str(item.quantity)
		quantity_label.show()
	elif quantity_label:
		quantity_label.hide()
	
	# Cambiar color de fondo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_filled
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = colors.border
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	slot.set_meta("item_data", item)

func clear_enhanced_slot_item(slot: Panel, item_icon: TextureRect, quantity_label: Label, rarity_border: Panel):
	if item_icon:
		item_icon.texture = null
	if quantity_label:
		quantity_label.hide()
	if rarity_border:
		rarity_border.hide()
	
	# Restaurar color de fondo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_empty
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = colors.border
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	slot.set_meta("item_data", null)

func set_enhanced_equipment_slot_item(slot: Panel, item_icon: TextureRect, item_name: Label, item):
	if item_icon:
		# Crear textura por defecto
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var item_color = Color(0.5, 0.5, 0.5, 1)
		
		match item.type:
			"weapon":
				item_color = Color(0.8, 0.6, 0.4, 1)
			"armor":
				item_color = Color(0.6, 0.6, 0.8, 1)
			"shield":
				item_color = Color(0.7, 0.7, 0.5, 1)
		
		image.fill(item_color)
		item_icon.texture = ImageTexture.create_from_image(image)
	
	if item_name:
		item_name.text = item.name
		item_name.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "common")))
	
	# Cambiar color de fondo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_filled
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = get_rarity_color(item.get("rarity", "common"))
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	slot.set_meta("item_data", item)

func clear_enhanced_equipment_slot_item(slot: Panel, item_icon: TextureRect, item_name: Label):
	if item_icon:
		item_icon.texture = null
	if item_name:
		item_name.text = "Vacío"
		item_name.add_theme_color_override("font_color", colors.text_secondary)
	
	# Restaurar color de fondo del slot
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = colors.slot_empty
	slot_style.border_width_left = 2
	slot_style.border_width_top = 2
	slot_style.border_width_right = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = colors.border
	slot_style.corner_radius_top_left = 6
	slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6
	slot_style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", slot_style)
	
	slot.set_meta("item_data", null)

# Funciones de botones
func _on_equip_button_pressed():
	if selected_inventory_slot >= 0 and selected_inventory_slot < inventory_items.size():
		equip_item(selected_inventory_slot)
		update_inventory_display()
		update_player_stats()

func _on_unequip_button_pressed():
	if selected_equip_slot >= 0:
		unequip_item(selected_equip_slot)
		update_inventory_display()
		update_player_stats()

func _on_use_button_pressed():
	if selected_inventory_slot >= 0 and selected_inventory_slot < inventory_items.size():
		use_item(selected_inventory_slot)
		update_inventory_display()
		update_player_stats()

func _on_close_button_pressed():
	toggle_inventory()

func _on_close_info_button_pressed():
	hide_item_info()

func _input(event):
	# Manejar arrastre global
	if is_dragging and event is InputEventMouseMotion:
		var main_panel = inventory_ui.get_node_or_null("MainPanel")
		if main_panel:
			var new_position = event.global_position - drag_offset
			main_panel.global_position = new_position
	
	# Teclas de acceso
	if event.is_action_pressed("inventory") or (event is InputEventKey and event.pressed and event.keycode == KEY_I):
		toggle_inventory()

func reset_window_position():
	var main_panel = inventory_ui.get_node_or_null("MainPanel")
	if main_panel:
		var viewport_size = get_viewport().get_visible_rect().size
		var center_position = Vector2(
			(viewport_size.x - main_panel.size.x) / 2,
			(viewport_size.y - main_panel.size.y) / 2
		)
		
		var tween = create_tween()
		tween.tween_property(main_panel, "global_position", center_position, 0.3)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
