extends Node

# Cambia a una nueva escena
func change_scene(scene_path: String) -> void:
	var new_scene = load(scene_path)
	if new_scene:
		print("Cambiando a la escena:", scene_path)
		get_tree().change_scene_to(new_scene)
	else:
		print("Error: No se pudo cargar la escena:", scene_path)
