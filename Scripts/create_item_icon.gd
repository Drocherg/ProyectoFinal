extends Node

func _ready():
	create_placeholder_icons()
	get_tree().quit()

func create_placeholder_icons():
	var icons = {
		"sword": Color(0.7, 0.7, 0.9),
		"shield": Color(0.6, 0.8, 0.6),
		"helmet": Color(0.8, 0.7, 0.5),
		"chest": Color(0.9, 0.6, 0.6),
		"potion": Color(0.9, 0.3, 0.3),
		"default_icon": Color(0.5, 0.5, 0.5)
	}
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Assets"):
		dir.make_dir("Assets")
	
	if not dir.dir_exists("Assets/Items"):
		dir.make_dir("Assets/Items")
	
	for icon_name in icons:
		create_icon_image(icon_name, icons[icon_name])

func create_icon_image(name: String, color: Color):
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Dibujar un borde
	for x in range(64):
		for y in range(64):
			if x < 2 or x > 61 or y < 2 or y > 61:
				image.set_pixel(x, y, Color(0.2, 0.2, 0.2))
	
	# Añadir un símbolo simple según el tipo de objeto
	if name == "sword":
		draw_sword(image)
	elif name == "shield":
		draw_shield(image)
	elif name == "helmet":
		draw_helmet(image)
	elif name == "chest":
		draw_chest(image)
	elif name == "potion":
		draw_potion(image)
	
	var texture = ImageTexture.create_from_image(image)
	var error = ResourceSaver.save(texture, "res://Assets/Items/" + name + ".png")
	
	if error == OK:
		print("✅ Icono creado: " + name + ".png")
	else:
		print("❌ Error al guardar icono: " + name + ".png")

func draw_sword(image: Image):
	# Dibujar una espada simple
	for y in range(15, 50):
		image.set_pixel(32, y, Color(0.3, 0.3, 0.3))
	
	for x in range(22, 43):
		image.set_pixel(x, 15, Color(0.3, 0.3, 0.3))
	
	for x in range(27, 38):
		for y in range(10, 15):
			image.set_pixel(x, y, Color(0.8, 0.8, 1.0))

func draw_shield(image: Image):
	# Dibujar un escudo simple
	for x in range(22, 43):
		for y in range(15, 45):
			if (x - 32) * (x - 32) + (y - 30) * (y - 30) < 225:
				image.set_pixel(x, y, Color(0.4, 0.6, 0.4))

func draw_helmet(image: Image):
	# Dibujar un casco simple
	for x in range(22, 43):
		for y in range(25, 45):
			if y > 35 or (x > 25 and x < 39):
				image.set_pixel(x, y, Color(0.6, 0.5, 0.3))

func draw_chest(image: Image):
	# Dibujar una armadura simple
	for x in range(22, 43):
		for y in range(15, 45):
			if (y > 25 and y < 40) or (x > 27 and x < 38 and y < 25):
				image.set_pixel(x, y, Color(0.7, 0.4, 0.4))

func draw_potion(image: Image):
	# Dibujar una poción simple
	for x in range(27, 38):
		for y in range(20, 45):
			if y > 30 or (x > 29 and x < 36):
				image.set_pixel(x, y, Color(0.8, 0.2, 0.2))
	
	for x in range(29, 36):
		for y in range(15, 20):
			image.set_pixel(x, y, Color(0.3, 0.3, 0.3))
