# VERSIÓN FINAL - Grid completamente arreglado
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

# UI Elements
var ui_layer
var turn_label
var pa_label
var health_label
var end_turn_button
var action_label

# Efectos y Grid
var effects_layer
var grid_area: Control  # Área específica para detectar clics del grid

func _ready():
	print("🎮 Escena de combate - GRID DEFINITIVAMENTE ARREGLADO")
	create_combat_scene()
	setup_ui()
	setup_grid_input_area()  # NUEVA función para manejar input
	start_player_turn()

func create_combat_scene():
	# Fondo mejorado
	var background = ColorRect.new()
	background.size = Vector2(480, 320)
	background.color = Color(0.85, 0.82, 0.75)
	add_child(background)
	
	create_checkerboard_background()
	create_grid()
	
	# Capa para efectos
	effects_layer = Node2D.new()
	effects_layer.name = "Effects"
	add_child(effects_layer)
	
	player = create_player()
	enemy = create_enemy()

func create_checkerboard_background():
	var pattern = Node2D.new()
	pattern.name = "Pattern"
	add_child(pattern)
	
	for x in range(15):
		for y in range(10):
			if (x + y) % 2 == 1:
				var tile = ColorRect.new()
				tile.size = Vector2(grid_size, grid_size)
				tile.position = Vector2(x * grid_size, y * grid_size)
				tile.color = Color(0.8, 0.77, 0.7, 0.3)
				pattern.add_child(tile)

func create_grid():
	var grid_container = Node2D.new()
	grid_container.name = "Grid"
	add_child(grid_container)
	
	for x in range(16):
		var line = Line2D.new()
		line.add_point(Vector2(x * grid_size, 0))
		line.add_point(Vector2(x * grid_size, 320))
		line.default_color = Color(0.4, 0.4, 0.4, 0.6)
		line.width = 2
		grid_container.add_child(line)
	
	for y in range(11):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * grid_size))
		line.add_point(Vector2(480, y * grid_size))
		line.default_color = Color(0.4, 0.4, 0.4, 0.6)
		line.width = 2
		grid_container.add_child(line)

# NUEVA FUNCIÓN: Área específica para detectar clics del grid
func setup_grid_input_area():
	grid_area = Control.new()
	grid_area.name = "GridInputArea"
	grid_area.size = Vector2(480, 320)  # Tamaño exacto del grid
	grid_area.position = Vector2(0, 0)   # Posición exacta del grid
	grid_area.mouse_filter = Control.MOUSE_FILTER_PASS  # Permitir clics
	
	# Conectar señales de input específicamente a esta área
	grid_area.gui_input.connect(_on_grid_input)
	
	# Agregar DESPUÉS del UI para que esté encima
	add_child(grid_area)

# NUEVA FUNCIÓN: Manejo de input específico del grid
func _on_grid_input(event):
	if not is_player_turn or is_animating:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and player_pa > 0:
			handle_grid_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_action_mode()

# FUNCIÓN CORREGIDA: Click del grid con coordenadas exactas
func handle_grid_click(local_click_pos: Vector2):
	# Las coordenadas ya son locales al grid_area
	var grid_x = int(local_click_pos.x / grid_size)
	var grid_y = int(local_click_pos.y / grid_size)
	var target_pos = Vector2(grid_x * grid_size + grid_size/2, grid_y * grid_size + grid_size/2)
	
	print("🎯 GRID CLICK:")
	print("  Posición en grid:", local_click_pos)
	print("  Casilla:", Vector2(grid_x, grid_y))
	print("  Target:", target_pos)
	print("  Válido:", grid_x >= 0 and grid_x < 15 and grid_y >= 0 and grid_y < 10)
	
	# Verificar límites del grid
	if grid_x >= 0 and grid_x < 15 and grid_y >= 0 and grid_y < 10:
		# Crear indicador visual del clic
		create_click_indicator(target_pos)
		
		if selected_action == "MOVE":
			handle_move(target_pos)
		elif selected_action == "ATTACK":
			handle_attack(target_pos)
	else:
		print("❌ Clic fuera del grid")

