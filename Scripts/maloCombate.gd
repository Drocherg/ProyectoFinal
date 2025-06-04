extends CharacterBody2D

@export var tile_size: int = 32
@export var speed: float = 150.0
@export var max_pa: int = 3
@export var max_health: int = 30
@export var attack_damage: int = 10
@export var attack_range: int = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int
var pa: int
var combate
var is_taking_turn = false

signal health_changed(new_health: int)

func _ready():
	health = max_health
	pa = max_pa
	update_health_bar()

func start_turn():
	pa = max_pa
	is_taking_turn = true

func end_turn():
	is_taking_turn = false

func take_turn():
	if not is_taking_turn or pa <= 0:
		combate.end_current_turn()
		return
	
	var player = combate.player
	if not player:
		combate.end_current_turn()
		return

	var distance = combate.get_distance_in_tiles(global_position, player.global_position)
	
	# Decidir acción basada en distancia y PA
	if distance <= attack_range and pa >= 1:
		# Atacar si está en rango
		perform_attack(player)
	elif pa >= distance and distance > attack_range:
		# Moverse hacia el jugador si puede alcanzarlo
		move_towards_player()
	elif pa > 0:
		# Moverse lo más cerca posible
		move_towards_player()
	else:
		# Sin PA, terminar turno
		combate.end_current_turn()
		return
	
	# Continuar turno después de un delay
	await get_tree().create_timer(1.5).timeout
	take_turn()

func perform_attack(target):
	pa -= 1
	print("👹 Enemigo ataca! Daño:", attack_damage, "PA restante:", pa)
	target.take_damage(attack_damage)
	combate.update_ui()

func move_towards_player():
	if pa <= 0:
		return
	
	var player = combate.player
	var direction = (player.global_position - global_position).normalized()
	
	# Determinar movimiento en grid (solo horizontal o vertical)
	var move_vector = Vector2.ZERO
	if abs(direction.x) > abs(direction.y):
		move_vector.x = sign(direction.x) * tile_size
	else:
		move_vector.y = sign(direction.y) * tile_size
	
	var new_position = global_position + move_vector
	new_position = combate.snap_to_grid(new_position)
	
	# Verificar que la nueva posición no esté ocupada
	if not combate.is_position_occupied(new_position):
		global_position = new_position
		pa -= 1
		print("👹 Enemigo se mueve. PA restante:", pa)
		combate.update_ui()
		update_animation(move_vector.normalized())
	else:
		print("👹 Enemigo no puede moverse, posición ocupada")
		pa = 0  # Terminar turno si no puede moverse

func update_animation(direction: Vector2):
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

func take_damage(damage: int):
	health -= damage
	health = max(0, health)
	print("💔 Enemigo recibe", damage, "de daño. Vida:", health)
	update_health_bar()
	health_changed.emit(health)

func update_health_bar():
	if health_bar:
		health_bar.value = (float(health) / float(max_health)) * 100
