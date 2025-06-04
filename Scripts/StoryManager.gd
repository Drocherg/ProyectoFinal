extends Node

# Singleton para manejar el progreso de la historia
signal story_event_triggered(event_name: String)
signal quest_completed(quest_name: String)
signal character_relationship_changed(character: String, relationship: int)

var story_progress: Dictionary = {}
var character_relationships: Dictionary = {}
var completed_quests: Array[String] = []
var active_quests: Array[String] = []

func _ready():
	# Inicializar relaciones con personajes
	character_relationships = {
		"merchant_aldric": 0,  # -100 a 100
		"captain_marcus": 0,
		"guard_patrol": 0
	}
	
	# Conectar con DialogueManager para escuchar decisiones
	if DialogueManager:
		DialogueManager.choice_made.connect(_on_dialogue_choice_made)

func _on_dialogue_choice_made(choice_text: String, consequence: String):
	# Procesar consecuencias de diálogos que afectan la historia
	match consequence:
		"quest_forest_accepted":
			add_quest("forest_investigation")
			change_relationship("merchant_aldric", 10)
			trigger_story_event("forest_quest_started")
		
		"quest_forest_refused":
			change_relationship("merchant_aldric", -5)
			trigger_story_event("forest_quest_refused")
		
		"patrol_mission_accepted":
			add_quest("find_lost_patrol")
			change_relationship("captain_marcus", 15)
			trigger_story_event("patrol_mission_started")
		
		"guard_hostile":
			change_relationship("captain_marcus", -20)
			change_relationship("guard_patrol", -10)
			trigger_story_event("guards_hostile")

func add_quest(quest_name: String):
	if quest_name not in active_quests:
		active_quests.append(quest_name)
		print("📜 Nueva misión:", quest_name)

func complete_quest(quest_name: String):
	if quest_name in active_quests:
		active_quests.erase(quest_name)
		completed_quests.append(quest_name)
		quest_completed.emit(quest_name)
		print("✅ Misión completada:", quest_name)

func change_relationship(character: String, change: int):
	if character in character_relationships:
		character_relationships[character] += change
		character_relationships[character] = clamp(character_relationships[character], -100, 100)
		character_relationship_changed.emit(character, character_relationships[character])
		print("💭 Relación con", character, ":", character_relationships[character])

func trigger_story_event(event_name: String):
	story_progress[event_name] = true
	story_event_triggered.emit(event_name)
	print("🎭 Evento de historia:", event_name)

func get_relationship(character: String) -> int:
	return character_relationships.get(character, 0)

func has_completed_quest(quest_name: String) -> bool:
	return quest_name in completed_quests

func has_active_quest(quest_name: String) -> bool:
	return quest_name in active_quests

func get_story_flag(flag_name: String) -> bool:
	return story_progress.get(flag_name, false)