# NUEVA FUNCIÓN: Indicador visual de dónde se hizo clic
func create_click_indicator(pos: Vector2):
	var indicator = ColorRect.new()
	indicator.size = Vector2(grid_size - 4, grid_size - 4)
	indicator.position = pos - Vector2((grid_size - 4)/2, (grid_size - 4)/2)
	indicator.color = Color.YELLOW if selected_action == "ATTACK" else Color.CYAN
	indicator.modulate.a = 0.5
	effects_layer.add_child(indicator)
	
	# Hacer que desaparezca
	var tween = create_tween()
	tween.tween_property(indicator, "modulate:a", 0.0, 0.5)
	tween.tween_callback(indicator.queue_free)

func create_player():
	var player_node = CharacterBody2D.new()
	player_node.name = "Player"
	
	var animated_sprite = create_player_sprite()
	player_node.add_child(animated_sprite)
	
	create_health_bar(player_node, Color.CYAN)
	
	var turn_indicator = ColorRect.new()
	turn_indicator.size = Vector2(6, 6)
	turn_indicator.position = Vector2(-3, -25)
	turn_indicator.color = Color.YELLOW
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
		print("⚠️ Sprite del jugador no encontrado, usando fallback")
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
			print("✅ Encontrado sprite del jugador en:", path)
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
	
	print("❌ No se encontró sprite del jugador")
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
	
	create_health_bar(enemy_node, Color.ORANGE)
	
	var turn_indicator = ColorRect.new()
	turn_indicator.size = Vector2(6, 6)
	turn_indicator.position = Vector2(-3, -25)
	turn_indicator.color = Color.RED
	turn_indicator.name = "TurnIndicator"
	turn_indicator.visible = false
	enemy_node.add_child(turn_indicator)
	
	enemy_node.position = Vector2(12 * grid_size + grid_size/2, 5 * grid_size + grid_size/2)
	add_child(enemy_node)
	return enemy_node

func create_enemy_sprite():
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite2D"
	
	var sprite_frames = load_enemy_sprite_frames()
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idleFront")
		animated_sprite.scale = Vector2(1.0, 1.0)
		print("✅ Sprite del enemigo cargado")
	else:
		print("⚠️ Sprite del enemigo no encontrado, usando fallback")
		animated_sprite.queue_free()
		return create_fallback_enemy_sprite()
	
	return animated_sprite

