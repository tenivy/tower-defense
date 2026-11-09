extends CanvasLayer

# Открытие паузы по Escape обрабатывает main.gd.
# Узел PauseMenu в сцене имеет process_mode = ALWAYS, поэтому этот скрипт
# и кнопки продолжают работать, пока дерево сцен стоит на паузе.

@onready var overlay = $Overlay
@onready var continue_button = $Overlay/ColorRect/CenterContainer/VBoxContainer/ContinueButton
@onready var settings_button = $Overlay/ColorRect/CenterContainer/VBoxContainer/SettingsButton
@onready var exit_to_menu_button = $Overlay/ColorRect/CenterContainer/VBoxContainer/ExitToMenuButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_to_menu_button.pressed.connect(_on_exit_to_menu_pressed)


func _input(event) -> void:
	# Закрываем паузу по Escape, только если она уже открыта
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE and overlay.visible:
			resume_game()
			get_viewport().set_input_as_handled()


# Ставит игру на паузу и показывает меню
func open_pause() -> void:
	get_tree().paused = true
	overlay.visible = true


# Снимает паузу и прячет меню
func resume_game() -> void:
	get_tree().paused = false
	overlay.visible = false


func _on_continue_pressed() -> void:
	resume_game()


func _on_settings_pressed() -> void:
	print("Настройки в разработке")


func _on_exit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
