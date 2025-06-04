extends Node

# Singleton para manejar transiciones entre escenas
signal loading_started
signal loading_progress(progress: float)
signal loading_finished

var loading_screen_scene = null
var loading_screen_instance = null
var is_loading = false
var target_scene_path = ""

# Configuración de la pantalla de carga
var loading_config = {
	"min_loading_time": 1.0,  # Tiempo mínimo para mostrar la pantalla
	"show_tips": true,
	"show_progress": true,
	"fade_duration": 0.5
}

# Tips que se muestran durante la carga
var loading_tips = [
	"💡 Presiona 'I' para abrir tu inventario",
	"⚔️ Equipa armas y armaduras para mejorar tus estadísticas",
	"🧪 Las pociones se pueden usar desde el inventario",
	"🎒 Arrastra la ventana del inventario desde cualquier borde",
	"💍 Los accesorios proporcionan bonificaciones especiales",
	"🛡️ La defensa reduce el daño recibido",
	"🗡️ El ataque aumenta el daño que infliges",
	"❤️ Algunos objetos aumentan tu salud máxima",
	"🔄 Puedes intercambiar objetos entre ranuras",
	"✨ Los objetos de mayor rareza son más poderosos"
]

func _ready():
	print("🔄 SceneTransitionManager iniciado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crear la pantalla de carga
	create_loading_screen()

func create_loading_screen():
	# Crear la escena de pantalla de carga programáticamente
	loading_screen_scene = preload("res://Scripts/loading-screen.gd")
	print("✅ Pantalla de carga preparada")

func change_scene_with_loading(scene_path: String):
	if is_loading:
		print("⚠️ Ya hay una carga en progreso")
		return
	
	print("🔄 Iniciando carga de escena: ", scene_path)
	is_loading = true
	target_scene_path = scene_path
	
	# Mostrar pantalla de carga
	show_loading_screen()
	
	# Iniciar carga asíncrona
	start_async_loading()

func show_loading_screen():
	# Crear instancia de la pantalla de carga
	loading_screen_instance = Node.new()
	loading_screen_instance.set_script(loading_screen_scene)
	loading_screen_instance.name = "LoadingScreen"
	
	# Añadir a la escena
	get_tree().root.add_child(loading_screen_instance)
	
	# Configurar la pantalla
	loading_screen_instance.setup(loading_config, loading_tips)
	
	loading_started.emit()

func start_async_loading():
	# Usar ResourceLoader para carga asíncrona
	var error = ResourceLoader.load_threaded_request(target_scene_path)
	
	if error != OK:
		print("❌ Error al iniciar carga: ", error)
		finish_loading()
		return
	
	# Iniciar el proceso de monitoreo
	monitor_loading_progress()

func monitor_loading_progress():
	var start_time = Time.get_time_dict_from_system()
	var min_time_elapsed = false
	
	while true:
		# Verificar progreso de carga
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		# Actualizar progreso en la pantalla
		var current_progress = progress[0] if progress.size() > 0 else 0.0
		loading_progress.emit(current_progress)
		
		if loading_screen_instance and is_instance_valid(loading_screen_instance):
			loading_screen_instance.update_progress(current_progress)
		
		# Verificar si la carga ha terminado
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Verificar tiempo mínimo
			var current_time = Time.get_time_dict_from_system()
			var elapsed = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - \
						 (start_time.hour * 3600 + start_time.minute * 60 + start_time.second)
			
			if elapsed >= loading_config.min_loading_time:
				min_time_elapsed = true
			
			if min_time_elapsed:
				finish_loading()
				break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			print("❌ Error en la carga de la escena")
			finish_loading()
			break
		
		# Esperar un frame
		await get_tree().process_frame

func finish_loading():
	print("✅ Carga completada")
	
	# Obtener la escena cargada
	var loaded_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	if loaded_scene:
		# Animar salida de la pantalla de carga
		if loading_screen_instance and is_instance_valid(loading_screen_instance):
			loading_screen_instance.hide_with_animation()
			
			# Esperar a que termine la animación
			await get_tree().create_timer(loading_config.fade_duration).timeout
		
		# Cambiar a la nueva escena
		get_tree().change_scene_to_packed(loaded_scene)
		
		# Limpiar
		cleanup_loading()
		
		loading_finished.emit()
	else:
		print("❌ No se pudo cargar la escena")
		cleanup_loading()

func cleanup_loading():
	is_loading = false
	target_scene_path = ""
	
	if loading_screen_instance and is_instance_valid(loading_screen_instance):
		loading_screen_instance.queue_free()
		loading_screen_instance = null

# Función de conveniencia para usar desde otros scripts
func transition_to_scene(scene_path: String):
	change_scene_with_loading(scene_path)
