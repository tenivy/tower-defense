extends CanvasLayer

var _transitioning: bool = false

@onready var overlay: Control = $Overlay
@onready var retry_button: Button = $Overlay/CenterContainer/Column/RetryButton
@onready var menu_button: Button = $Overlay/CenterContainer/Column/MenuButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_defeat(round_number: int) -> void:
	if overlay.visible:
		return
	$Overlay/CenterContainer/Column/RoundLabel.text = "Раунд " + str(round_number)
	overlay.show()
	get_tree().paused = true
	retry_button.grab_focus()


func _input(event: InputEvent) -> void:
	# Escape cannot resume a game after the castle has fallen.
	if overlay.visible and event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _on_retry_pressed() -> void:
	_go_to_scene("res://scenes/main.tscn")


func _on_menu_pressed() -> void:
	_go_to_scene("res://menus/main_menu.tscn")


func _go_to_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_transitioning = false
		get_tree().paused = true
		push_error("Не удалось открыть сцену: " + path)
