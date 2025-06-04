# VERSIÓN CON TEXTURAS PIXEL ART - Estilo medieval fantasy
extends Node2D

var player
var enemy
var is_player_turn = true
var player_pa = 3
var enemy_pa = 3
var player_health = 50
var enemy_health = 30
var grid_size = 32
var selected_action = "MOVE"
var is_animating = false

# Dimensiones del grid
var grid_width = 15
var grid_height = 10

# UI Elements
var ui_layer
var turn_label
var pa_label
var health_label
var end_turn_button
var action_label

# Efectos y Grid
var effects_layer
var grid_area: Control

func _ready():
	print("🎮 Escena de combate - PIXEL ART MEDIEVAL")
	create_pixel_art_combat_scene()
	setup_ui()
	setup_grid_input_area()
	start_player_turn()

func create_pixel_art_combat_scene():
	# 1. FONDO MEDIEVAL CON TEXTURAS PIXEL ART
	create_medieval_background()
	
	# 2. MAPA CON TEXTURAS DETALLADAS
	create_detailed_terrain_map()
	
	# 3. GRID SUTIL ENCIMA
	create_subtle_grid_lines()
	
	# Capa para efectos
	effects_layer = Node2D.new()
	effects_layer.name = "Effects"
	add_child(effects_layer)
	
	player = create_player()
	enemy = create_enemy()

# 🏰 FONDO MEDIEVAL CON PIXEL ART
func create_medieval_background():
	# Fondo principal - color tierra medieval
	var main_background = ColorRect.new()
	main_background.size = Vector2(1200, 800)
	main_background.position = Vector2(-200, -100)
	main_background.color = Color(0.35, 0.3, 0.25)  # Marrón tierra medieval
	add_child(main_background)
	
	# Crear elementos medievales de fondo
	create_medieval_elements()
	
	# Marco decorativo alrededor del campo de batalla
	create_battlefield_frame()

func create_medieval_elements():
	var elements_container = Node2D.new()
	elements_container.name = "MedievalElements"
	add_child(elements_container)
	
	# Muros de piedra a los lados
	create_stone_walls(elements_container)
	
	# Torres de vigilancia en las esquinas
	create_watchtowers(elements_container)
	
	# Vegetación medieval
	create_medieval_vegetation(elements_container)

func create_stone_walls(parent: Node2D):
	# Muro izquierdo
	for i in range(12):
		var wall_section = create_stone_wall_section()
		wall_section.position = Vector2(-80, i * 32 - 50)
		wall_section.modulate = Color(0.8, 0.8, 0.8, 0.9)
		parent.add_child(wall_section)
	
	# Muro derecho
	for i in range(12):
		var wall_section = create_stone_wall_section()
		wall_section.position = Vector2(grid_width * grid_size + 50, i * 32 - 50)
		wall_section.modulate = Color(0.8, 0.8, 0.8, 0.9)
		parent.add_child(wall_section)

func create_stone_wall_section() -> Node2D:
	var wall = Node2D.new()
	
	# Base de piedra
	var base = ColorRect.new()
	base.size = Vector2(32, 32)
	base.color = Color(0.6, 0.6, 0.55)  # Gris piedra
	wall.add_child(base)
	
	# Patrón de bloques de piedra
	for x in range(4):
		for y in range(4):
			if (x + y) % 2 == 0:
				var block = ColorRect.new()
				block.size = Vector2(6, 6)
				block.position = Vector2(x * 8 + 1, y * 8 + 1)
				block.color = Color(0.5, 0.5, 0.45)  # Más oscuro
				base.add_child(block)
	
	# Líneas de mortero
	var mortar_h = ColorRect.new()
	mortar_h.size = Vector2(32, 1)
	mortar_h.position = Vector2(0, 16)
	mortar_h.color = Color(0.4, 0.4, 0.35)
	base.add_child(mortar_h)
	
	var mortar_v = ColorRect.new()
	mortar_v.size = Vector2(1, 32)
	mortar_v.position = Vector2(16, 0)
	mortar_v.color = Color(0.4, 0.4, 0.35)
	base.add_child(mortar_v)
	
	return wall

func create_watchtowers(parent: Node2D):
	# Torre esquina superior izquierda
	var tower1 = create_medieval_tower()
	tower1.position = Vector2(-120, -80)
	parent.add_child(tower1)
	
	# Torre esquina superior derecha
	var tower2 = create_medieval_tower()
	tower2.position = Vector2(grid_width * grid_size + 80, -80)
	parent.add_child(tower2)

func create_medieval_tower() -> Node2D:
	var tower = Node2D.new()
	
	# Base de la torre
	var base = ColorRect.new()
	base.size = Vector2(40, 60)
	base.color = Color(0.5, 0.5, 0.45)
	tower.add_child(base)
	
	# Patrón de piedras en la torre
	for y in range(6):
		for x in range(4):
			var stone = ColorRect.new()
			stone.size = Vector2(8, 8)
			stone.position = Vector2(x * 10 + 2, y * 10 + 2)
			stone.color = Color(0.45, 0.45, 0.4)
			base.add_child(stone)
	
	# Techo puntiagudo
	var roof = Node2D.new()
	roof.position = Vector2(20, 0)
	tower.add_child(roof)
	
	# Crear techo triangular con pixel art
	for i in range(10):
		var roof_line = ColorRect.new()
		roof_line.size = Vector2(20 - i * 2, 2)
		roof_line.position = Vector2(-10 + i, -20 + i * 2)
		roof_line.color = Color(0.6, 0.3, 0.2)  # Rojo teja
		roof.add_child(roof_line)
	
	return tower