func load_enemy_sprite_frames():
	var possible_paths = [
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

func create_health_bar(character: Node2D, bar_color: Color):
	var health_bg = ColorRect.new()
	health_bg.size = Vector2(30, 6)
	health_bg.position = Vector2(-15, -22)
	health_bg.color = Color(0.2, 0.2, 0.2)
	health_bg.name = "HealthBG"
	character.add_child(health_bg)
	
	var health_bar = ColorRect.new()
	health_bar.size = Vector2(28, 4)
	health_bar.position = Vector2(-14, -21)
	health_bar.color = bar_color
	health_bar.name = "HealthBar"
	character.add_child(health_bar)

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# PANEL PRINCIPAL - Posicionado para no interferir con el grid
	var main_panel = ColorRect.new()
	main_panel.size = Vector2(280, 160)
	main_panel.position = Vector2(10, 10)
	main_panel.color = Color(0, 0, 0, 0.85)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics en el panel
	ui_layer.add_child(main_panel)
	
	var panel_border = ColorRect.new()
	panel_border.size = Vector2(284, 164)
	panel_border.position = Vector2(8, 8)
	panel_border.color = Color(0.4, 0.4, 0.4)
	panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(panel_border)
	ui_layer.move_child(panel_border, 0)
	
	# LABELS
	turn_label = Label.new()
	turn_label.position = Vector2(20, 25)
	turn_label.add_theme_color_override("font_color", Color.WHITE)
	turn_label.add_theme_font_size_override("font_size", 18)
	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(turn_label)
	
	pa_label = Label.new()
	pa_label.position = Vector2(20, 50)
	pa_label.add_theme_color_override("font_color", Color.CYAN)
	pa_label.add_theme_font_size_override("font_size", 16)
	pa_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(pa_label)
	
	health_label = Label.new()
	health_label.position = Vector2(20, 75)
	health_label.add_theme_color_override("font_color", Color.GREEN)
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(health_label)
	
	action_label = Label.new()
	action_label.position = Vector2(20, 100)
	action_label.add_theme_color_override("font_color", Color.YELLOW)
	action_label.add_theme_font_size_override("font_size", 16)
	action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(action_label)
	
	end_turn_button = Button.new()
	end_turn_button.position = Vector2(20, 125)
	end_turn_button.size = Vector2(140, 35)
	end_turn_button.text = "Terminar Turno"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_layer.add_child(end_turn_button)
	
	# INSTRUCCIONES - Panel separado
	var instructions_panel = ColorRect.new()
	instructions_panel.size = Vector2(180, 100)
	instructions_panel.position = Vector2(490, 10)  # Fuera del área del grid
	instructions_panel.color = Color(0.2, 0.2, 0.2, 0.9)
	instructions_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(instructions_panel)
	
	var instructions_border = ColorRect.new()
	instructions_border.size = Vector2(184, 104)
	instructions_border.position = Vector2(488, 8)
	instructions_border.color = Color(0.5, 0.5, 0.5)
	instructions_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(instructions_border)
	ui_layer.move_child(instructions_border, 0)
	
	var instructions = Label.new()
	instructions.position = Vector2(500, 20)
	instructions.text = "🖱️ Clic Izq: Acción\n🖱️ Clic Der: Cambiar modo\n⚔️ Rango ataque: 1 casilla\n👟 Movimiento: Hasta 3 PA\n\n💡 Haz clic en el grid\npara mover/atacar"
	instructions.add_theme_color_override("font_color", Color.WHITE)
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(instructions)

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
	else:
		print("❌ Movimiento inválido - Distancia:", distance, "PA:", player_pa)

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
			print("❌ No hay enemigo en esa posición")
	else:
		print("❌ Ataque inválido - Distancia:", distance, "PA:", player_pa)

func animate_movement(character: Node2D, target_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(character, "position", target_pos, 0.3)
	tween.tween_callback(create_movement_trail.bind(character))
	await tween.finished

func create_movement_trail(character: Node2D):
	var trail = ColorRect.new()
	trail.size = Vector2(32, 32)
	trail.position = character.position - Vector2(16, 16)
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
	
	if grid_x >= 0 and grid_x < 15 and grid_y >= 0 and grid_y < 10:
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
	tween.tween_property(health_bar, "size:x", 28 * health_percent, 0.3)
	
	health_bar.color = Color.CYAN if health_percent > 0.5 else Color.YELLOW if health_percent > 0.25 else Color.RED

func update_enemy_health_bar():
	var health_bar = enemy.get_node("HealthBar")
	var health_percent = float(enemy_health) / 30.0
	
	var tween = create_tween()
	tween.tween_property(health_bar, "size:x", 28 * health_percent, 0.3)
	
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
	for i in range(10):
		var firework = ColorRect.new()
		firework.size = Vector2(4, 4)
		firework.position = Vector2(randf_range(100, 380), randf_range(50, 250))
		firework.color = Color(randf(), randf(), randf())
		effects_layer.add_child(firework)
		
		var tween = create_tween()
		tween.parallel().tween_property(firework, "scale", Vector2(3, 3), 1.0)
		tween.parallel().tween_property(firework, "modulate:a", 0.0, 1.0)
		tween.tween_callback(firework.queue_free)
		
		await get_tree().create_timer(0.1)

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
