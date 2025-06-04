extends Node

signal shop_opened
signal shop_closed
signal item_purchased(item_id: String, quantity: int, total_cost: int)
signal item_sold(item_id: String, quantity: int, total_earned: int)

var is_shop_open: bool = false
var shop_ui: Control = null
var current_shop_data: Dictionary = {}

# Referencias a nodos de UI
var shop_title_label: Label = null
var player_gold_label: Label = null
var shop_grid: GridContainer = null
var player_inventory_grid: GridContainer = null
var item_info_panel: Panel = null
var selected_shop_item: Dictionary = {}
var selected_inventory_item: Dictionary = {}
var selected_shop_slot: int = -1
var selected_inventory_slot: int = -1

# Colores del tema (mismo que el inventario)
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
	"buy_button": Color(0.2, 0.6, 0.2, 1),
	"sell_button": Color(0.6, 0.4, 0.2, 1)
}

# Base de datos de tiendas
var shop_database = {
	"merchant_general": {
		"name": "Tienda General",
		"keeper": "Mercader",
		"items": [
			{"id": "sword", "price": 50, "stock": 3},
			{"id": "shield", "price": 30, "stock": 2},
			{"id": "helmet", "price": 40, "stock": 1},
			{"id": "potion", "price": 15, "stock": 10},
			{"id": "chest", "price": 80, "stock": 1}
		],
		"buy_rate": 1.0,  # Precio normal de compra
		"sell_rate": 0.6  # Vende al 60% del precio
	},
	"blacksmith": {
		"name": "Herrería",
		"keeper": "Herrero",
		"items": [
			{"id": "sword", "price": 45, "stock": 5},
			{"id": "shield", "price": 25, "stock": 4},
			{"id": "helmet", "price": 35, "stock": 3}
		],
		"buy_rate": 0.9,  # 10% descuento
		"sell_rate": 0.7  # Mejor precio de venta
	}
}

func _ready():
	print("🏪 ShopManager iniciado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_create_ui_deferred")

func _create_ui_deferred():
	await get_tree().process_frame
	create_shop_ui()

func create_shop_ui():
	print("🔨 Creando UI de tienda...")
	
	# Crear CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ShopUILayer"
	canvas_layer.layer = 180  # Entre diálogos e inventario
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Control principal
	shop_ui = Control.new()
	shop_ui.name = "ShopUI"
	shop_ui.anchors_preset = Control.PRESET_FULL_RECT
	shop_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.name = "Background"
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.color = Color(0, 0, 0, 0.7)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_ui.add_child(background)
	
	# Panel principal de la tienda
	var main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.size = Vector2(1000, 700)
	
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
	
	# Título de la tienda
	var title_container = HBoxContainer.new()
	title_container.name = "TitleContainer"
	title_container.anchors_preset = Control.PRESET_TOP_WIDE
	title_container.offset_top = 15
	title_container.offset_bottom = 55
	title_container.offset_left = 20
	title_container.offset_right = -20
	
	shop_title_label = Label.new()
	shop_title_label.text = "🏪 TIENDA GENERAL"
	shop_title_label.add_theme_font_size_override("font_size", 24)
	shop_title_label.add_theme_color_override("font_color", colors.accent)
	shop_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(shop_title_label)
	
	# Oro del jugador
	player_gold_label = Label.new()
	player_gold_label.text = "💰 Oro: 100"
	player_gold_label.add_theme_font_size_override("font_size", 18)
	player_gold_label.add_theme_color_override("font_color", Color.GOLD)
	title_container.add_child(player_gold_label)
	
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
	
	# Contenedor principal
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.offset_top = 70
	main_container.offset_bottom = -20
	main_container.offset_left = 20
	main_container.offset_right = -20
	main_container.add_theme_constant_override("separation", 20)
	
	# Crear paneles
	create_shop_panel(main_container)
	create_player_inventory_panel(main_container)
	create_shop_info_panel(main_container)
	
	main_panel.add_child(main_container)
	shop_ui.add_child(main_panel)
	canvas_layer.add_child(shop_ui)
	
	# Añadir a la escena
	get_tree().root.call_deferred("add_child", canvas_layer)
	
	# Ocultar inicialmente
	shop_ui.hide()
	
	print("✅ UI de tienda creada")