func create_medieval_vegetation(parent: Node2D):
	# Arbustos medievales alrededor
	for i in range(15):
		var bush = create_medieval_bush()
		var angle = (i / 15.0) * 2 * PI
		var radius = 250 + randf_range(-50, 50)
		bush.position = Vector2(
			grid_width * grid_size / 2 + cos(angle) * radius,
			grid_height * grid_size / 2 + sin(angle) * radius
		)
		bush.modulate = Color(0.7, 0.8, 0.6, 0.8)
		parent.add_child(bush)

func create_medieval_bush() -> Node2D:
	var bush = Node2D.new()
	
	# Base del arbusto
	var base = ColorRect.new()
	base.size = Vector2(16, 12)
	base.position = Vector2(-8, -6)
	base.color = Color(0.3, 0.5, 0.2)  # Verde oscuro
	bush.add_child(base)
	
	# Hojas superiores
	var leaves = ColorRect.new()
	leaves.size = Vector2(12, 8)
	leaves.position = Vector2(-6, -10)
	leaves.color = Color(0.4, 0.6, 0.3)  # Verde más claro
	bush.add_child(leaves)
	
	# Pequeños detalles de hojas
	for i in range(3):
		var leaf = ColorRect.new()
		leaf.size = Vector2(2, 2)
		leaf.position = Vector2(randf_range(-6, 6), randf_range(-8, -2))
		leaf.color = Color(0.5, 0.7, 0.4)
		bush.add_child(leaf)
	
	return bush

func create_battlefield_frame():
	# Marco decorativo alrededor del campo de batalla
	var frame_container = Node2D.new()
	frame_container.name = "BattlefieldFrame"
	add_child(frame_container)
	
	# Borde superior
	var top_border = create_decorative_border(grid_width * grid_size, 8, true)
	top_border.position = Vector2(0, -8)
	frame_container.add_child(top_border)
	
	# Borde inferior
	var bottom_border = create_decorative_border(grid_width * grid_size, 8, true)
	bottom_border.position = Vector2(0, grid_height * grid_size)
	frame_container.add_child(bottom_border)
	
	# Borde izquierdo
	var left_border = create_decorative_border(8, grid_height * grid_size, false)
	left_border.position = Vector2(-8, 0)
	frame_container.add_child(left_border)
	
	# Borde derecho
	var right_border = create_decorative_border(8, grid_height * grid_size, false)
	right_border.position = Vector2(grid_width * grid_size, 0)
	frame_container.add_child(right_border)

func create_decorative_border(width: int, height: int, horizontal: bool) -> ColorRect:
	var border = ColorRect.new()
	border.size = Vector2(width, height)
	border.color = Color(0.4, 0.35, 0.3)  # Marrón oscuro
	
	# Patrón decorativo
	var pattern_size = 8
	var steps = width / pattern_size if horizontal else height / pattern_size
	
	for i in range(steps):
		var decoration = ColorRect.new()
		decoration.size = Vector2(4, 4)
		if horizontal:
			decoration.position = Vector2(i * pattern_size + 2, 2)
		else:
			decoration.position = Vector2(2, i * pattern_size + 2)
		decoration.color = Color(0.6, 0.5, 0.4)  # Más claro
		border.add_child(decoration)
	
	return border

# 🌍 MAPA CON TEXTURAS PIXEL ART DETALLADAS
func create_detailed_terrain_map():
	var terrain_container = Node2D.new()
	terrain_container.name = "DetailedTerrain"
	add_child(terrain_container)
	
	print("🎨 Creando mapa pixel art detallado:")
	
	for x in range(grid_width):
		for y in range(grid_height):
			var tile_pos = Vector2(x * grid_size, y * grid_size)
			var terrain_tile = create_pixel_art_terrain_tile(x, y)
			terrain_tile.position = tile_pos
			terrain_container.add_child(terrain_tile)

func create_pixel_art_terrain_tile(grid_x: int, grid_y: int) -> Control:
	var tile = Control.new()
	tile.size = Vector2(grid_size, grid_size)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Determinar tipo de terreno
	var terrain_type = get_medieval_terrain_type(grid_x, grid_y)
	
	match terrain_type:
		"cobblestone":
			add_cobblestone_texture(tile)
		"grass":
			add_detailed_grass_texture(tile)
		"dirt_path":
			add_dirt_path_texture(tile)
		"stone_floor":
			add_stone_floor_texture(tile)
		"worn_stone":
			add_worn_stone_texture(tile)
	
	return tile

