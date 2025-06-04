# Helper para transiciones limpias - opcional
extends Node

# Función para cambio de escena con efecto visual simple
static func transition_to_scene(scene_path: String, transition_time: float = 0.5):
	var tree = Engine.get_main_loop()
	
	# Crear overlay negro
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.size = Vector2(1920, 1080)  # Tamaño grande para cubrir toda la pantalla
	overlay.position = Vector2.ZERO
	overlay.modulate.a = 0.0
	
	# Agregar al viewport actual
	var current_scene = tree.current_scene
	if current_scene:
		current_scene.add_child(overlay)
		
		# Fade in
		var tween = tree.create_tween()
		tween.tween_property(overlay, "modulate:a", 1.0, transition_time * 0.5)
		await tween.finished
	
	# Cambiar escena
	tree.change_scene_to_file(scene_path)
	
	# El overlay se eliminará automáticamente con la escena anterior

# Uso alternativo en el enemigo:
# SceneTransitionHelper.transition_to_scene("res://Scenes/CombatScene.tscn")