func create_shop_panel(parent):
	var shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var shop_style = StyleBoxFlat.new()
	shop_style.bg_color = colors.panel
	shop_style.border_width_left = 2
	shop_style.border_width_top = 2
	shop_style.border_width_right = 2
	shop_style.border_width_bottom = 2
	shop_style.border_color = colors.border
	shop_style.corner_radius_top_left = 8
	shop_style.corner_radius_top_right = 8
	shop_style.corner_radius_bottom_left = 8
	shop_style.corner_radius_bottom_right = 8
	shop_panel.add_theme_stylebox_override("panel", shop_style)
	
	var shop_margin = MarginContainer.new()
	shop_margin.name = "MarginContainer"
	shop_margin.anchors_preset = Control.PRESET_FULL_RECT
	shop_margin.add_theme_constant_override("margin_left", 15)
	shop_margin.add_theme_constant_override("margin_top", 15)
	shop_margin.add_theme_constant_override("margin_right", 15)
	shop_margin.add_theme_constant_override("margin_bottom", 15)
	
	var shop_vbox = VBoxContainer.new()
	shop_vbox.name = "VBoxContainer"
	shop_vbox.add_theme_constant_override("separation", 15)
	
	# Título de la sección
	var shop_title = Label.new()
	shop_title.text = "🛒 PRODUCTOS EN VENTA"
	shop_title.add_theme_font_size_override("font_size", 16)
	shop_title.add_theme_color_override("font_color", colors.accent)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_vbox.add_child(shop_title)
	
	# Grid de productos
	shop_grid = GridContainer.new()
	shop_grid.name = "ShopGrid"
	shop_grid.columns = 4
	shop_grid.add_theme_constant_override("h_separation", 8)
	shop_grid.add_theme_constant_override("v_separation", 8)
	shop_vbox.add_child(shop_grid)
	
	shop_margin.add_child(shop_vbox)
	shop_panel.add_child(shop_margin)
	parent.add_child(shop_panel)

func create_player_inventory_panel(parent):
	var inventory_panel = Panel.new()
	inventory_panel.name = "PlayerInventoryPanel"
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
	
	# Título de la sección
	var inventory_title = Label.new()
	inventory_title.text = "🎒 TU INVENTARIO"
	inventory_title.add_theme_font_size_override("font_size", 16)
	inventory_title.add_theme_color_override("font_color", colors.accent)
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_vbox.add_child(inventory_title)
	
	# Grid del inventario del jugador
	player_inventory_grid = GridContainer.new()
	player_inventory_grid.name = "PlayerInventoryGrid"
	player_inventory_grid.columns = 4
	player_inventory_grid.add_theme_constant_override("h_separation", 8)
	player_inventory_grid.add_theme_constant_override("v_separation", 8)
	inventory_vbox.add_child(player_inventory_grid)
	
	inventory_margin.add_child(inventory_vbox)
	inventory_panel.add_child(inventory_margin)
	parent.add_child(inventory_panel)

