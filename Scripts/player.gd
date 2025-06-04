extends CharacterBody2D

@export var speed: float = 50.0
@export var run_speed: float = 120.0
@export var max_health: int = 50

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var level: int = 1
var experience: int = 0
var last_direction: Vector2 = Vector2(0, 1)

# Estadísticas del equipamiento
var equipment_stats = {
	"attack": 0,
	"defense": 0,
	"health": 0
}

func _ready():
	# Cargar datos del GameManager
	health = GameManager.get_player_health()
	max_health = GameManager.get_player_max_health()
	level = GameManager.get_player_level()
	experience = GameManager.get_player_experience()
	
	# Cargar estadísticas del equipamiento
	load_equipment_stats()
	
	# Si venimos de combate, restaurar posición
	if GameManager.player_data.position != Vector2.ZERO:
		global_position = GameManager.player_data.position
	
	handle_combat_result()

func load_equipment_stats():
	# Obtener estadísticas del InventoryManager
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager:
		equipment_stats = inventory_manager.get_equipped_stats()
		
		# Aplicar bonificación de salud al máximo de vida
		max_health = 50 + equipment_stats.get("health", 0)
		
		# Actualizar datos en GameManager
		GameManager.player_data.max_health = max_health
		GameManager.player_data.equipment_stats = equipment_stats
		
		print("📊 Estadísticas de equipamiento cargadas:")
		print("  ⚔️ Ataque: ", equipment_stats.get("attack", 0))
		print("  🛡️ Defensa: ", equipment_stats.get("defense", 0))
		print("  ❤️ Salud Extra: ", equipment_stats.get("health", 0))
		print("  💚 Vida Máxima Total: ", max_health)

func get_total_attack() -> int:
	return 10 + equipment_stats.get("attack", 0)  # Ataque base + equipamiento

func get_total_defense() -> int:
	return equipment_stats.get("defense", 0)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vector.x = 1
	elif Input.is_action_pressed("move_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("move_down"):
		input_vector.y = 1
	elif Input.is_action_pressed("move_up"):
		input_vector.y = -1

	var current_speed = speed
	if Input.is_action_pressed("move_run"):
		current_speed = run_speed

	velocity = input_vector * current_speed
	move_and_slide()

	update_animation(input_vector, Input.is_action_pressed("move_run"))
	
	if input_vector != Vector2.ZERO:
		last_direction = input_vector

func update_animation(input_vector: Vector2, is_running: bool):
	if animated_sprite == null:
		print("AnimatedSprite2D no encontrado")
		return

	if input_vector != Vector2.ZERO:
		var animation_prefix = "run" if is_running else "walk"
		
		if input_vector.y > 0:
			animated_sprite.play(animation_prefix + "Front")
		elif input_vector.y < 0:
			animated_sprite.play(animation_prefix + "Back")
		elif input_vector.x > 0:
			animated_sprite.flip_h = true
			animated_sprite.play(animation_prefix + "Right")
		elif input_vector.x < 0:
			animated_sprite.flip_h = false
			animated_sprite.play(animation_prefix + "Left")
	else:
		if last_direction.y > 0:
			animated_sprite.play("idleFront")
		elif last_direction.y < 0:
			animated_sprite.play("idleBack")
		elif last_direction.x > 0:
			animated_sprite.play("idleRight")
		elif last_direction.x < 0:
			animated_sprite.play("idleLeft")
		else:
			animated_sprite.play("idleFront")

func take_damage(damage: int):
	# Aplicar defensa del equipamiento
	var defense = get_total_defense()
	var final_damage = max(1, damage - defense)  # Mínimo 1 de daño
	
	health -= final_damage
	health = max(0, health)
	
	# Actualizar datos en GameManager
	GameManager.player_data.health = health
	
	print("🛡️ Daño recibido: ", damage, " - Defensa: ", defense, " = ", final_damage)
	
	if health <= 0:
		die()

func heal(amount: int):
	health += amount
	health = min(max_health, health)
	
	# Actualizar datos en GameManager
	GameManager.player_data.health = health


func die():
	print("💀 El jugador ha muerto")
	GameManager.reset_game()
	GameManager.change_scene("res://Scenes/WorldScene.tscn")

func handle_combat_result():
	# Aplicar resultado del combate usando GameManager
	GameManager.apply_combat_result()
	
	# Actualizar stats locales
	health = GameManager.get_player_health()
	level = GameManager.get_player_level()
	experience = GameManager.get_player_experience()
	
	# Recargar estadísticas del equipamiento
	load_equipment_stats()
	

func gain_experience(amount: int):
	experience += amount
	GameManager.player_data.experience = experience
	print("✨ Ganaste", amount, "puntos de experiencia. Total:", experience)

# Función para actualizar estadísticas cuando cambia el equipamiento
func refresh_equipment_stats():
	load_equipment_stats()
