extends ColorRect

func _ready():
	# Crear un fondo con patrón de tablero
	create_checkerboard_pattern()

func create_checkerboard_pattern():
	# Crear un patrón de tablero sutil
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	
	for x in range(64):
		for y in range(64):
			var tile_x = x / 32
			var tile_y = y / 32
			if (tile_x + tile_y) % 2 == 0:
				image.set_pixel(x, y, Color(0.9, 0.9, 0.85))  # Color claro
			else:
				image.set_pixel(x, y, Color(0.85, 0.85, 0.8))  # Color más oscuro
	
	texture.set_image(image)
	
	# Aplicar como textura repetida
	var style = StyleBoxTexture.new()
	style.texture = texture
	add_theme_stylebox_override("panel", style)
