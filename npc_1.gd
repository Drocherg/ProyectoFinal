extends CharacterBody2D

@export var speed: float = 30.0  # Velocidad de movimiento
@export var idle_time_range: Vector2 = Vector2(2.0, 4.0)  # Tiempo de espera al estar inactivo
@export var move_time_range: Vector2 = Vector2(2.0, 5.0)  # Tiempo de movimiento

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Estados posibles de la IA
enum State { IDLE, MOVING }
var current_state: State = State.IDLE

# Temporizador interno para cambiar de estado
var state_timer: float = 0.0

# Dirección de movimiento actual
var current_direction: Vector2 = Vector2.ZERO

func _ready():
	# Elegir el primer estado y tiempo inicial
	change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	# Reducir el temporizador del estado actual
	state_timer -= delta
	if state_timer <= 0.0:
		# Cambiar entre moverse y estar inactivo
		if current_state == State.IDLE:
			change_state(State.MOVING)
		else:
			change_state(State.IDLE)

	if current_state == State.MOVING:
		# Aplicar movimiento solo en cuatro direcciones (sin diagonal)
		velocity = current_direction * speed
		play_walk_animation()
	else:
		# Detener movimiento cuando está inactivo
		velocity = Vector2.ZERO
		play_idle_animation()

	# Aplicar movimiento
	move_and_slide()

func change_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.IDLE:
		# Detener la IA y establecer un tiempo aleatorio para la inactividad
		state_timer = randf_range(idle_time_range.x, idle_time_range.y)
		current_direction = Vector2.ZERO  # No hay movimiento
	elif new_state == State.MOVING:
		# Elegir una dirección aleatoria (arriba, abajo, izquierda, derecha)
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		current_direction = directions[randi() % directions.size()]
		state_timer = randf_range(move_time_range.x, move_time_range.y)

func play_walk_animation():
	# Reproducir animaciones basadas en la dirección de movimiento
	if current_direction == Vector2.UP:
		animated_sprite.play("Npc1WalkUp")
	elif current_direction == Vector2.DOWN:
		animated_sprite.play("Npc1WalkDown")
	elif current_direction == Vector2.LEFT:
		animated_sprite.flip_h = false
		animated_sprite.play("Npc1WalkLeft")
	elif current_direction == Vector2.RIGHT:
		animated_sprite.flip_h = true
		animated_sprite.play("Npc1WalkRight")

func play_idle_animation():
	# Reproducir animación de estar inactivo
	if current_direction == Vector2.UP:
		animated_sprite.play("Npc1IdleBack")
	elif current_direction == Vector2.DOWN or current_direction == Vector2.ZERO:
		animated_sprite.play("Npc1IdleFront")
	elif current_direction == Vector2.LEFT:
		animated_sprite.flip_h = false
		animated_sprite.play("Npc1IdleLeft")
	elif current_direction == Vector2.RIGHT:
		animated_sprite.flip_h = true
		animated_sprite.play("Npc1IdleRight")