func create_shop_info_panel(parent):
	item_info_panel = Panel.new()
	item_info_panel.name = "InfoPanel"
	item_info_panel.custom_minimum_size = Vector2(300, 0)
	item_info_panel.hide()
	
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
	item_info_panel.add_theme_stylebox_override("panel", info_style)
	
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
	
	# Header
	var header_title = Label.new()
	header_title.text = "📋 INFORMACIÓN"
	header_title.add_theme_font_size_override("font_size", 14)
	header_title.add_theme_color_override("font_color", colors.accent)
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(header_title)
	
	# Separador
	var header_separator = HSeparator.new()
	header_separator.add_theme_color_override("separator", colors.border)
	main_vbox.add_child(header_separator)
	
	# Contenido
	var content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.add_theme_constant_override("separation", 15)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Nombre del objeto
	var item_name = Label.new()
	item_name.name = "ItemName"
	item_name.add_theme_font_size_override("font_size", 18)
	item_name.add_theme_color_override("font_color", colors.accent)
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_container.add_child(item_name)
	
	# Precio
	var item_price = Label.new()
	item_price.name = "ItemPrice"
	item_price.add_theme_font_size_override("font_size", 16)
	item_price.add_theme_color_override("font_color", Color.GOLD)
	item_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(item_price)
	
	# Stock
	var item_stock = Label.new()
	item_stock.name = "ItemStock"
	item_stock.add_theme_font_size_override("font_size", 14)
	item_stock.add_theme_color_override("font_color", colors.text_secondary)
	item_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(item_stock)
	
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
	buttons_label.text = "💰 COMERCIO"
	buttons_label.add_theme_font_size_override("font_size", 14)
	buttons_label.add_theme_color_override("font_color", colors.accent)
	buttons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(buttons_label)
	
	var buttons_container = VBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.add_theme_constant_override("separation", 8)
	
	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "💰 COMPRAR"
	buy_button.add_theme_font_size_override("font_size", 14)
	buy_button.pressed.connect(_on_buy_button_pressed)
	style_action_button(buy_button, colors.buy_button)
	buttons_container.add_child(buy_button)
	
	var sell_button = Button.new()
	sell_button.name = "SellButton"
	sell_button.text = "💸 VENDER"
	sell_button.add_theme_font_size_override("font_size", 14)
	sell_button.pressed.connect(_on_sell_button_pressed)
	style_action_button(sell_button, colors.sell_button)
	buttons_container.add_child(sell_button)
	
	content_container.add_child(buttons_container)
	main_vbox.add_child(content_container)
	main_container.add_child(main_vbox)
	item_info_panel.add_child(main_container)
	parent.add_child(item_info_panel)

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

