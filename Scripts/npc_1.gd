extends CharacterBody2D

@export var speed: float = 30.0
@export var idle_time_range: Vector2 = Vector2(2.0, 4.0)
@export var move_time_range: Vector2 = Vector2(2.0, 5.0)
@export var dialogue_id: String = "npc_merchant"
@export var interaction_radius: float = 50.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum State { IDLE, MOVING, TALKING }
var current_state: State = State.IDLE
var state_timer: float = 0.0
var current_direction: Vector2 = Vector2.ZERO
var player_in_range: bool = false
var player_reference: Node2D = null

# UI de interacción simple
var interaction_label: Label = null

func _ready():
	setup_interaction_detection()
	change_state(State.IDLE)
	create_interaction_label()
	
	# Conectar con DialogueManager de forma segura
	call_deferred("connect_to_dialogue_manager")

func connect_to_dialogue_manager():
	if has_node("/root/DialogueManager"):
		var dialogue_manager = get_node("/root/DialogueManager")
		if dialogue_manager.has_signal("dialogue_started"):
			dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		if dialogue_manager.has_signal("dialogue_ended"):
			dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
		print("✅ NPC conectado a DialogueManager")
	else:
		print("❌ DialogueManager no encontrado")

func setup_interaction_detection():
	# Verificar si ya existe un Area2D
	var existing_area = get_node_or_null("InteractionArea")
	if existing_area:
		existing_area.queue_free()
	
	# Crear área de detección
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0  # No colisiona con nada
	area.collision_mask = 1   # Detecta layer 1 (jugador)
	add_child(area)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_radius
	collision.shape = shape
	area.add_child(collision)
	
	# Conectar señales con verificación
	if not area.body_entered.is_connected(_on_player_entered):
		area.body_entered.connect(_on_player_entered)
	if not area.body_exited.is_connected(_on_player_exited):
		area.body_exited.connect(_on_player_exited)
	
	print("✅ Área de interacción creada para NPC")

func create_interaction_label():
	interaction_label = Label.new()
	interaction_label.text = "Presiona E para hablar"
	interaction_label.position = Vector2(-50, -60)
	interaction_label.add_theme_color_override("font_color", Color.YELLOW)
	interaction_label.add_theme_font_size_override("font_size", 12)
	interaction_label.hide()
	add_child(interaction_label)

func _physics_process(delta: float) -> void:
	if current_state == State.TALKING:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# IA de movimiento normal
	state_timer -= delta
	if state_timer <= 0.0:
		if current_state == State.IDLE:
			change_state(State.MOVING)
		else:
			change_state(State.IDLE)

	if current_state == State.MOVING:
		velocity = current_direction * speed
		play_walk_animation()
	else:
		velocity = Vector2.ZERO
		play_idle_animation()

	move_and_slide()

func _input(event):
	if event.is_action_pressed("interact") and player_in_range and current_state != State.TALKING:
		start_dialogue()

func start_dialogue():
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		if not dialogue_manager.is_dialogue_active:
			print("🗣️ Iniciando conversación con", dialogue_id)
			change_state(State.TALKING)
			dialogue_manager.start_dialogue(dialogue_id)
	else:
		print("❌ DialogueManager no encontrado al intentar iniciar diálogo")

func _on_player_entered(body):
	if body.has_method("_physics_process") and body.name.to_lower().contains("player"):
		player_in_range = true
		player_reference = body
		if interaction_label:
			interaction_label.show()
		print("👋 Jugador cerca del NPC")

func _on_player_exited(body):
	if body.has_method("_physics_process") and body.name.to_lower().contains("player"):
		player_in_range = false
		player_reference = null
		if interaction_label:
			interaction_label.hide()
		print("🚶 Jugador se alejó del NPC")

func _on_dialogue_started():
	change_state(State.TALKING)
	if interaction_label:
		interaction_label.hide()

func _on_dialogue_ended():
	change_state(State.IDLE)
	if player_in_range and interaction_label:
		interaction_label.show()

func change_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.IDLE:
		state_timer = randf_range(idle_time_range.x, idle_time_range.y)
		current_direction = Vector2.ZERO
	elif new_state == State.MOVING:
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		current_direction = directions[randi() % directions.size()]
		state_timer = randf_range(move_time_range.x, move_time_range.y)

func play_walk_animation():
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