func get_medieval_terrain_type(x: int, y: int) -> String:
	# Patrón más medieval y estratégico
	var noise = (x * 13 + y * 17) % 31
	
	# Camino central de adoquines
	if abs(x - grid_width/2) <= 1:
		return "cobblestone"
	
	# Bordes de piedra
	if x == 0 or x == grid_width - 1 or y == 0 or y == grid_height - 1:
		if noise % 3 == 0:
			return "stone_floor"
		else:
			return "worn_stone"
	
	# Área central variada
	if noise % 8 == 0:
		return "dirt_path"
	elif noise % 5 == 0:
		return "cobblestone"
	elif noise % 3 == 0:
		return "stone_floor"
	else:
		return "grass"

func add_cobblestone_texture(tile: Control):
	# Base de adoquines
	var base = ColorRect.new()
	base.size = Vector2(grid_size, grid_size)
	base.color = Color(0.55, 0.55, 0.5)  # Gris adoquín
	tile.add_child(base)
	
	# Patrón de adoquines individuales
	for x in range(4):
		for y in range(4):
			var cobble = ColorRect.new()
			cobble.size = Vector2(6, 6)
			cobble.position = Vector2(x * 8 + 1, y * 8 + 1)
			
			# Variación de color para cada adoquín
			var variation = randf_range(-0.1, 0.1)
			cobble.color = Color(0.5 + variation, 0.5 + variation, 0.45 + variation)
			base.add_child(cobble)
			
			# Líneas de separación
			if x < 3:
				var sep_v = ColorRect.new()
				sep_v.size = Vector2(1, 6)
				sep_v.position = Vector2(x * 8 + 7, y * 8 + 1)
				sep_v.color = Color(0.3, 0.3, 0.25)
				base.add_child(sep_v)
			
			if y < 3:
				var sep_h = ColorRect.new()
				sep_h.size = Vector2(6, 1)
				sep_h.position = Vector2(x * 8 + 1, y * 8 + 7)
				sep_h.color = Color(0.3, 0.3, 0.25)
				base.add_child(sep_h)

func add_detailed_grass_texture(tile: Control):
	# Base de césped
	var base = ColorRect.new()
	base.size = Vector2(grid_size, grid_size)
	base.color = Color(0.35, 0.6, 0.3)  # Verde césped
	tile.add_child(base)
	
	# Patrón de césped detallado
	for i in range(16):
		var grass_pixel = ColorRect.new()
		grass_pixel.size = Vector2(2, 2)
		grass_pixel.position = Vector2(randf_range(0, grid_size-2), randf_range(0, grid_size-2))
		grass_pixel.color = Color(0.4, 0.7, 0.35)  # Verde más claro
		base.add_child(grass_pixel)
	
	# Briznas de hierba
	for i in range(8):
		var blade = ColorRect.new()
		blade.size = Vector2(1, 4)
		blade.position = Vector2(randf_range(2, grid_size-3), randf_range(2, grid_size-6))
		blade.color = Color(0.3, 0.8, 0.25)
		base.add_child(blade)

func add_dirt_path_texture(tile: Control):
	# Base de tierra
	var base = ColorRect.new()
	base.size = Vector2(grid_size, grid_size)
	base.color = Color(0.5, 0.35, 0.25)  # Marrón tierra
	tile.add_child(base)
	
	# Textura de tierra con pequeñas piedras
	for i in range(12):
		var dirt_pixel = ColorRect.new()
		dirt_pixel.size = Vector2(2, 2)
		dirt_pixel.position = Vector2(randf_range(0, grid_size-2), randf_range(0, grid_size-2))
		dirt_pixel.color = Color(0.45, 0.3, 0.2)  # Más oscuro
		base.add_child(dirt_pixel)
	
	# Pequeñas piedras
	for i in range(4):
		var stone = ColorRect.new()
		stone.size = Vector2(3, 3)
		stone.position = Vector2(randf_range(2, grid_size-5), randf_range(2, grid_size-5))
		stone.color = Color(0.4, 0.4, 0.35)
		base.add_child(stone)

func add_stone_floor_texture(tile: Control):
	# Base de piedra
	var base = ColorRect.new()
	base.size = Vector2(grid_size, grid_size)
	base.color = Color(0.6, 0.6, 0.55)  # Gris piedra
	tile.add_child(base)
	
	# Patrón de losas de piedra
	for x in range(2):
		for y in range(2):
			var slab = ColorRect.new()
			slab.size = Vector2(14, 14)
			slab.position = Vector2(x * 16 + 1, y * 16 + 1)
			slab.color = Color(0.55, 0.55, 0.5)
			base.add_child(slab)
			
			# Borde de la losa
			var border = ColorRect.new()
			border.size = Vector2(16, 16)
			border.position = Vector2(x * 16, y * 16)
			border.color = Color(0.4, 0.4, 0.35)
			base.add_child(border)
			base.move_child(border, 0)  # Mover al fondo

func add_worn_stone_texture(tile: Control):
	# Base de piedra desgastada
	var base = ColorRect.new()
	base.size = Vector2(grid_size, grid_size)
	base.color = Color(0.5, 0.5, 0.45)  # Gris más oscuro
	tile.add_child(base)
	
	# Marcas de desgaste
	for i in range(8):
		var wear = ColorRect.new()
		wear.size = Vector2(randf_range(2, 6), randf_range(1, 3))
		wear.position = Vector2(randf_range(0, grid_size-6), randf_range(0, grid_size-3))
		wear.color = Color(0.45, 0.45, 0.4)
		base.add_child(wear)

