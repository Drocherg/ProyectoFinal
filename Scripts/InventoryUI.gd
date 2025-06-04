extends Control

# Referencias a nodos
@onready var inventory_container = $InventoryPanel/MarginContainer/HBoxContainer/InventoryContainer/GridContainer
@onready var equipment_container = $InventoryPanel/MarginContainer/HBoxContainer/EquipmentContainer/VBoxContainer
@onready var item_info_panel = $InventoryPanel/MarginContainer/HBoxContainer/ItemInfoPanel
@onready var item_name_label = $InventoryPanel/MarginContainer/HBoxContainer/ItemInfoPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label = $InventoryPanel/MarginContainer/HBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescriptionLabel
@onready var item_stats_label = $InventoryPanel/MarginContainer/HBoxContainer/ItemInfoPanel/VBoxContainer/ItemStatsLabel

# Referencias a escenas - usando rutas directas para evitar errores
var inventory_slot_scene = null
var equipment_slot_scene = null

# Referencia al gestor de inventario
var inventory_manager = null

# Estado
var selected_inventory_slot = -1
var selected_equip_slot = -1
var dragging_item = null
var drag_start_position = Vector2.ZERO

# Variables para arrastrar la ventana
var is_dragging = false
var drag_offset = Vector2.ZERO
var draggable_areas = []
var drag_border_width = 15  # Ancho del borde arrastrable

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

func _ready():
	print("🎮 InventoryUI iniciado")
	
	# Cargar escenas de slots
	load_slot_scenes()
	
	# Ocultar panel de información inicialmente
	if item_info_panel:
		item_info_panel.hide()
	
	# Configurar el panel principal para que esté centrado
	setup_main_panel()

func setup_main_panel():
	# Asegurar que el panel principal esté centrado
	var main_panel = get_node_or_null("InventoryPanel")
	if main_panel:
		main_panel.set_anchors_preset(Control.PRESET_CENTER)
		main_panel.size = Vector2(900, 650)
		main_panel.position = Vector2(-450, -325)
		
		# Aplicar estilo mejorado
		var style = StyleBoxFlat.new()
		style.bg_color = colors.background
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = colors.accent
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 8
		main_panel.add_theme_stylebox_override("panel", style)
		
		# Crear áreas arrastrables en todos los bordes
		create_draggable_borders(main_panel)

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
	
	# Crear indicador visual en el centro
	create_drag_indicator(main_panel)

func create_drag_indicator(main_panel: Panel):
	# Crear indicador visual sutil
	var drag_indicator = Label.new()
	drag_indicator.name = "DragIndicator"
	drag_indicator.text = "🔄 Arrastra desde cualquier borde para mover"
	drag_indicator.add_theme_font_size_override("font_size", 10)
	drag_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.3))
	drag_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	drag_indicator.offset_top = 40
	drag_indicator.offset_bottom = 55
	drag_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	main_panel.add_child(drag_indicator)

func _on_drag_area_mouse_entered():
	# Cambiar cursor cuando se entra en cualquier área arrastrable
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func _on_drag_area_mouse_exited():
	# Restaurar cursor normal solo si no estamos arrastrando
	if not is_dragging:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_drag_area_input(event: InputEvent):
	var main_panel = get_node_or_null("InventoryPanel")
	if not main_panel:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Iniciar arrastre
				is_dragging = true
				drag_offset = event.global_position - main_panel.global_position
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
				
				# Efecto visual de que se está arrastrando
				var tween = create_tween()
				tween.tween_property(main_panel, "scale", Vector2(1.02, 1.02), 0.1)
				
				# Resaltar bordes durante el arrastre
				highlight_draggable_borders(true)
				
			else:
				# Terminar arrastre
				is_dragging = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				
				# Restaurar escala normal
				var tween = create_tween()
				tween.tween_property(main_panel, "scale", Vector2(1.0, 1.0), 0.1)
				
				# Quitar resaltado de bordes
				highlight_draggable_borders(false)
				
				# Asegurar que la ventana esté dentro de los límites de la pantalla
				clamp_window_to_screen(main_panel)
	
	elif event is InputEventMouseMotion and is_dragging:
		# Mover la ventana
		var new_position = event.global_position - drag_offset
		main_panel.global_position = new_position