func open_shop(shop_id: String):
	if is_shop_open:
		print("⚠️ Ya hay una tienda abierta")
		return
	
	if not shop_database.has(shop_id):
		print("❌ Tienda no encontrada: ", shop_id)
		return
	
	if not shop_ui or not is_instance_valid(shop_ui):
		print("❌ No hay UI de tienda disponible")
		return
	
	current_shop_data = shop_database[shop_id]
	is_shop_open = true
	
	# Configurar título
	if shop_title_label:
		shop_title_label.text = "🏪 " + current_shop_data.name.to_upper()
	
	# Actualizar oro del jugador
	update_player_gold_display()
	
	# Mostrar UI
	shop_ui.show()
	
	# Centrar la ventana
	var main_panel = shop_ui.get_node("MainPanel")
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = main_panel.size
	
	var centered_position = Vector2(
		(viewport_size.x - panel_size.x) / 2,
		(viewport_size.y - panel_size.y) / 2
	)
	
	main_panel.position = centered_position
	
	# Animación de entrada
	main_panel.scale = Vector2(0.8, 0.8)
	main_panel.modulate.a = 0
	
	var tween = create_tween()
	tween.parallel().tween_property(main_panel, "scale", Vector2(1, 1), 0.3)
	tween.parallel().tween_property(main_panel, "modulate:a", 1.0, 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Cargar productos y inventario
	populate_shop_items()
	populate_player_inventory()
	
	# Pausar el juego
	get_tree().paused = true
	
	shop_opened.emit()
	print("🏪 Tienda abierta: ", current_shop_data.name)

func populate_shop_items():
	if not shop_grid:
		return
	
	# Limpiar grid anterior
	for child in shop_grid.get_children():
		child.queue_free()
	
	# Obtener base de datos de items del InventoryManager
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if not inventory_manager:
		print("❌ InventoryManager no encontrado")
		return
	
	var item_database = inventory_manager.item_database
	
	# Crear slots para cada producto
	for i in range(current_shop_data.items.size()):
		var shop_item = current_shop_data.items[i]
		var item_data = item_database.get(shop_item.id, {})
		
		if item_data.is_empty():
			continue
		
		var slot = create_shop_item_slot(i, item_data, shop_item)
		shop_grid.add_child(slot)

func create_shop_item_slot(index: int, item_data: Dictionary, shop_item: Dictionary) -> Panel:
	var slot = Panel.new()
	slot.name = "ShopSlot_" + str(index)
	slot.custom_minimum_size = Vector2(80, 100)
	slot.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Estilo del slot
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
	
	# Contenedor vertical
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("margin_left", 5)
	vbox.add_theme_constant_override("margin_top", 5)
	vbox.add_theme_constant_override("margin_right", 5)
	vbox.add_theme_constant_override("margin_bottom", 5)
	
	# Icono del objeto
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.custom_minimum_size = Vector2(60, 60)
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Crear icono de respaldo
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var item_color = get_item_color(item_data.get("type", ""))
	image.fill(item_color)
	item_icon.texture = ImageTexture.create_from_image(image)
	
	vbox.add_child(item_icon)
	
	# Precio
	var price_label = Label.new()
	price_label.text = str(shop_item.price) + "💰"
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color.GOLD)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)
	
	# Stock
	var stock_label = Label.new()
	stock_label.text = "Stock: " + str(shop_item.stock)
	stock_label.add_theme_font_size_override("font_size", 10)
	stock_label.add_theme_color_override("font_color", colors.text_secondary)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stock_label)
	
	slot.add_child(vbox)
	
	# Conectar señal de clic
	slot.gui_input.connect(_on_shop_slot_input.bind(index))
	
	# Añadir metadatos
	slot.set_meta("shop_index", index)
	slot.set_meta("item_data", item_data)
	slot.set_meta("shop_item", shop_item)
	
	return slot

func get_item_color(item_type: String) -> Color:
	match item_type:
		"weapon":
			return Color(0.8, 0.6, 0.4, 1)
		"armor":
			return Color(0.6, 0.6, 0.8, 1)
		"shield":
			return Color(0.7, 0.7, 0.5, 1)
		"consumable":
			return Color(0.8, 0.4, 0.4, 1)
		_:
			return Color(0.5, 0.5, 0.5, 1)

func populate_player_inventory():
	if not player_inventory_grid:
		return
	
	# Limpiar grid anterior
	for child in player_inventory_grid.get_children():
		child.queue_free()
	
	# Obtener inventario del jugador
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if not inventory_manager:
		return
	
	var player_items = inventory_manager.inventory_items
	
	# Crear slots para cada item del jugador
	for i in range(player_items.size()):
		var item_data = player_items[i]
		var slot = create_player_inventory_slot(i, item_data)
		player_inventory_grid.add_child(slot)

