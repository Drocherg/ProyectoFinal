extends Area2D

@export var cambiar_escena: String
@export var transition_name: String = "Cargando nueva área..."

# Referencia al manager de transiciones
var transition_manager: Node

func _ready():
	# Obtener referencia al manager de transiciones
	transition_manager = get_node("/root/SceneTransitionManager")
	if not transition_manager:
		print("⚠️ SceneTransitionManager no encontrado, usando cambio directo")

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		change_scene()

func change_scene():
	if transition_manager:
		# Usar el sistema de carga con pantalla
		print("🚪 Cambiando escena con pantalla de carga: ", cambiar_escena)
		transition_manager.transition_to_scene(cambiar_escena)
	else:
		# Fallback al método tradicional
		print("🚪 Cambiando escena directamente: ", cambiar_escena)
		get_tree().change_scene_to_file(cambiar_escena)

# Función para cambio manual desde código
func trigger_scene_change():
	change_scene()
