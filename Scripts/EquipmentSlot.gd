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
	
	# Cargar icono
	if ResourceLoader.exists(item.icon):
		item_icon.texture = load(item.icon)

func clear_item():
	item_data = null
	item_icon.texture = null

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inventory_ui.on_equipment_slot_clicked(equip_type)