# 📏 LÍNEAS DEL GRID SUTILES
func create_subtle_grid_lines():
	var grid_container = Node2D.new()
	grid_container.name = "SubtleGrid"
	add_child(grid_container)
	
	# Líneas muy sutiles para no interferir con el pixel art
	for x in range(grid_width + 1):
		var line = Line2D.new()
		var x_pos = x * grid_size
		line.add_point(Vector2(x_pos, 0))
		line.add_point(Vector2(x_pos, grid_height * grid_size))
		line.default_color = Color(0, 0, 0, 0.3)  # Negro muy transparente
		line.width = 1
		grid_container.add_child(line)
	
	for y in range(grid_height + 1):
		var line = Line2D.new()
		var y_pos = y * grid_size
		line.add_point(Vector2(0, y_pos))
		line.add_point(Vector2(grid_width * grid_size, y_pos))
		line.default_color = Color(0, 0, 0, 0.3)
		line.width = 1
		grid_container.add_child(line)

func setup_grid_input_area():
	grid_area = Control.new()
	grid_area.name = "GridInputArea"
	grid_area.size = Vector2(grid_width * grid_size, grid_height * grid_size)
	grid_area.position = Vector2(0, 0)
	grid_area.mouse_filter = Control.MOUSE_FILTER_PASS
	
	grid_area.gui_input.connect(_on_grid_input)
	add_child(grid_area)

func _on_grid_input(event):
	if not is_player_turn or is_animating:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and player_pa > 0:
			handle_grid_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_action_mode()

func handle_grid_click(local_click_pos: Vector2):
	var grid_x = int(local_click_pos.x / grid_size)
	var grid_y = int(local_click_pos.y / grid_size)
	var target_pos = Vector2(grid_x * grid_size + grid_size/2, grid_y * grid_size + grid_size/2)
	
	if grid_x >= 0 and grid_x < grid_width and grid_y >= 0 and grid_y < grid_height:
		create_medieval_click_indicator(Vector2(grid_x * grid_size, grid_y * grid_size))
		
		if selected_action == "MOVE":
			handle_move(target_pos)
		elif selected_action == "ATTACK":
			handle_attack(target_pos)

func create_medieval_click_indicator(tile_pos: Vector2):
	var indicator = ColorRect.new()
	indicator.size = Vector2(grid_size, grid_size)
	indicator.position = tile_pos
	indicator.color = Color.YELLOW if selected_action == "ATTACK" else Color.CYAN
	indicator.modulate.a = 0.6
	effects_layer.add_child(indicator)
	
	# Borde medieval
	var border = ColorRect.new()
	border.size = Vector2(grid_size - 4, grid_size - 4)
	border.position = Vector2(2, 2)
	border.color = Color.TRANSPARENT
	indicator.add_child(border)
	
	# Crear borde pixel art
	for i in range(4):
		# Esquinas
		var corner = ColorRect.new()
		corner.size = Vector2(4, 4)
		match i:
			0: corner.position = Vector2(0, 0)
			1: corner.position = Vector2(grid_size - 4, 0)
			2: corner.position = Vector2(0, grid_size - 4)
			3: corner.position = Vector2(grid_size - 4, grid_size - 4)
		corner.color = Color.WHITE
		indicator.add_child(corner)
	
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "scale", Vector2(1.1, 1.1), 0.2)
	tween.parallel().tween_property(indicator, "modulate:a", 0.0, 0.8)
	tween.tween_callback(indicator.queue_free)

func create_player():
	var player_node = CharacterBody2D.new()
	player_node.name = "Player"
	
	var animated_sprite = create_player_sprite()
	player_node.add_child(animated_sprite)
	
	create_medieval_health_bar(player_node, Color.CYAN)
	
	var turn_indicator = create_medieval_turn_indicator(Color.YELLOW)
	turn_indicator.name = "TurnIndicator"
	player_node.add_child(turn_indicator)
	
	player_node.position = Vector2(2 * grid_size + grid_size/2, 5 * grid_size + grid_size/2)
	add_child(player_node)
	return player_node

func create_player_sprite():
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	
	var sprite_frames = load_player_sprite_frames()
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idleFront")
		animated_sprite.scale = Vector2(1.0, 1.0)
		print("✅ Sprite del jugador cargado")
	else:
		animated_sprite.queue_free()
		return create_fallback_player_sprite()
	
	return animated_sprite

