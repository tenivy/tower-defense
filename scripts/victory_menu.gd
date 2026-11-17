extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var free_play_button: Button = $Overlay/Center/Column/FreePlayButton
@onready var menu_button: Button = $Overlay/Center/Column/MenuButton
var _leaving: bool = false


func _ready() -> void:
	free_play_button.pressed.connect(_continue_free_play)
	menu_button.pressed.connect(_return_to_menu)


func show_victory() -> void:
	if overlay.visible:
		return
	overlay.show()
	get_tree().paused = true
	free_play_button.grab_focus()


func _input(event: InputEvent) -> void:
	if overlay.visible and event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _continue_free_play() -> void:
	if _leaving or not overlay.visible:
		return
	_leaving = true
	overlay.hide()
	get_tree().paused = false
	get_parent().enter_free_play()


func _return_to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	var error := get_tree().change_scene_to_file("res://menus/main_menu.tscn")
	if error != OK:
		_leaving = false
		get_tree().paused = true
		push_error("Не удалось открыть меню: " + error_string(error))
