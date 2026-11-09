@tool
extends Panel
## Presentation only. Existing Main signals still handle buying and rounds.

const COIN = preload("res://assets/ui/shop/coin.svg")
const CARD_PRESSED = preload("res://assets/ui/shop/card-pressed.svg")
const PORTRAITS = [
	preload("res://assets/knight/knight1/1.png0001.png"),
	preload("res://assets/archer/archer1/1.png0001.png"),
	preload("res://assets/wizard/wizard1/1.png0001.png"),
]
const DEFENDER_SCENES = [
	preload("res://scenes/defender.tscn"),
	preload("res://scenes/archer.tscn"),
	preload("res://scenes/wizard.tscn"),
]
const BUTTON_NAMES = ["KnightButton", "ArcherButton", "WizardButton"]

var _cards: Array[Button] = []
var _costs: Array[int] = []
var _normal_style: StyleBoxTexture
var _selected_style: StyleBoxTexture


func _ready() -> void:
	_normal_style = get_theme_stylebox("normal", "Button").duplicate()
	_normal_style.content_margin_left = 86.0
	_normal_style.content_margin_top = 10.0
	_normal_style.content_margin_right = 8.0
	_normal_style.content_margin_bottom = 44.0
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
	icon.position = Vector2(12, 9)
	icon.size = Vector2(66, 66)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var price := Label.new()
	price.name = "Price"
	price.text = str(_costs[index])
	price.position = Vector2(111, 46)
	price.size = Vector2(70, 24)
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(price)

	var coin := TextureRect.new()
	coin.name = "Coin"
	coin.texture = COIN
	coin.position = Vector2(86, 49)
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
