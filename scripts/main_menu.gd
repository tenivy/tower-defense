extends Control

# Путь до сцены основной игры; грузим её в фоне, чтобы показывать прогресс
const GAME_SCENE_PATH = "res://scenes/main.tscn"

@onready var loading_overlay = $LoadingOverlay
@onready var loading_progress_bar = $LoadingOverlay/ColorRect/CenterContainer/LoadingVBox/LoadingProgressBar
@onready var play_button = $MarginContainer/CenterContainer/MenuVBox/PlayRow/PlayButton
@onready var settings_button = $MarginContainer/CenterContainer/MenuVBox/BottomRow/SettingsButton
@onready var quit_button = $MarginContainer/CenterContainer/MenuVBox/BottomRow/QuitButton

# Флаг загрузки: защищает от повторного запуска загрузки
var _is_loading = false


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	if _is_loading:
		return
	_is_loading = true

	# Показываем оверлей и блокируем кнопку от повторных нажатий
	loading_overlay.show_loading()
	play_button.disabled = true

	_load_game_scene()


# Загружает сцену игры в фоновом потоке и обновляет прогресс-бар
func _load_game_scene() -> void:
	# Ждём кадр, чтобы оверлей успел отрисоваться до старта загрузки
	await get_tree().process_frame

	var request_error = ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	if request_error != OK:
		print("Ошибка запуска загрузки сцены: ", request_error)
		_reset_loading_state()
		return

	var progress = []
	while true:
		var status = ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH, progress)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# В массиве progress один элемент — доля загрузки от 0 до 1
			if progress.size() > 0:
				loading_overlay.set_progress(progress[0] * 100.0)
			await get_tree().process_frame
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_scene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH)
			await loading_overlay.finish_loading()
			var change_error = get_tree().change_scene_to_packed(loaded_scene)
			if change_error != OK:
				_reset_loading_state()
			return
		else:
			# THREAD_LOAD_FAILED или THREAD_LOAD_INVALID_RESOURCE
			print("Ошибка загрузки сцены, статус: ", status)
			_reset_loading_state()
			return


# Возвращает меню в исходное состояние после ошибки загрузки
func _reset_loading_state() -> void:
	_is_loading = false
	loading_overlay.hide_loading()
	play_button.disabled = false


func _on_settings_pressed() -> void:
	print("Настройки в разработке")


func _on_quit_pressed() -> void:
	get_tree().quit()
