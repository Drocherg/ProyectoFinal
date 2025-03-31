extends CharacterBody2D

@export var speed: float = 50.0  # Velocidad de caminar del protagonista
@export var run_speed: float = 120.0  # Velocidad al correr

# Referencia al AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO

	# Leer la entrada del usuario para movimiento (teclas de dirección)
	if Input.is_action_pressed("move_right"):
		input_vector.x = 1
	elif Input.is_action_pressed("move_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("move_down"):
		input_vector.y = 1
	elif Input.is_action_pressed("move_up"):
		input_vector.y = -1

	# Determinar la velocidad dependiendo si el jugador está corriendo
	var current_speed = speed
	if Input.is_action_pressed("move_run"):  # Si el jugador está manteniendo SHIFT
		current_speed = run_speed

	# Aplicar velocidad al movimiento
	velocity = input_vector * current_speed

	# Verificar si el AnimatedSprite2D está presente y reproducir las animaciones correspondientes
	if animated_sprite != null:
		if input_vector != Vector2.ZERO:
			# Determinar animación de caminar o correr
			if Input.is_action_pressed("move_run"):
				# Animaciones de correr
				if input_vector.y > 0:
					animated_sprite.play("runFront")
				elif input_vector.y < 0:
					animated_sprite.play("runBack")
				elif input_vector.x > 0:
					animated_sprite.flip_h = true  # Voltear sprite horizontalmente para la derecha
					animated_sprite.play("runRight")
				elif input_vector.x < 0:
					animated_sprite.flip_h = false  # No voltear sprite para la izquierda
					animated_sprite.play("runLeft")
			else:
				# Animaciones de caminar
				if input_vector.y > 0:
					animated_sprite.play("walkFront")
				elif input_vector.y < 0:
					animated_sprite.play("walkBack")
				elif input_vector.x > 0:
					animated_sprite.flip_h = true
					animated_sprite.play("walkRight")
				elif input_vector.x < 0:
					animated_sprite.flip_h = false
					animated_sprite.play("walkLeft")
		else:
			# Animación cuando el jugador está quieto (idle)
			if input_vector.y > 0:
				animated_sprite.play("idleFront")
			elif input_vector.y < 0:
				animated_sprite.play("idleBack")
			elif input_vector.x > 0:
				animated_sprite.play("idleRight")
			elif input_vector.x < 0:
				animated_sprite.play("idleLeft")
			else:
				animated_sprite.play("idleFront")  # Default idle animación (puedes ajustarla según tu preferencia)
	else:
		print("AnimatedSprite2D no encontrado")  # Mensaje de error si no se encuentra el AnimatedSprite2D

	# Aplicar movimiento
	move_and_slide()