func highlight_draggable_borders(highlight: bool):
	# Crear efecto visual en los bordes durante el arrastre
	var main_panel = get_node_or_null("InventoryPanel")
	if not main_panel:
		return
	
	if highlight:
		# Añadir un brillo sutil a los bordes
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
		
		# Animación de pulso
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(border_highlight, "modulate:a", 0.3, 0.5)
		tween.tween_property(border_highlight, "modulate:a", 0.8, 0.5)
	else:
		# Quitar resaltado
		var border_highlight = main_panel.get_node_or_null("BorderHighlight")
		if border_highlight:
			border_highlight.queue_free()

func clamp_window_to_screen(main_panel: Panel):
	# Obtener límites de la pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = main_panel.size
	
	# Calcular límites (permitir que se salga parcialmente)
	var min_x = -panel_size.x + 100  # Permitir que se salga un poco pero no completamente
	var max_x = viewport_size.x - 100
	var min_y = 0  # No permitir que se salga por arriba
	var max_y = viewport_size.y - 100
	
	# Aplicar límites
	var clamped_position = Vector2(
		clamp(main_panel.global_position.x, min_x, max_x),
		clamp(main_panel.global_position.y, min_y, max_y)
	)
	
	# Animar hacia la posición válida si es necesario
	if main_panel.global_position != clamped_position:
		var tween = create_tween()
		tween.tween_property(main_panel, "global_position", clamped_position, 0.2)
		tween.set_ease(Tween.EASE_OUT)

func load_slot_scenes():
	# Intentar cargar las escenas de slots
	if ResourceLoader.exists("res://Escenas/UI/InventorySlot.tscn"):
		inventory_slot_scene = load("res://Escenas/UI/InventorySlot.tscn")
		print("✅ InventorySlot.tscn cargado")
	else:
		print("⚠️ No se encontró InventorySlot.tscn - usando creación programática")
	
	if ResourceLoader.exists("res://Escenas/UI/EquipmentSlot.tscn"):
		equipment_slot_scene = load("res://Escenas/UI/EquipmentSlot.tscn")
		print("✅ EquipmentSlot.tscn cargado")
	else:
		print("⚠️ No se encontró EquipmentSlot.tscn - usando creación programática")

func setup(manager):
	inventory_manager = manager
	
	if not inventory_container or not equipment_container:
		print("❌ No se encontraron los contenedores de UI")
		return
	
	# Crear ranuras de inventario
	create_inventory_slots()
	
	# Crear ranuras de equipamiento
	create_equipment_slots()
	
	# Actualizar visualización
	update_inventory_display()
	
	print("✅ InventoryUI configurado correctamente con arrastre desde todos los bordes")

func create_inventory_slots():
	if not inventory_slot_scene:
		print("🔨 Creando slots de inventario programáticamente...")
		create_inventory_slots_programmatically()
		return
	
	print("🔨 Creando slots de inventario desde escenas...")
	for i in range(inventory_manager.MAX_INVENTORY_SLOTS):
		var slot = inventory_slot_scene.instantiate()
		inventory_container.add_child(slot)
		if slot.has_method("setup"):
			slot.setup(i, self)

func create_equipment_slots():
	if not equipment_slot_scene:
		print("🔨 Creando slots de equipamiento programáticamente...")
		create_equipment_slots_programmatically()
		return
	
	print("🔨 Creando slots de equipamiento desde escenas...")
	for slot_type in inventory_manager.EquipSlot:
		var slot = equipment_slot_scene.instantiate()
		equipment_container.add_child(slot)
		if slot.has_method("setup"):
			slot.setup(inventory_manager.EquipSlot[slot_type], self, slot_type)

