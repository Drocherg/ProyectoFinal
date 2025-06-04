extends CharacterBody2D

@export var tile_size: int = 32
@export var speed: float = 200.0
@export var max_pa: int = 3
@export var max_health: int = 50
@export var attack_damage: int = 15
@export var attack_range: int = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int
var pa: int
var is_moving = false
var my_turn = false
var combate
var selected_action = "MOVE"  # MOVE, ATTACK

signal health_changed(new_health: int)
signal action_completed()

func _ready():
	health = max_health
	pa = max_pa
	
	# Configurar NavigationAgent2D de forma segura
	if agent:
		agent.max_speed = speed
		agent.path_desired_distance = 2.0
		agent.target_desired_distance = 1.0
	
	update_health_bar()
	print("🎮 Jugador de combate inicializado - Vida:", health, "PA:", pa)

func _physics_process(delta: float) -> void:
	if is_moving:
		move_to_target()

func _input(event):
	if not my_turn or is_moving:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click()

func handle_left_click():
	var target_pos = get_global_mouse_position()
	
	if not combate:
		print("❌ No hay referencia a combate")
		return
		
	var grid_target = combate.snap_to_grid(target_pos)
	
	if selected_action == "MOVE":
		attempt_move(grid_target)
	elif selected_action == "ATTACK":
		attempt_attack(grid_target)

func handle_right_click():
	if selected_action == "MOVE":
		selected_action = "ATTACK"
		print("🗡️ Modo: Ataque")
	else:
		selected_action = "MOVE"
		print("👟 Modo: Movimiento")

func attempt_move(target_pos: Vector2):
	if pa <= 0:
		print("❌ Sin PA para moverse")
		return
		
	if combate.is_position_occupied(target_pos):
		print("❌ Posición ocupada")
		return
	
	var distance = combate.get_distance_in_tiles(global_position, target_pos)
	if distance > pa:
		print("❌ Muy lejos para llegar con PA actual")
		return
	
	if agent:
		agent.set_target_position(target_pos)
		if agent.is_target_reachable():
			is_moving = true
			pa -= distance
			print("🚶 Moviéndose... PA restante:", pa)
			if combate:
				combate.update_ui()
		else:
			print("❌ Objetivo no alcanzable")

func attempt_attack(target_pos: Vector2):
	if pa <= 0:
		print("❌ Sin PA para atacar")
		return
	
	var distance = combate.get_distance_in_tiles(global_position, target_pos)
	if distance > attack_range:
		print("❌ Objetivo fuera de rango de ataque")
		return
	
	# Verificar si hay un enemigo en esa posición
	if combate.enemy and combate.enemy.global_position.distance_to(target_pos) < tile_size / 2:
		perform_attack(combate.enemy)
	else:
		print("❌ No hay enemigo en esa posición")

func perform_attack(target):
	pa -= 1
	print("⚔️ Atacando! Daño:", attack_damage, "PA restante:", pa)
	
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	if combate:
		combate.update_ui()
	
	action_completed.emit()

func move_to_target():
	if not agent:
		is_moving = false
		return
		
	if agent.is_navigation_finished():
		is_moving = false
		velocity = Vector2.ZERO
		if combate:
			global_position = combate.snap_to_grid(global_position)
		action_completed.emit()
		return

	var next_path_pos = agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	update_animation(direction)

func update_animation(direction: Vector2):
	if not animated_sprite:
		return
		
	if direction.length() == 0:
		animated_sprite.play("idleFront")
		return

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.flip_h = true
			animated_sprite.play("walkRight")
		else:
			animated_sprite.flip_h = false
			animated_sprite.play("walkLeft")
	else:
		if direction.y > 0:
			animated_sprite.play("walkFront")
		else:
			animated_sprite.play("walkBack")

func start_turn():
	my_turn = true
	pa = max_pa
	selected_action = "MOVE"
	print("🎮 Turno iniciado - PA:", pa)

func end_turn():
	my_turn = false
	print("🔚 Turno terminado")

func take_damage(damage: int):
	health -= damage
	health = max(0, health)
	print("💔 Jugador recibe", damage, "de daño. Vida:", health)
	update_health_bar()
	health_changed.emit(health)

func update_health_bar():
	if health_bar:
		health_bar.value = (float(health) / float(max_health)) * 100