func load_player_sprite_frames():
	var possible_paths = [
		"res://Assets/Player/player_animations.tres",
		"res://assets/player/player_animations.tres", 
		"res://Player/player_animations.tres",
		"res://Sprites/Player/player_animations.tres",
		"res://Graphics/Player/player_animations.tres",
		"res://Escenas/Player.tscn",
		"res://Scenes/Player.tscn"
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			if path.ends_with(".tscn"):
				var scene = load(path)
				var instance = scene.instantiate()
				var sprite = instance.get_node_or_null("AnimatedSprite2D")
				if sprite and sprite.sprite_frames:
					var frames = sprite.sprite_frames
					instance.queue_free()
					return frames
			else:
				return load(path)
	
	return null

func create_fallback_player_sprite():
	var sprite = ColorRect.new()
	sprite.size = Vector2(24, 24)
	sprite.position = Vector2(-12, -12)
	sprite.color = Color(0.2, 0.4, 0.8)
	sprite.name = "FallbackSprite"
	
	var border = ColorRect.new()
	border.size = Vector2(26, 26)
	border.position = Vector2(-13, -13)
	border.color = Color(0.1, 0.2, 0.4)
	sprite.add_child(border)
	sprite.move_child(border, 0)
	
	return sprite

func create_enemy():
	var enemy_node = CharacterBody2D.new()
	enemy_node.name = "Enemy"
	
	var animated_sprite = create_enemy_sprite()
	enemy_node.add_child(animated_sprite)
	
	create_medieval_health_bar(enemy_node, Color.ORANGE)
	
	var turn_indicator = create_medieval_turn_indicator(Color.RED)
	turn_indicator.name = "TurnIndicator"
	turn_indicator.visible = false
	enemy_node.add_child(turn_indicator)
	
	enemy_node.position = Vector2(12 * grid_size + grid_size/2, 5 * grid_size + grid_size/2)
	add_child(enemy_node)
	return enemy_node

func create_enemy_sprite():
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	
	# RUTA ACTUALIZADA DEL ENEMIGO
	var sprite_frames = load_enemy_sprite_frames()
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idleFront")
		animated_sprite.scale = Vector2(1.0, 1.0)
		print("✅ Sprite del enemigo cargado desde malo.tscn")
	else:
		animated_sprite.queue_free()
		return create_fallback_enemy_sprite()
	
	return animated_sprite

func load_enemy_sprite_frames():
	# RUTA ACTUALIZADA
	var possible_paths = [
		"res://Escenas/malo.tscn",  # NUEVA RUTA PRINCIPAL
		"res://Assets/Enemy/enemy_animations.tres",
		"res://assets/enemy/enemy_animations.tres",
		"res://Enemy/enemy_animations.tres", 
		"res://Sprites/Enemy/enemy_animations.tres",
		"res://Graphics/Enemy/enemy_animations.tres",
		"res://Escenas/Enemy.tscn",
		"res://Scenes/Enemy.tscn"
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			print("✅ Encontrado sprite del enemigo en:", path)
			if path.ends_with(".tscn"):
				var scene = load(path)
				var instance = scene.instantiate()
				var sprite = instance.get_node_or_null("AnimatedSprite2D")
				if sprite and sprite.sprite_frames:
					var frames = sprite.sprite_frames
					instance.queue_free()
					return frames
			else:
				return load(path)
	
	print("❌ No se encontró sprite del enemigo")
	return null

func create_fallback_enemy_sprite():
	var sprite = ColorRect.new()
	sprite.size = Vector2(24, 24)
	sprite.position = Vector2(-12, -12)
	sprite.color = Color(0.8, 0.2, 0.2)
	sprite.name = "FallbackSprite"
	
	var border = ColorRect.new()
	border.size = Vector2(26, 26)
	border.position = Vector2(-13, -13)
	border.color = Color(0.4, 0.1, 0.1)
	sprite.add_child(border)
	sprite.move_child(border, 0)
	
	return sprite

func create_medieval_health_bar(character: Node2D, bar_color: Color):
	# Fondo de la barra estilo medieval
	var health_bg = ColorRect.new()
	health_bg.size = Vector2(32, 8)
	health_bg.position = Vector2(-16, -24)
	health_bg.color = Color(0.2, 0.1, 0.1)  # Marrón muy oscuro
	health_bg.name = "HealthBG"
	character.add_child(health_bg)
	
	# Borde de la barra
	var border = ColorRect.new()
	border.size = Vector2(34, 10)
	border.position = Vector2(-17, -25)
	border.color = Color(0.6, 0.5, 0.3)  # Dorado
	character.add_child(border)
	character.move_child(border, 0)
	
	# Barra de vida
	var health_bar = ColorRect.new()
	health_bar.size = Vector2(30, 6)
	health_bar.position = Vector2(-15, -23)
	health_bar.color = bar_color
	health_bar.name = "HealthBar"
	character.add_child(health_bar)

func create_medieval_turn_indicator(color: Color) -> Control:
	var indicator = Control.new()
	indicator.size = Vector2(12, 12)
	indicator.position = Vector2(-6, -32)
	
	# Gema/cristal indicador
	var gem = ColorRect.new()
	gem.size = Vector2(8, 8)
	gem.position = Vector2(2, 2)
	gem.color = color
	indicator.add_child(gem)
	
	# Borde de la gema
	var border = ColorRect.new()
	border.size = Vector2(10, 10)
	border.position = Vector2(1, 1)
	border.color = Color(0.8, 0.7, 0.5)  # Dorado
	indicator.add_child(border)
	indicator.move_child(border, 0)
	
	return indicator

# 🎨 UI MEDIEVAL
func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Panel principal estilo medieval
	create_medieval_ui_panel()
	
	# Instrucciones en panel separado
	create_medieval_instructions_panel()

func create_medieval_ui_panel():
	# Fondo del panel con textura
	var main_panel = ColorRect.new()
	main_panel.size = Vector2(320, 150)
	main_panel.position = Vector2(10, 10)
	main_panel.color = Color(0.15, 0.1, 0.08)  # Marrón muy oscuro
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(main_panel)
	
	# Marco dorado decorativo
	var frame = ColorRect.new()
	frame.size = Vector2(324, 154)
	frame.position = Vector2(8, 8)
	frame.color = Color(0.8, 0.6, 0.2)  # Dorado
	ui_layer.add_child(frame)
	ui_layer.move_child(frame, 0)
	
	# Decoraciones en las esquinas
	for i in range(4):
		var corner_decoration = ColorRect.new()
		corner_decoration.size = Vector2(8, 8)
		corner_decoration.color = Color(1.0, 0.8, 0.3)  # Dorado brillante
		match i:
			0: corner_decoration.position = Vector2(12, 12)
			1: corner_decoration.position = Vector2(320, 12)
			2: corner_decoration.position = Vector2(12, 150)
			3: corner_decoration.position = Vector2(320, 150)
		ui_layer.add_child(corner_decoration)
	
	# Labels con estilo medieval
	turn_label = Label.new()
	turn_label.position = Vector2(25, 30)
	turn_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))  # Beige claro
	turn_label.add_theme_font_size_override("font_size", 18)
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(turn_label)
	
	pa_label = Label.new()
	pa_label.position = Vector2(25, 55)
	pa_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))  # Azul mágico
	pa_label.add_theme_font_size_override("font_size", 16)
	pa_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(pa_label)
	
	health_label = Label.new()
	health_label.position = Vector2(25, 80)
	health_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))  # Rojo sangre
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(health_label)
	
	action_label = Label.new()
	action_label.position = Vector2(25, 105)
	action_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Dorado
	action_label.add_theme_font_size_override("font_size", 16)
	action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(action_label)
	
	# Botón estilo medieval
	end_turn_button = Button.new()
	end_turn_button.position = Vector2(180, 115)
	end_turn_button.size = Vector2(130, 35)
	end_turn_button.text = "Terminar Turno"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_layer.add_child(end_turn_button)

