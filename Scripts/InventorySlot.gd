extends Panel

# Referencias
@onready var item_icon = $ItemIcon
@onready var slot_label = $SlotLabel

# Variables
var equip_type: int = -1
var inventory_ui = null
var item_data = null
var slot_name: String = ""

func setup(type: int, ui, slot_type_name: String):
	equip_type = type
	inventory_ui = ui
	slot_name = slot_type_name
	
	# Configurar etiqueta
	slot_label.text = slot_type_name.capitalize()
	
	# Ocultar icono inicialmente
	item_icon.texture = null

func set_item(item):
	item_data = item
	
	# Cargar icono desde res://Assets/Items/
	if item.has("icon") and item.icon != "":
		var icon_path = item.icon
		
		# Si la ruta no es absoluta, asumir que está en Assets/Items/
		if not icon_path.begins_with("res://"):
			icon_path = "res://Assets/Items/" + icon_path
		
		# Verificar si el archivo existe y cargarlo
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			if texture:
				item_icon.texture = texture
				print("✅ Icono cargado:", icon_path)
			else:
				print("❌ Error al cargar textura:", icon_path)
				create_fallback_icon()
		else:
			print("❌ Archivo no encontrado:", icon_path)
			create_fallback_icon()
	else:
		create_fallback_icon()

func create_fallback_icon():
	# Crear icono por defecto si no se puede cargar el asset
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = Color(0.5, 0.5, 0.5, 1)
	
	# Color según el tipo de item
	if item_data and item_data.has("type"):
		match item_data.type:
			"weapon":
				color = Color(0.8, 0.6, 0.4, 1)
			"armor":
				color = Color(0.6, 0.6, 0.8, 1)
			"shield":
				color = Color(0.7, 0.7, 0.5, 1)
			"consumable":
				color = Color(0.8, 0.4, 0.4, 1)
	
	image.fill(color)
	item_icon.texture = ImageTexture.create_from_image(image)

func clear_item():
	item_data = null
	item_icon.texture = null

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inventory_ui.on_equipment_slot_clicked(equip_type)
