extends Control
## Only presentation; MainMenu retains threaded resource loading and transitions.

const MIN_VISIBLE_SECONDS = 0.65
const TIPS = [
	"Лучники прикрывают рыцарей издалека",
	"Клавиша B открывает и скрывает магазин",
	"Улучшайте защитников между волнами",
	"Катапульта наносит урон по области",
	"Автостарт запускает следующие волны",
]

@onready var progress_bar: ProgressBar = $ColorRect/CenterContainer/LoadingVBox/LoadingProgressBar
@onready var status_label: Label = $ColorRect/CenterContainer/LoadingVBox/StatusLabel
@onready var tip_label: Label = $ColorRect/CenterContainer/LoadingVBox/TipLabel

var _target_progress: float = 0.0
var _display_progress: float = 0.0
var _started_at: int = 0
var _elapsed: float = 0.0
var _tip_index: int = 0
var _appearance_tween: Tween


func _ready() -> void:
	set_process(false)


func show_loading() -> void:
	_target_progress = 0.0
	_display_progress = 0.0
	_elapsed = 0.0
	_started_at = Time.get_ticks_msec()
	_tip_index = randi_range(0, TIPS.size() - 1)
	progress_bar.value = 0.0
	tip_label.text = "Совет: " + TIPS[_tip_index]
	status_label.text = "Собираем защитников..."
	show()
	modulate.a = 0.0
	set_process(true)
	if _appearance_tween and _appearance_tween.is_valid():
		_appearance_tween.kill()
	_appearance_tween = create_tween().set_ignore_time_scale(true)
	_appearance_tween.tween_property(self, "modulate:a", 1.0, 0.18)


func set_progress(percent: float) -> void:
	# Never show progress ahead of the resource loader or move backwards.
	_target_progress = maxf(_target_progress, clampf(percent, 0.0, 100.0))


func finish_loading() -> void:
	set_progress(100.0)
	while _display_progress < 100.0 or (Time.get_ticks_msec() - _started_at) < MIN_VISIBLE_SECONDS * 1000.0:
		await get_tree().process_frame
	status_label.text = "К обороне всё готово"
	await get_tree().create_timer(0.12, true, false, true).timeout


func hide_loading() -> void:
	if _appearance_tween and _appearance_tween.is_valid():
		_appearance_tween.kill()
	hide()
	set_process(false)
	modulate.a = 1.0


func _process(delta: float) -> void:
	_display_progress = move_toward(_display_progress, _target_progress, delta * 180.0)
	progress_bar.value = _display_progress
	_elapsed += delta
	var dots := ".".repeat(1 + int(_elapsed * 2.5) % 3)
	if _display_progress >= 100.0:
		status_label.text = "К обороне всё готово"
	elif _display_progress >= 70.0:
		status_label.text = "Укрепляем замок" + dots
	elif _display_progress >= 33.0:
		status_label.text = "Готовим поле боя" + dots
	else:
		status_label.text = "Собираем защитников" + dots
	var next_tip := (int(_elapsed / 4.0) + _tip_index) % TIPS.size()
	tip_label.text = "Совет: " + TIPS[next_tip]
