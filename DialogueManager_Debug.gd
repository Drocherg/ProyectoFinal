extends Node

var dialogue_ui: Control = null

func _ready():
	print("🗣️ DialogueManager iniciado")
	call_deferred("debug_ui_structure")

func debug_ui_structure():
	var scene_path = "res://Escenas/UI/DialogueUI.tscn"
	
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			var ui_instance = scene.instantiate()
			get_tree().root.add_child(ui_instance)
			
			print("🔍 Estructura de DialogueUI:")
			print_node_tree(ui_instance, 0)
			
			ui_instance.queue_free()

func print_node_tree(node: Node, depth: int):
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	print(indent + "- " + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		print_node_tree(child, depth + 1)