func create_inventory_slots_programmatically():
	for i in range(inventory_manager.MAX_INVENTORY_SLOTS):
		var slot = create_inventory_slot_node(i)
		inventory_container.add_child(slot)

func create_equipment_slots_programmatically():
	var equipment_slots_data = [
		{"type": inventory_manager.EquipSlot.HEAD, "name": "HEAD", "icon": "🪖", "label": "Cabeza"},
		{"type": inventory_manager.EquipSlot.BODY, "name": "BODY", "icon": "🛡️", "label": "Pecho"},
		{"type": inventory_manager.EquipSlot.LEGS, "name": "LEGS", "icon": "👖", "label": "Piernas"},
		{"type": inventory_manager.EquipSlot.WEAPON, "name": "WEAPON", "icon": "⚔️", "label": "Arma"},
		{"type": inventory_manager.EquipSlot.SHIELD, "name": "SHIELD", "icon": "🛡️", "label": "Escudo"},
		{"type": inventory_manager.EquipSlot.ACCESSORY, "name": "ACCESSORY", "icon": "💍", "label": "Accesorio"}
	]
	
	for slot_data in equipment_slots_data:
		var slot = create_equipment_slot_node(slot_data.type, slot_data.name, slot_data.icon, slot_data.label)
		equipment_container.add_child(slot)

func create_inventory_slot_node(index: int) -> Panel:
	var slot = Panel.new()
	slot.name = "InventorySlot_" + str(index)
	slot.custom_minimum_size = Vector2(70, 70)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Estilo del panel mejorado
	var style = StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = colors.border
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.bg_color = colors.slot_empty
	slot.add_theme_stylebox_override("panel", style)
	
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
	quantity_label.text = ""
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

func create_equipment_slot_node(equip_type: int, slot_name: String, icon: String, label: String) -> Panel:
	var slot = Panel.new()
	slot.name = "EquipmentSlot_" + slot_name
	slot.custom_minimum_size = Vector2(180, 50)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Estilo del panel mejorado
	var style = StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = colors.border
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.bg_color = colors.slot_empty
	slot.add_theme_stylebox_override("panel", style)
	
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

func _on_inventory_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		animate_slot_selection(inventory_container.get_child(slot_index))
		on_inventory_slot_clicked(slot_index)

