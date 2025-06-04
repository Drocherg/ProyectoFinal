extends CanvasLayer

# Referencias a nodos
@onready var health_bar = $MarginContainer/Stats/HealthBar
@onready var energy_bar = $MarginContainer/Stats/EnergyBar
@onready var gold_label = $MarginContainer/Stats/GoldContainer/GoldLabel
@onready var level_label = $MarginContainer/Stats/LevelContainer/LevelLabel
@onready var minimap = $MarginContainer/MinimapContainer/Minimap
@onready var quick_slots = $QuickSlots

# Valores máximos
var max_health: float = 100.0
var max_energy: float = 100.0

# Valores actuales
var current_health: float = 100.0
var current_energy: float = 100.0
var current_gold: int = 0
var current_level: int = 1

func _ready():
	update_health(current_health)
	update_energy(current_energy)
	update_gold(current_gold)
	update_level(current_level)

func update_health(value: float):
	current_health = clamp(value, 0, max_health)
	health_bar.value = current_health
	health_bar.max_value = max_health
	health_bar.get_node("Label").text = str(int(current_health)) + "/" + str(int(max_health))

func update_energy(value: float):
	current_energy = clamp(value, 0, max_energy)
	energy_bar.value = current_energy
	energy_bar.max_value = max_energy
	energy_bar.get_node("Label").text = str(int(current_energy)) + "/" + str(int(max_energy))

func update_gold(value: int):
	current_gold = value
	gold_label.text = str(current_gold)

func update_level(value: int):
	current_level = value
	level_label.text = "Nivel " + str(current_level)

func update_max_values(new_max_health: float, new_max_energy: float):
	max_health = new_max_health
	max_energy = new_max_energy
	update_health(current_health)
	update_energy(current_energy)

func _input(event):
	# Tecla I para abrir/cerrar inventario
	if event.is_action_pressed("inventory"):
		var inventory = get_node_or_null("/root/InventoryManager")
		if inventory:
			inventory.toggle_inventory()
