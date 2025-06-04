# === ENEMIGO ACTUALIZADO (malo fuera de combate) ===
extends CharacterBody2D

@export var wander_speed: float = 20.0
@export var chase_speed: float = 100.0
@export var detection_radius: float = 80.0
@export var wander_time_range: Vector2 = Vector2(2, 5)
@export var wander_radius: float = 50.0
@export var enemy_type: String = "basic"
@export var level: int = 1
@export var health: int = 30
@export var max_health: int = 30

# NUEVO: ID único para este enemigo
@export var unique_id: String = ""

@onready var player: Node2D = get_node_or_null("../Player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_area: Area2D = $CollisionArea

var wander_timer: float = 0.0
var target_position: Vector2
var spawn_position: Vector2
var is_chasing: bool = false
var battle_started: bool = false
var is_defeated: bool = false

func _ready():
	# NUEVO: Generar ID único si no está asignado
	if unique_id == "":
		unique_id = "enemy_" + str(get_instance_id()) + "_" + str(randi())
	
	print("🆔 Enemigo inicializado con ID:", unique_id)
	
	# NUEVO: Verificar si este enemigo ya fue derrotado
	if GameManager and GameManager.is_enemy_defeated(unique_id):
		print("💀 Enemigo", unique_id, "ya fue derrotado, ocultando...")
		hide_defeated_enemy()
		return
	
	spawn_position = global_position
	target_position = global_position
	
	if collision_area:
		collision_area.body_entered.connect(_on_collision_area_entered)
		print("✅ Área de colisión configurada para", enemy_type)
	else:
		print("❌ No se encontró CollisionArea en", enemy_type)
	
	choose_new_wander_direction()

# NUEVO: Función para ocultar enemigo derrotado
func hide_defeated_enemy():
	is_defeated = true
	visible = false
	set_physics_process(false)
	set_process(false)
	
	# Desactivar colisiones
	if collision_area:
		collision_area.set_deferred("monitoring", false)
		collision_area.set_deferred("monitorable", false)
	
	# Desactivar collision shape del CharacterBody2D
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	print("👻 Enemigo", unique_id, "completamente desactivado")

func _physics_process(delta: float) -> void:
	# NUEVO: No procesar si está derrotado
	if is_defeated:
		return
		
	if not is_instance_valid(player) or battle_started:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= detection_radius:
		if not is_chasing:
			start_chase()
		target_position = player.global_position
	else:
		if is_chasing:
			stop_chase()

	if not is_chasing:
		wander_timer -= delta
		if wander_timer <= 0:
			choose_new_wander_direction()

	move_towards_target()

	if distance_to_player < 20 and not battle_started:
		print("🔥 Iniciando combate por proximidad...")
		initiate_combat()

func move_towards_target():
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < 5.0 and not is_chasing:
		choose_new_wander_direction()
		return
	
	var direction = (target_position - global_position).normalized()
	var current_speed = chase_speed if is_chasing else wander_speed
	velocity = direction * current_speed
	
	move_and_slide()
	update_animation(direction)

func choose_new_wander_direction():
	wander_timer = randf_range(wander_time_range.x, wander_time_range.y)
	var random_angle = randf_range(0, 2 * PI)
	var random_distance = randf_range(20, wander_radius)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	target_position = spawn_position + offset

func start_chase():
	is_chasing = true
	print("👹 ", enemy_type, " comienza a perseguir")

func stop_chase():
	is_chasing = false
	choose_new_wander_direction()
	print("👹 ", enemy_type, " deja de perseguir")

func update_animation(direction: Vector2):
	if not sprite:
		return
		
	var base_animation = "Run" if is_chasing else "Walk"

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play(base_animation + "Right")
			sprite.flip_h = true
		else:
			sprite.play(base_animation + "Left")
			sprite.flip_h = false
	else:
		sprite.flip_h = false
		if direction.y > 0:
			sprite.play(base_animation + "Down")
		else:
			sprite.play(base_animation + "Up")

func initiate_combat():
	if battle_started or is_defeated:
		return

	battle_started = true
	print("⚔️ INICIANDO COMBATE CON ", enemy_type.to_upper())
	
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	if not GameManager:
		print("❌ Error: GameManager no encontrado")
		return
	
	print("🎬 Verificando ruta de combate...")
	
	# Verificar que la ruta existe antes de cambiar
	if ResourceLoader.exists("res://Escenas/combate.tscn"):
		print("✅ Ruta de combate encontrada")
		await get_tree().create_timer(0.2).timeout
		GameManager.start_combat(player, self)
	else:
		print("❌ Error: No se encontró res://Escenas/combate.tscn")
		print("🔍 Verificando rutas alternativas...")
		
		# Intentar rutas alternativas
		var alternative_paths = [
			"res://Scenes/CombatScene.tscn",
			"res://escenas/combate.tscn",
			"res://Escenas/Combate.tscn"
		]
		
		var found = false
		for path in alternative_paths:
			if ResourceLoader.exists(path):
				print("✅ Ruta alternativa encontrada:", path)
				await get_tree().create_timer(0.2).timeout
				GameManager.change_scene(path)
				found = true
				break
		
		if not found:
			print("❌ No se encontró ninguna escena de combate")

func _on_collision_area_entered(body):
	print("🔍 Colisión detectada con:", body.name)
	if body.name == "Player" and not battle_started and not is_defeated:
		print("🎯 ¡Jugador detectado!")
		initiate_combat()

# NUEVO: Función para marcar como derrotado (llamada desde GameManager si es necesario)
func mark_as_defeated():
	print("💀 Marcando enemigo", unique_id, "como derrotado")
	hide_defeated_enemy()