func create_medieval_instructions_panel():
	# Panel de instrucciones estilo pergamino
	var instructions_panel = ColorRect.new()
	instructions_panel.size = Vector2(grid_width * grid_size, 70)
	instructions_panel.position = Vector2(0, grid_height * grid_size + 15)
	instructions_panel.color = Color(0.9, 0.85, 0.7)  # Color pergamino
	instructions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(instructions_panel)
	
	# Borde del pergamino
	var parchment_border = ColorRect.new()
	parchment_border.size = Vector2(grid_width * grid_size + 4, 74)
	parchment_border.position = Vector2(-2, grid_height * grid_size + 13)
	parchment_border.color = Color(0.6, 0.4, 0.2)  # Marrón borde
	parchment_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(parchment_border)
	ui_layer.move_child(parchment_border, 0)
	
	# Texto de instrucciones estilo medieval
	var instructions = Label.new()
	instructions.position = Vector2(15, grid_height * grid_size + 25)
	instructions.text = "⚔️ Clic Izquierdo: Ejecutar acción | 🛡️ Clic Derecho: Cambiar modo | 🗡️ Alcance de ataque: 1 casilla | 🏃 Movimiento: Hasta 3 PA"
	instructions.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))  # Marrón muy oscuro
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(instructions)

# Resto de funciones (lógica sin cambios)
func play_character_animation(character: Node2D, animation_name: String):
	var sprite = character.get_node_or_null("AnimatedSprite2D")
	if sprite and sprite is AnimatedSprite2D:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
			sprite.play(animation_name)
		else:
			if sprite.sprite_frames and sprite.sprite_frames.has_animation("idleFront"):
				sprite.play("idleFront")

func toggle_action_mode():
	if selected_action == "MOVE":
		selected_action = "ATTACK"
		create_mode_change_effect()
	else:
		selected_action = "MOVE"
		create_mode_change_effect()
	update_ui()

func create_mode_change_effect():
	var effect = ColorRect.new()
	effect.size = Vector2(40, 40)
	effect.position = player.position - Vector2(20, 20)
	effect.color = Color.YELLOW if selected_action == "ATTACK" else Color.CYAN
	effect.modulate.a = 0.7
	effects_layer.add_child(effect)
	
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func handle_move(target_pos: Vector2):
	var distance = get_grid_distance(player.position, target_pos)
	
	if distance <= player_pa and distance > 0:
		is_animating = true
		
		var direction = (target_pos - player.position).normalized()
		play_movement_animation(player, direction)
		
		await animate_movement(player, target_pos)
		
		play_character_animation(player, "idleFront")
		
		player_pa -= distance
		print("🚶 Jugador movido")
		update_ui()
		is_animating = false
		
		if player_pa <= 0:
			end_player_turn()

