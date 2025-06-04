extends Area2D

@export var portal_group: String = "portal"
var send_Player_to: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Encontrar otros portales en el grupo
	var portals = get_tree().get_nodes_in_group(portal_group)

	for portal in portals:
		# Asegurarnos de que no estamos seleccionando este mismo portal
		if portal != self and portal is Area2D:
			print("El portal con posición ", position, " ha detectado el otro portal con posición ", portal.position)
			send_Player_to = portal.position
			break  # Asumimos que solo hay un destino por ahora

# Función que se ejecuta al entrar en el área del portal
func _on_area_2d_area_entered(area: Area2D) -> void:
	# Verificar si el área es del jugador
	var parent = area.get_parent()
	if parent.is_in_group("Player"):
		parent.position = send_Player_to
