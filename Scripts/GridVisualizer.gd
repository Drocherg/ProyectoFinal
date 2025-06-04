# Script para visualizar exactamente dónde detecta los clics
extends Node2D

var grid_size = 32

func _ready():
	# Crear puntos de referencia en cada esquina del grid
	create_corner_markers()

func create_corner_markers():
	# Esquinas del grid
	var corners = [
		Vector2(0, 0),                    # Esquina superior izquierda
		Vector2(14 * grid_size, 0),       # Esquina superior derecha  
		Vector2(0, 9 * grid_size),        # Esquina inferior izquierda
		Vector2(14 * grid_size, 9 * grid_size)  # Esquina inferior derecha
	]
	
	for i in range(corners.size()):
		var marker = ColorRect.new()
		marker.size = Vector2(8, 8)
		marker.position = corners[i] - Vector2(4, 4)
		marker.color = Color.RED
		add_child(marker)
		
		# Agregar label con coordenadas
		var label = Label.new()
		label.position = corners[i] + Vector2(10, -5)
		label.text = str(corners[i])
		label.add_theme_color_override("font_color", Color.BLACK)
		label.add_theme_font_size_override("font_size", 10)
		add_child(label)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.position
		var local_pos = to_local(click_pos)
		var grid_x = int(local_pos.x / grid_size)
		var grid_y = int(local_pos.y / grid_size)
		
		print("🔍 GRID DEBUG:")
		print("  Clic pantalla:", click_pos)
		print("  Posición local:", local_pos)
		print("  Grid calculado:", Vector2(grid_x, grid_y))
		print("  Límites válidos: x(0-14), y(0-9)")
		print("  ¿Dentro del grid?", grid_x >= 0 and grid_x < 15 and grid_y >= 0 and grid_y < 10)
		print("---")
