@tool
extends ProgressBar
## Retains the original health value API with an inset, tiled pixel fill.

var _pixel_fill: StyleBox


func _ready() -> void:
	_pixel_fill = get_theme_stylebox("fill")
	# ProgressBar normally paints its fill over the entire frame rectangle.
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	show_percentage = false
	value_changed.connect(func(_value: float) -> void: queue_redraw())


func _draw() -> void:
	if _pixel_fill == null:
		return
	var inset := 6.0
	var inner := Rect2(Vector2(inset, inset), (size - Vector2.ONE * inset * 2.0).max(Vector2.ZERO))
	inner.size.x = floorf(inner.size.x * get_as_ratio())
	if inner.has_area():
		_pixel_fill.draw(get_canvas_item(), inner)
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var baseline := floorf((size.y - font.get_height(font_size)) / 2.0) + font.get_ascent(font_size)
	var text := "%d%%" % roundi(get_as_ratio() * 100.0)
	font.draw_string(get_canvas_item(), Vector2(1, baseline + 1), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color("101b1b"))
	font.draw_string(get_canvas_item(), Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, get_theme_color("font_color"))
