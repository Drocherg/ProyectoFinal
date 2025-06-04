extends Node

# Función corregida para cambiar escenas
func change_scene(scene_path: String) -> void:
	print("🔄 GameManager: Cambiando a escena:", scene_path)
	
	# Verificar que la escena existe
	if not ResourceLoader.exists(scene_path):
		print("❌ Error: La escena no existe:", scene_path)
		return
	
	# Usar el método nativo de Godot que maneja correctamente el cambio
	get_tree().change_scene_to_file(scene_path)
	print("✅ Escena cambiada exitosamente a:", scene_path)

# Datos del jugador para transferir entre escenas
var player_data = {
	"level": 1,
	"health": 50,
	"max_health": 50,
	"experience": 0,
	"position": Vector2.ZERO,
	"last_scene_path": ""
}

# Datos del enemigo para el combate
var enemy_data = {
	"type": "basic",
	"health": 30,
	"max_health": 30,
	"level": 1,
	"unique_id": ""  # NUEVO: ID único del enemigo
}

# NUEVO: Lista de enemigos derrotados en la sesión actual
var defeated_enemies = []

# Resultado del combate
var combat_result = ""

func save_player_state(player_world):
	if not player_world:
		print("❌ No se pudo guardar estado del jugador: objeto nulo")
		return
		
	player_data.position = player_world.global_position
	print("💾 Guardando posición del jugador:", player_data.position)
	
	if "health" in player_world:
		player_data.health = player_world.health
	if "max_health" in player_world:
		player_data.max_health = player_world.max_health
	if "level" in player_world:
		player_data.level = player_world.level
	if "experience" in player_world:
		player_data.experience = player_world.experience

func save_enemy_state(enemy_world):
	if not enemy_world:
		print("❌ No se pudo guardar estado del enemigo: objeto nulo")
		return
	
	# NUEVO: Guardar ID único del enemigo
	if "unique_id" in enemy_world:
		enemy_data.unique_id = enemy_world.unique_id
	else:
		enemy_data.unique_id = "enemy_" + str(enemy_world.get_instance_id())
		
	if "enemy_type" in enemy_world:
		enemy_data.type = enemy_world.enemy_type
	else:
		enemy_data.type = "basic"
		
	if "level" in enemy_world:
		enemy_data.level = enemy_world.level
	else:
		enemy_data.level = 1
		
	if "health" in enemy_world:
		enemy_data.health = enemy_world.health
	if "max_health" in enemy_world:
		enemy_data.max_health = enemy_world.max_health
	
	print("💾 Guardando datos del enemigo:", enemy_data)

func start_combat(player_world, enemy_world):
	print("⚔️ GameManager: Iniciando combate...")
	
	if not player_world:
		print("❌ Error: player_world es null")
		return
	
	if not enemy_world:
		print("❌ Error: enemy_world es null")
		return
	
	save_player_state(player_world)
	save_enemy_state(enemy_world)
	
	# Guardar la escena actual
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path != "":
		player_data.last_scene_path = current_scene.scene_file_path
		print("💾 Escena actual guardada:", player_data.last_scene_path)
	else:
		print("⚠️ No se pudo guardar la escena actual")
	
	print("📊 Datos del jugador:", player_data)
	print("📊 Datos del enemigo:", enemy_data)
	
	# RUTA CORREGIDA - usar la ruta correcta de tu escena de combate
	change_scene("res://Escenas/combate.tscn")

func return_to_world():
	print("🏠 GameManager: Regresando al mundo...")
	print("🎯 Resultado del combate:", combat_result)
	
	# NUEVO: Si ganó el combate, marcar enemigo como derrotado
	if combat_result == "victory" and enemy_data.unique_id != "":
		if not enemy_data.unique_id in defeated_enemies:
			defeated_enemies.append(enemy_data.unique_id)
			print("💀 Enemigo", enemy_data.unique_id, "marcado como derrotado")
	
	if player_data.last_scene_path != "":
		change_scene(player_data.last_scene_path)
	else:
		print("⚠️ No hay escena guardada, usando escena por defecto")
		change_scene("res://Escenas/mundo.tscn")

func apply_combat_result():
	match combat_result:
		"victory":
			print("🎉 Aplicando recompensas de victoria...")
			player_data.experience += 10
		"defeat":
			print("💀 Aplicando penalización por derrota...")
			player_data.health = max(1, player_data.health - 10)

# NUEVO: Función para verificar si un enemigo está derrotado
func is_enemy_defeated(enemy_id: String) -> bool:
	return enemy_id in defeated_enemies

# NUEVO: Función para resetear enemigos derrotados (opcional)
func reset_defeated_enemies():
	defeated_enemies.clear()
	print("🔄 Lista de enemigos derrotados limpiada")

func reset_game():
	player_data = {
		"level": 1,
		"health": 50,
		"max_health": 50,
		"experience": 0,
		"position": Vector2.ZERO,
		"last_scene_path": ""
	}
	
	enemy_data = {
		"type": "basic",
		"health": 30,
		"max_health": 30,
		"level": 1,
		"unique_id": ""
	}
	
	# NUEVO: Limpiar enemigos derrotados al resetear
	defeated_enemies.clear()
	combat_result = ""
	print("🔄 Juego reiniciado")

# Funciones getter
func get_player_health() -> int:
	return player_data.health

func get_player_max_health() -> int:
	return player_data.max_health

func get_player_level() -> int:
	return player_data.level

func get_player_experience() -> int:
	return player_data.experience

func debug_gamemanager():
	print("=== DEBUG GAMEMANAGER ===")
	print("Player data:", player_data)
	print("Enemy data:", enemy_data)
	print("Combat result:", combat_result)
	print("Defeated enemies:", defeated_enemies)  # NUEVO
	print("Current scene:", get_tree().current_scene)
	print("Current scene path:", get_tree().current_scene.scene_file_path if get_tree().current_scene else "null")
	print("========================")
