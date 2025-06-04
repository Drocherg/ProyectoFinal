extends Area2D

@export var cambiar_escena: String

func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		change_escene()

func change_escene():
	get_tree().change_scene_to_file(cambiar_escena)
