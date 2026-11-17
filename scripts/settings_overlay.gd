extends CanvasLayer
## Shared modal for the main menu and pause. Opening it preserves the caller's pause state.

const SHOP_THEME = preload("res://assets/ui/shop/shop-theme.tres")
const CARD = preload("res://assets/ui/shop/card-normal.svg")
const DIVIDER = preload("res://assets/ui/shop/divider.svg")
const MUSIC_ICON = preload("res://assets/ui/settings/music.svg")
const SOUNDS_ICON = preload("res://assets/ui/settings/speaker.svg")
const THUMB = preload("res://assets/ui/settings/slider-thumb.svg")
const CUES: Array[StringName] = [&"sword", &"arrow", &"spell", &"catapult", &"ogre", &"werewolf"]
const CUE_NAMES = ["Меч рыцаря", "Выстрел лучницы", "Заклинание мага", "Бросок катапульты", "Рык огра", "Вой оборотня"]
const GOLD = Color("f1ce89")
const MUTED_GOLD = Color("aa9a7b")

var overlay: Control
var panel: PanelContainer
var done_button: Button
var preview_button: Button
var preview_label: Label
var _rows: Dictionary = {}
var _was_paused: bool = false
var _return_focus: WeakRef
var _preview_index: int = 0
var _appear: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_build_ui()
	AudioSettings.changed.connect(_sync)
	_sync()


func _build_ui() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = SHOP_THEME
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.015, 0.025, 0.045, 0.82)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.custom_minimum_size.x = 640
	var frame := StyleBoxTexture.new()
	frame.texture = CARD
	frame.set_texture_margin_all(9)
	frame.content_margin_left = 28
	frame.content_margin_right = 28
	frame.content_margin_top = 22
	frame.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", frame)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("Настройки", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var escape := _label("Esc", 16)
	escape.modulate = MUTED_GOLD
	heading.add_child(escape)
	var subtitle := _label("Звуки вашего королевства", 16)
	subtitle.modulate = MUTED_GOLD
	column.add_child(subtitle)
	var ornament := TextureRect.new()
	ornament.texture = DIVIDER
	ornament.custom_minimum_size = Vector2(0, 16)
	ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ornament.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(ornament)
	_add_audio_row(column, &"Music", "Музыка", "Меню и музыка во время игры", MUSIC_ICON)
	_add_audio_row(column, &"SFX", "Эффекты", "Оружие и голоса противников", SOUNDS_ICON)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	preview_button = _button("Проверить звук")
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_preview)
	buttons.add_child(preview_button)
	done_button = _button("Готово")
	done_button.custom_minimum_size.x = 196
	done_button.pressed.connect(close)
	buttons.add_child(done_button)
	preview_label = _label("Прослушайте эффекты по очереди", 16)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.modulate = MUTED_GOLD
	column.add_child(preview_label)
	var saved := _label("Громкость сохраняется автоматически", 16)
	saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	saved.modulate = Color("7d8989")
	column.add_child(saved)
	overlay.hide()


func _add_audio_row(parent: VBoxContainer, channel: StringName, title: String, hint: String, icon: Texture2D) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101922")
	style.border_color = Color("605236")
	style.set_border_width_all(1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	column.add_child(header)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(32, 32)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(picture)
	var label := _label(title, 24)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var mute := CheckBox.new()
	mute.name = String(channel) + "Mute"
	mute.text = "Выключить"
	mute.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mute.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	mute.toggled.connect(func(pressed: bool): AudioSettings.set_muted(channel, pressed))
	header.add_child(mute)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 16)
	column.add_child(controls)
	var slider := HSlider.new()
	slider.name = String(channel) + "Volume"
	slider.custom_minimum_size.y = 32
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.scrollable = true
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_slider(slider)
	slider.value_changed.connect(func(value: float): AudioSettings.set_volume(channel, value / 100.0))
	controls.add_child(slider)
	var percent := _label("100%", 16)
	percent.custom_minimum_size.x = 60
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_child(percent)
	var description := _label(hint, 16)
	description.modulate = MUTED_GOLD
	column.add_child(description)
	_rows[channel] = {"slider": slider, "mute": mute, "percent": percent}


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("080f17")
	track.border_color = Color("685332")
	track.set_border_width_all(2)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("b78e48")
	fill.border_color = Color("e7c477")
	fill.set_border_width_all(1)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	slider.add_theme_icon_override("grabber", THUMB)
	slider.add_theme_icon_override("grabber_highlight", THUMB)
	slider.add_theme_icon_override("grabber_disabled", THUMB)


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _sync() -> void:
	for channel: StringName in _rows:
		var row: Dictionary = _rows[channel]
		var volume: float = AudioSettings.music_volume if channel == &"Music" else AudioSettings.sounds_volume
		var muted: bool = AudioSettings.music_muted if channel == &"Music" else AudioSettings.sounds_muted
		row.slider.set_value_no_signal(roundf(volume * 100.0))
		row.mute.set_pressed_no_signal(muted)
		row.percent.text = str(roundi(volume * 100.0)) + "%"
		row.slider.modulate = Color("877e6b") if muted else Color.WHITE
		row.percent.modulate = MUTED_GOLD if muted else GOLD
	preview_button.disabled = AudioSettings.sounds_muted or AudioSettings.sounds_volume <= 0.0


func open(return_focus: Control = null) -> void:
	if is_open():
		return
	_was_paused = get_tree().paused
	_return_focus = weakref(return_focus) if return_focus != null else null
	get_tree().paused = true
	_sync()
	preview_label.text = "Прослушайте эффекты по очереди"
	_preview_index = 0
	overlay.show()
	panel.modulate.a = 0.0
	_appear = create_tween().set_ignore_time_scale(true)
	_appear.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_appear.tween_property(panel, "modulate:a", 1.0, 0.14)
	done_button.grab_focus()


func close() -> void:
	if not is_open():
		return
	if _appear and _appear.is_valid():
		_appear.kill()
	SoundManager.stop_preview()
	AudioSettings.save_settings()
	overlay.hide()
	get_tree().paused = _was_paused
	if _return_focus != null and is_instance_valid(_return_focus.get_ref()):
		var control: Control = _return_focus.get_ref()
		if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
			control.grab_focus()
	_return_focus = null


func is_open() -> bool:
	return overlay != null and overlay.visible


func _input(event: InputEvent) -> void:
	if is_open() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _preview() -> void:
	SoundManager.preview(CUES[_preview_index])
	preview_label.text = CUE_NAMES[_preview_index]
	_preview_index = (_preview_index + 1) % CUES.size()
