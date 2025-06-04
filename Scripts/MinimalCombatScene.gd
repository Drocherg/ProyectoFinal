# Versión mínima para probar que funciona
extends Node2D

var player
var enemy

func _ready():
	print("🎮 Escena de combate mínima iniciada")
	create_simple_combat()

func create_simple_combat():
	# Crear fondo simple
	var background = ColorRect.new()
	background.size = Vector2(480, 320)
	background.color = Color(0.8, 0.8, 0.7)
	add_child(background)
	
	# Crear jugador simple
	player = ColorRect.new()
	player.size = Vector2(32, 32)
	player.position = Vector2(100, 150)
	player.color = Color.BLUE
	add_child(player)
	
	# Crear enemigo simple
	enemy = ColorRect.new()
	enemy.size = Vector2(32, 32)
	enemy.position = Vector2(350, 150)
	enemy.color = Color.RED
	add_child(enemy)
	
	# Crear UI simple
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var label = Label.new()
	label.position = Vector2(10, 10)
	label.text = "Combate iniciado - Presiona ESC para salir"
	ui_layer.add_child(label)
	
	print("✅ Combate simple creado")

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		print("🏠 Regresando al mundo...")
		if GameManager:
			GameManager.return_to_world()
		else:
			get_tree().quit()
