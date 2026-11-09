@tool
extends Panel
## Shop presentation and drawer. Main still handles buying and rounds.

const COIN = preload("res://assets/ui/shop/coin.svg")
const CARD_PRESSED = preload("res://assets/ui/shop/card-pressed.svg")
const PORTRAITS = [
	preload("res://assets/knight/knight1/1.png0001.png"),
	preload("res://assets/archer/archer1/1.png0001.png"),
	preload("res://assets/wizard/wizard1/1.png0001.png"),
	preload("res://assets/catapult/front/1.png0001.png"),
]
const DEFENDER_SCENES = [
	preload("res://scenes/defender.tscn"),
	preload("res://scenes/archer.tscn"),
	preload("res://scenes/wizard.tscn"),
	preload("res://scenes/catapult.tscn"),
]
const BUTTON_NAMES = ["KnightButton", "ArcherButton", "WizardButton", "CatapultButton"]
const DRAWER_DURATION = 0.24

var _cards: Array[Button] = []
var _costs: Array[int] = []
var _normal_style: StyleBoxTexture
var _selected_style: StyleBoxTexture
var is_collapsed: bool = false
var _drawer_progress: float = 0.0
var _drawer_tween: Tween
var _open_position: Vector2
var _gold_label: Label
var _gold_open_position: Vector2


func _ready() -> void:
	_normal_style = get_theme_stylebox("normal", "Button").duplicate()
	_normal_style.content_margin_left = 86.0
	_normal_style.content_margin_top = 8.0
	_normal_style.content_margin_right = 8.0
	_normal_style.content_margin_bottom = 38.0
	_selected_style = _normal_style.duplicate()
	_selected_style.texture = CARD_PRESSED
	for index in BUTTON_NAMES.size():
		var button: Button = get_node(BUTTON_NAMES[index])
		_cards.append(button)
		_costs.append(_scene_cost(DEFENDER_SCENES[index]))
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var style: StyleBoxTexture = _normal_style.duplicate()
			style.texture = (button.get_theme_stylebox(state) as StyleBoxTexture).texture
			button.add_theme_stylebox_override(state, style)
		_add_card_content(button, index)
	if Engine.is_editor_hint():
		set_process(false)
		set_process_unhandled_key_input(false)
		return
	_open_position = position
	# GoldLabel keeps its original path for Main's economy code.
	_gold_label = get_parent().get_node("GoldLabel")
	_gold_open_position = _gold_label.position
	$ToggleButton.pressed.connect(toggle_shop)
	_update_toggle_button()


func is_pointer_over_shop(point: Vector2) -> bool:
	return get_global_rect().has_point(point) or $ToggleButton.get_global_rect().has_point(point)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Physical B also works with the Russian keyboard layout (И).
		if (event.physical_keycode == KEY_B or event.keycode == KEY_B) and not (
			event.ctrl_pressed or event.alt_pressed or event.meta_pressed
		):
			toggle_shop()
			get_viewport().set_input_as_handled()


func toggle_shop() -> void:
	set_collapsed(not is_collapsed)


func set_collapsed(collapsed: bool) -> void:
	if is_collapsed == collapsed:
		return
	is_collapsed = collapsed
	if _drawer_tween and _drawer_tween.is_valid():
		_drawer_tween.kill()
	# Hidden cards must not retain keyboard focus or receive Space/Enter.
	var focused := get_viewport().gui_get_focus_owner()
	if is_collapsed and focused and focused != $ToggleButton and is_ancestor_of(focused):
		focused.release_focus()
	for button in _cards + [$StartRoundButton, $AutoStartCheckBox, $SpeedCheckBox]:
		button.focus_mode = Control.FOCUS_NONE if is_collapsed else Control.FOCUS_ALL
	_update_toggle_button()
	_drawer_tween = create_tween()
	_drawer_tween.set_ignore_time_scale(true)
	_drawer_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_drawer_tween.tween_method(
		_set_drawer_progress, _drawer_progress, 1.0 if is_collapsed else 0.0, DRAWER_DURATION
	)


func _set_drawer_progress(progress: float) -> void:
	_drawer_progress = progress
	# Align the panel's right edge with the viewport's left edge when closed.
	var closed_x: float = get_parent().to_local(Vector2(0.0, global_position.y)).x - size.x
	position.x = lerpf(_open_position.x, closed_x, progress)
	_gold_label.position.x = _gold_open_position.x + position.x - _open_position.x


func _update_toggle_button() -> void:
	$ToggleButton/Arrow.flip_h = is_collapsed
	$ToggleButton.tooltip_text = "Показать магазин (B)" if is_collapsed else "Скрыть магазин (B)"


func _add_card_content(button: Button, index: int) -> void:
	# Crop transparent margins at load time; keep original game art untouched.
	var portrait := AtlasTexture.new()
	portrait.atlas = PORTRAITS[index]
	portrait.region = Rect2(PORTRAITS[index].get_image().get_used_rect())
	var icon := TextureRect.new()
	icon.name = "Portrait"
	icon.texture = portrait
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(12, 8)
	icon.size = Vector2(58, 58)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var price := Label.new()
	price.name = "Price"
	price.text = str(_costs[index])
	price.position = Vector2(111, 40)
	price.size = Vector2(70, 24)
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(price)

	var coin := TextureRect.new()
	coin.name = "Coin"
	coin.texture = COIN
	coin.position = Vector2(86, 43)
	coin.size = Vector2(18, 18)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(coin)


func _scene_cost(scene: PackedScene) -> int:
	var state := scene.get_state()
	for property in state.get_node_property_count(0):
		if state.get_node_property_name(0, property) == &"cost":
			return int(state.get_node_property_value(0, property))
	return 100 # The default exported cost in defender.gd.


func _process(_delta: float) -> void:
	var game := get_parent()
	for index in _cards.size():
		var button := _cards[index]
		var selected: bool = game.selected_defender and game.placement_scene == DEFENDER_SCENES[index]
		# Selection and affordability only affect appearance, never purchasing rules.
		if button.get_meta(&"selected", false) != selected:
			button.add_theme_stylebox_override("normal", _selected_style if selected else _normal_style)
			button.set_meta(&"selected", selected)
		var price: Label = button.get_node("Price")
		var affordable: bool = game.gold >= _costs[index]
		price.modulate = Color.WHITE if affordable else Color(0.75, 0.49, 0.40)