func play_movement_animation(character: Node2D, direction: Vector2):
	var animation_name = "walkFront"
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animation_name = "walkRight"
			var sprite = character.get_node_or_null("AnimatedSprite2D")
			if sprite:
				sprite.flip_h = false
		else:
			animation_name = "walkLeft"
			var sprite = character.get_node_or_null("AnimatedSprite2D")
			if sprite:
				sprite.flip_h = false
	else:
		if direction.y > 0:
			animation_name = "walkFront"
		else:
			animation_name = "walkBack"
	
	play_character_animation(character, animation_name)

func handle_attack(target_pos: Vector2):
	var distance = get_grid_distance(player.position, target_pos)
	
	if distance <= 1 and player_pa >= 1:
		var enemy_distance = get_grid_distance(enemy.position, target_pos)
		if enemy_distance == 0:
			is_animating = true
			await attack_enemy()
			is_animating = false
		else:
			create_miss_effect(target_pos)

func animate_movement(character: Node2D, target_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(character, "position", target_pos, 0.3)
	tween.tween_callback(create_movement_trail.bind(character))
	await tween.finished

func create_movement_trail(character: Node2D):
	var trail = ColorRect.new()
	trail.size = Vector2(grid_size, grid_size)
	trail.position = character.position - Vector2(grid_size/2, grid_size/2)
	trail.color = Color.WHITE if character == player else Color.GRAY
	trail.modulate.a = 0.3
	effects_layer.add_child(trail)
	
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.5)
	tween.tween_callback(trail.queue_free)

func attack_enemy():
	var direction = (enemy.position - player.position).normalized()
	play_attack_animation(player, direction)
	
	var original_pos = player.position
	var attack_pos = player.position + direction * 10
	
	var tween = create_tween()
	tween.tween_property(player, "position", attack_pos, 0.1)
	tween.tween_property(player, "position", original_pos, 0.1)
	await tween.finished
	
	play_character_animation(player, "idleFront")
	
	var damage = 15
	enemy_health -= damage
	player_pa -= 1
	
	create_damage_effect(enemy.position, damage, Color.RED)
	shake_character(enemy)
	
	print("⚔️ Jugador ataca por", damage, "de daño")
	update_enemy_health_bar()
	update_ui()
	
	if enemy_health <= 0:
		await create_death_effect(enemy)
		victory()
	elif player_pa <= 0:
		end_player_turn()

func play_attack_animation(character: Node2D, direction: Vector2):
	var animation_name = "idleFront"
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animation_name = "attackRight"
		else:
			animation_name = "attackLeft"
	else:
		if direction.y > 0:
			animation_name = "attackFront"
		else:
			animation_name = "attackBack"
	
	play_character_animation(character, animation_name)