func create_player_inventory_slot(index: int, item_data: Dictionary) -> Panel:
	var slot = Panel.new()
	slot.name = "PlayerSlot_" + str(index)
	slot.custom_minimum_size = Vector2(70, 70)
	slot.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Estilo del slot
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
	
	# Icono del objeto
	var item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.anchors_preset = Control.PRESET_FULL_RECT
	item_icon.offset_left = 6
	item_icon.offset_top = 6
	item_icon.offset_right = -6
	item_icon.offset_bottom = -6
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Crear icono de respaldo
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var item_color = get_item_color(item_data.get("type", ""))
	image.fill(item_color)
	item_icon.texture = ImageTexture.create_from_image(image)
	
	slot.add_child(item_icon)
	
	# Etiqueta de cantidad si es apilable
	if item_data.has("quantity") and item_data.quantity > 1:
		var quantity_label = Label.new()
		quantity_label.name = "QuantityLabel"
		quantity_label.text = str(item_data.quantity)
		quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		quantity_label.offset_right = -4
		quantity_label.offset_bottom = -4
		quantity_label.add_theme_font_size_override("font_size", 12)
		quantity_label.add_theme_color_override("font_color", Color.WHITE)
		quantity_label.add_theme_constant_override("outline_size", 1)
		quantity_label.add_theme_color_override("font_outline_color", Color.BLACK)
		slot.add_child(quantity_label)
	
	# Conectar señal de clic
	slot.gui_input.connect(_on_player_inventory_slot_input.bind(index))
	
	# Añadir metadatos
	slot.set_meta("inventory_index", index)
	slot.set_meta("item_data", item_data)
	
	return slot

func _on_shop_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_shop_item(slot_index)

func _on_player_inventory_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_player_inventory_item(slot_index)

func select_shop_item(slot_index: int):
	selected_shop_slot = slot_index
	selected_inventory_slot = -1
	
	if slot_index < current_shop_data.items.size():
		var shop_item = current_shop_data.items[slot_index]
		var inventory_manager = get_node_or_null("/root/InventoryManager")
		if inventory_manager:
			var item_data = inventory_manager.item_database.get(shop_item.id, {})
			selected_shop_item = item_data
			show_item_info(item_data, shop_item, true)

func select_player_inventory_item(slot_index: int):
	selected_inventory_slot = slot_index
	selected_shop_slot = -1
	
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager and slot_index < inventory_manager.inventory_items.size():
		var item_data = inventory_manager.inventory_items[slot_index]
		selected_inventory_item = item_data
		show_item_info(item_data, {}, false)

func show_item_info(item_data: Dictionary, shop_item: Dictionary = {}, is_shop_item: bool = false):
	if not item_info_panel:
		return
	
	var item_name = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemName")
	var item_price = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemPrice")
	var item_stock = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemStock")
	var item_description = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemDescription")
	var item_stats = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ItemStats")
	var buttons_container = item_info_panel.get_node_or_null("MainContainer/MainVBox/ContentContainer/ButtonsContainer")
	
	if item_name:
		item_name.text = item_data.get("name", "Objeto desconocido")
	
	if item_price:
		if is_shop_item:
			item_price.text = "💰 Precio: " + str(shop_item.get("price", 0)) + " oro"
		else:
			var sell_price = calculate_sell_price(item_data)
			item_price.text = "💸 Venta: " + str(sell_price) + " oro"
	
	if item_stock and is_shop_item:
		item_stock.text = "📦 Stock: " + str(shop_item.get("stock", 0))
		item_stock.show()
	elif item_stock:
		item_stock.hide()
	
	if item_description:
		item_description.text = item_data.get("description", "Sin descripción disponible.")
	
	if item_stats:
		var stats_text = ""
		if item_data.has("stats"):
			for stat in item_data.stats:
				var stat_name = stat.capitalize()
				var stat_value = item_data.stats[stat]
				var prefix = "+" if stat_value > 0 else ""
				stats_text += stat_name + ": " + prefix + str(stat_value) + "\n"
		item_stats.text = stats_text.strip_edges()
	
	# Mostrar/ocultar botones
	if buttons_container:
		var buy_button = buttons_container.get_node_or_null("BuyButton")
		var sell_button = buttons_container.get_node_or_null("SellButton")
		
		if buy_button:
			buy_button.visible = is_shop_item and shop_item.get("stock", 0) > 0
		
		if sell_button:
			sell_button.visible = not is_shop_item
	
	# Mostrar panel
	item_info_panel.show()
	var tween = create_tween()
	item_info_panel.modulate.a = 0
	tween.tween_property(item_info_panel, "modulate:a", 1.0, 0.2)