func _on_equipment_slot_input(event: InputEvent, equip_type: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Encontrar el slot correcto
		for child in equipment_container.get_children():
			if child.get_meta("equip_type") == equip_type:
				animate_slot_selection(child)
				break
		on_equipment_slot_clicked(equip_type)

func animate_slot_selection(slot: Panel):
	var tween = create_tween()
	var original_scale = slot.scale
	tween.tween_property(slot, "scale", original_scale * 1.1, 0.1)
	tween.tween_property(slot, "scale", original_scale, 0.1)

func update_inventory_display():
	if not inventory_manager:
		return
	
	# Actualizar ranuras de inventario
	for i in range(inventory_container.get_child_count()):
		var slot = inventory_container.get_child(i)
		var item_icon = slot.get_node_or_null("ItemIcon")
		var quantity_label = slot.get_node_or_null("QuantityLabel")
		var rarity_border = slot.get_node_or_null("RarityBorder")
		
		if i < inventory_manager.inventory_items.size():
			var item = inventory_manager.inventory_items[i]
			set_slot_item(slot, item_icon, quantity_label, rarity_border, item)
		else:
			clear_slot_item(slot, item_icon, quantity_label, rarity_border)
	
	# Actualizar ranuras de equipamiento
	for child in equipment_container.get_children():
		var equip_type = child.get_meta("equip_type")
		var item_icon = child.get_node_or_null("ItemIcon")
		var item_name = child.get_node_or_null("HBoxContainer/VBoxContainer/ItemName")
		
		if inventory_manager.equipped_items[equip_type] != null:
			var item = inventory_manager.equipped_items[equip_type]
			set_equipment_slot_item(child, item_icon, item_name, item)
		else:
			clear_equipment_slot_item(child, item_icon, item_name)

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

func set_slot_item(slot: Panel, item_icon: TextureRect, quantity_label: Label, rarity_border: Panel, item):
	if not item_icon:
		return
	
	# Cargar icono o crear textura por defecto
	if ResourceLoader.exists(item.icon):
		item_icon.texture = load(item.icon)
	else:
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

func clear_slot_item(slot: Panel, item_icon: TextureRect, quantity_label: Label, rarity_border: Panel):
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

func set_equipment_slot_item(slot: Panel, item_icon: TextureRect, item_name: Label, item):
	if item_icon:
		# Cargar icono o crear textura por defecto
		if ResourceLoader.exists(item.icon):
			item_icon.texture = load(item.icon)
		else:
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

func clear_equipment_slot_item(slot: Panel, item_icon: TextureRect, item_name: Label):
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

func on_inventory_slot_clicked(slot_index):
	selected_inventory_slot = slot_index
	selected_equip_slot = -1
	
	if slot_index < inventory_manager.inventory_items.size():
		var item = inventory_manager.inventory_items[slot_index]
		show_item_info(item)
	else:
		hide_item_info()

func on_equipment_slot_clicked(slot_type):
	selected_inventory_slot = -1
	selected_equip_slot = slot_type
	
	if inventory_manager.equipped_items[slot_type] != null:
		var item = inventory_manager.equipped_items[slot_type]
		show_item_info(item)
	else:
		hide_item_info()

func show_item_info(item):
	if not item_info_panel:
		return
	
	if item_name_label:
		item_name_label.text = item.name
		item_name_label.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "common")))
	
	if item_description_label:
		item_description_label.text = item.description
	
	var stats_text = ""
	if item.has("stats"):
		for stat in item.stats:
			var stat_name = stat.capitalize()
			var stat_value = item.stats[stat]
			var prefix = "+" if stat_value > 0 else ""
			stats_text += stat_name + ": " + prefix + str(stat_value) + "\n"
	
	if item_stats_label:
		item_stats_label.text = stats_text
	
	# Animar la aparición del panel
	item_info_panel.show()
	var tween = create_tween()
	item_info_panel.modulate.a = 0
	tween.tween_property(item_info_panel, "modulate:a", 1.0, 0.2)

func hide_item_info():
	if item_info_panel:
		var tween = create_tween()
		tween.tween_property(item_info_panel, "modulate:a", 0.0, 0.1)
		tween.tween_callback(func(): item_info_panel.hide())

func _on_equip_button_pressed():
	if selected_inventory_slot >= 0 and selected_inventory_slot < inventory_manager.inventory_items.size():
		inventory_manager.equip_item(selected_inventory_slot)
		update_inventory_display()

func _on_unequip_button_pressed():
	if selected_equip_slot >= 0:
		inventory_manager.unequip_item(selected_equip_slot)
		update_inventory_display()

func _on_use_button_pressed():
	if selected_inventory_slot >= 0 and selected_inventory_slot < inventory_manager.inventory_items.size():
		inventory_manager.use_item(selected_inventory_slot)
		update_inventory_display()

func _on_close_button_pressed():
	if inventory_manager:
		inventory_manager.toggle_inventory()

func _input(event):
	# Manejar arrastre global
	if is_dragging and event is InputEventMouseMotion:
		var main_panel = get_node_or_null("InventoryPanel")
		if main_panel:
			var new_position = event.global_position - drag_offset
			main_panel.global_position = new_position
	
	# Teclas de acceso
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			if inventory_manager:
				inventory_manager.toggle_inventory()

func reset_window_position():
	var main_panel = get_node_or_null("InventoryPanel")
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