func create_damage_effect(pos: Vector2, damage: int, color: Color):
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.position = pos + Vector2(-10, -30)
	damage_label.add_theme_color_override("font_color", color)
	damage_label.add_theme_font_size_override("font_size", 20)
	effects_layer.add_child(damage_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", pos + Vector2(-10, -60), 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)

func create_miss_effect(pos: Vector2):
	var miss_label = Label.new()
	miss_label.text = "MISS"
	miss_label.position = pos + Vector2(-15, -20)
	miss_label.add_theme_color_override("font_color", Color.GRAY)
	miss_label.add_theme_font_size_override("font_size", 16)
	effects_layer.add_child(miss_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(miss_label, "position", pos + Vector2(-15, -40), 0.8)
	tween.parallel().tween_property(miss_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(miss_label.queue_free)

func shake_character(character: Node2D):
	var original_pos = character.position
	var tween = create_tween()
	
	for i in range(3):
		tween.tween_property(character, "position", original_pos + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	
	tween.tween_property(character, "position", original_pos, 0.05)

func create_death_effect(character: Node2D):
	var death_effect = ColorRect.new()
	death_effect.size = Vector2(50, 50)
	death_effect.position = character.position - Vector2(25, 25)
	death_effect.color = Color.WHITE
	effects_layer.add_child(death_effect)
	
	var tween = create_tween()
	tween.parallel().tween_property(death_effect, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(death_effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(death_effect.queue_free)
	
	var char_tween = create_tween()
	for i in range(5):
		char_tween.tween_property(character, "modulate:a", 0.3, 0.1)
		char_tween.tween_property(character, "modulate:a", 1.0, 0.1)
	
	await char_tween.finished

func get_grid_distance(pos1: Vector2, pos2: Vector2) -> int:
	var grid_pos1 = Vector2(int(pos1.x / grid_size), int(pos1.y / grid_size))
	var grid_pos2 = Vector2(int(pos2.x / grid_size), int(pos2.y / grid_size))
	return int(abs(grid_pos1.x - grid_pos2.x) + abs(grid_pos1.y - grid_pos2.y))

func start_player_turn():
	is_player_turn = true
	player_pa = 3
	selected_action = "MOVE"
	
	player.get_node("TurnIndicator").visible = true
	enemy.get_node("TurnIndicator").visible = false
	
	play_character_animation(player, "idleFront")
	
	print("🎮 Turno del jugador")
	update_ui()

func end_player_turn():
	is_player_turn = false
	print("🔚 Fin del turno del jugador")
	start_enemy_turn()

func start_enemy_turn():
	enemy_pa = 3
	
	player.get_node("TurnIndicator").visible = false
	enemy.get_node("TurnIndicator").visible = true
	
	play_character_animation(enemy, "idleFront")
	
	print("👹 Turno del enemigo")
	update_ui()
	await get_tree().create_timer(1.0).timeout
	enemy_ai()

func enemy_ai():
	if enemy_pa > 0:
		var distance_to_player = get_grid_distance(enemy.position, player.position)
		
		if distance_to_player <= 1 and enemy_pa >= 1:
			await attack_player()
		else:
			await move_enemy_towards_player()
		
		await get_tree().create_timer(0.8).timeout
		enemy_ai()
	else:
		end_enemy_turn()

func attack_player():
	var direction = (player.position - enemy.position).normalized()
	play_attack_animation(enemy, direction)
	
	var original_pos = enemy.position
	var attack_pos = enemy.position + direction * 10
	
	var tween = create_tween()
	tween.tween_property(enemy, "position", attack_pos, 0.1)
	tween.tween_property(enemy, "position", original_pos, 0.1)
	await tween.finished
	
	play_character_animation(enemy, "idleFront")
	
	var damage = 10
	player_health -= damage
	enemy_pa -= 1
	
	create_damage_effect(player.position, damage, Color.ORANGE)
	shake_character(player)
	
	print("👹 Enemigo ataca por", damage, "de daño")
	update_player_health_bar()
	update_ui()
	
	if player_health <= 0:
		await create_death_effect(player)
		defeat()

func move_enemy_towards_player():
	var direction = (player.position - enemy.position).normalized()
	var target_pos = enemy.position + direction * grid_size
	
	var grid_x = int(target_pos.x / grid_size)
	var grid_y = int(target_pos.y / grid_size)
	target_pos = Vector2(grid_x * grid_size + grid_size/2, grid_y * grid_size + grid_size/2)
	
	if grid_x >= 0 and grid_x < grid_width and grid_y >= 0 and grid_y < grid_height:
		play_movement_animation(enemy, direction)
		await animate_movement(enemy, target_pos)
		play_character_animation(enemy, "idleFront")
		enemy_pa -= 1
		print("👹 Enemigo se mueve")

func end_enemy_turn():
	print("🔄 Fin del turno del enemigo")
	start_player_turn()

func update_player_health_bar():
	var health_bar = player.get_node("HealthBar")
	var health_percent = float(player_health) / 50.0
	
	var tween = create_tween()
	tween.tween_property(health_bar, "size:x", 30 * health_percent, 0.3)
	
	health_bar.color = Color.CYAN if health_percent > 0.5 else Color.YELLOW if health_percent > 0.25 else Color.RED

func update_enemy_health_bar():
	var health_bar = enemy.get_node("HealthBar")
	var health_percent = float(enemy_health) / 30.0
	
	var tween = create_tween()
	tween.tween_property(health_bar, "size:x", 30 * health_percent, 0.3)
	
	health_bar.color = Color.ORANGE if health_percent > 0.5 else Color.YELLOW if health_percent > 0.25 else Color.RED

func victory():
	print("🎉 ¡Victoria!")
	turn_label.text = "🎉 ¡VICTORIA!"
	turn_label.add_theme_color_override("font_color", Color.GOLD)
	
	create_victory_effect()
	
	if GameManager:
		GameManager.combat_result = "victory"
	await get_tree().create_timer(3.0).timeout
	return_to_world()

func defeat():
	print("💀 Derrota...")
	turn_label.text = "💀 DERROTA"
	turn_label.add_theme_color_override("font_color", Color.RED)
	
	if GameManager:
		GameManager.combat_result = "defeat"
	await get_tree().create_timer(3.0).timeout
	return_to_world()

func create_victory_effect():
	for i in range(20):
		var firework = ColorRect.new()
		firework.size = Vector2(8, 8)
		firework.position = Vector2(randf_range(50, grid_width * grid_size - 50), randf_range(50, grid_height * grid_size - 50))
		firework.color = Color(randf(), randf(), randf())
		effects_layer.add_child(firework)
		
		var tween = create_tween()
		tween.parallel().tween_property(firework, "scale", Vector2(5, 5), 1.5)
		tween.parallel().tween_property(firework, "modulate:a", 0.0, 1.5)
		tween.tween_callback(firework.queue_free)
		
		await get_tree().create_timer(0.08)

func return_to_world():
	if GameManager:
		GameManager.return_to_world()
	else:
		get_tree().quit()

func _on_end_turn_pressed():
	if is_player_turn and not is_animating:
		end_player_turn()

func update_ui():
	if is_player_turn:
		turn_label.text = "🎮 Turno: Jugador"
		pa_label.text = "⚡ PA: %d/3" % player_pa
		health_label.text = "❤️ Vida: %d/50" % player_health
		action_label.text = "🎯 Modo: " + ("⚔️ ATAQUE" if selected_action == "ATTACK" else "👟 MOVIMIENTO")
		end_turn_button.visible = true
	else:
		turn_label.text = "👹 Turno: Enemigo"
		pa_label.text = "⚡ PA: %d/3" % enemy_pa
		health_label.text = "💀 Vida Enemigo: %d/30" % enemy_health
		action_label.text = ""
		end_turn_button.visible = false