func calculate_sell_price(item_data: Dictionary) -> int:
	# Calcular precio de venta basado en el tipo de objeto y la tienda
	var base_price = 10  # Precio base por defecto
	
	# Aquí podrías tener una lógica más compleja para calcular precios
	match item_data.get("type", ""):
		"weapon":
			base_price = 30
		"armor":
			base_price = 25
		"shield":
			base_price = 20
		"consumable":
			base_price = 5
	
	return int(base_price * current_shop_data.get("sell_rate", 0.6))

func _on_buy_button_pressed():
	if selected_shop_slot >= 0 and selected_shop_slot < current_shop_data.items.size():
		buy_item(selected_shop_slot)

func _on_sell_button_pressed():
	if selected_inventory_slot >= 0:
		sell_item(selected_inventory_slot)

func buy_item(shop_slot_index: int):
	var shop_item = current_shop_data.items[shop_slot_index]
	var price = shop_item.price
	
	# Verificar si el jugador tiene suficiente oro
	var player_gold = get_player_gold()
	if player_gold < price:
		print("❌ No tienes suficiente oro")
		return
	
	# Verificar stock
	if shop_item.stock <= 0:
		print("❌ No hay stock disponible")
		return
	
	# Realizar compra
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager:
		var item_data = inventory_manager.item_database.get(shop_item.id, {})
		if inventory_manager.add_item(shop_item.id, 1):
			# Reducir oro del jugador
			subtract_player_gold(price)
			
			# Reducir stock
			shop_item.stock -= 1
			
			# Actualizar UI
			update_player_gold_display()
			populate_shop_items()
			populate_player_inventory()
			
			item_purchased.emit(shop_item.id, 1, price)
			print("✅ Comprado:", item_data.get("name", ""), "por", price, "oro")
		else:
			print("❌ Inventario lleno")

func sell_item(inventory_slot_index: int):
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if not inventory_manager or inventory_slot_index >= inventory_manager.inventory_items.size():
		return
	
	var item_data = inventory_manager.inventory_items[inventory_slot_index]
	var sell_price = calculate_sell_price(item_data)
	
	# Realizar venta
	if inventory_manager.remove_item(inventory_slot_index, 1):
		# Añadir oro al jugador
		add_player_gold(sell_price)
		
		# Actualizar UI
		update_player_gold_display()
		populate_player_inventory()
		
		item_sold.emit(item_data.get("id", ""), 1, sell_price)
		print("✅ Vendido:", item_data.get("name", ""), "por", sell_price, "oro")

func get_player_gold() -> int:
	# Aquí deberías obtener el oro del jugador desde tu sistema de datos
	# Por ahora, usamos un valor fijo
	return 100

func add_player_gold(amount: int):
	# Aquí añadirías oro al jugador
	print("💰 +", amount, " oro")

func subtract_player_gold(amount: int):
	# Aquí restarías oro al jugador
	print("💸 -", amount, " oro")

func update_player_gold_display():
	if player_gold_label:
		player_gold_label.text = "💰 Oro: " + str(get_player_gold())

func close_shop():
	if not is_shop_open:
		return
	
	is_shop_open = false
	selected_shop_item = {}
	selected_inventory_item = {}
	selected_shop_slot = -1
	selected_inventory_slot = -1
	
	# Animación de salida
	if shop_ui and is_instance_valid(shop_ui):
		var main_panel = shop_ui.get_node("MainPanel")
		var tween = create_tween()
		tween.parallel().tween_property(main_panel, "scale", Vector2(0.8, 0.8), 0.2)
		tween.parallel().tween_property(main_panel, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): shop_ui.hide())
	
	# Reanudar el juego
	get_tree().paused = false
	
	shop_closed.emit()
	print("🔚 Tienda cerrada")

func _on_close_button_pressed():
	close_shop()

func _input(event):
	if is_shop_open and event.is_action_pressed("ui_cancel"):
		close_shop()
