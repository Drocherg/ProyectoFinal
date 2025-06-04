extends Area2D  # Esto es para el área donde el jugador va a entrar

@export var teleport_position: Vector2  # Coordenadas donde se teletransportará el jugador

# Cuando el jugador entra en el área de colisión, lo teletransportamos
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":  # Comprobamos si el cuerpo que colisiona es el Player
		teleport(body)  # Llamamos a la función de teletransporte

# Función que teletransporta al jugador
func teleport(player: Node2D):
	player.position = teleport_position  # Cambia la posición del jugador
