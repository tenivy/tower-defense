extends AnimatedSprite2D
## Only the werewolf's visual presentation; movement and combat stay on Enemy.

@export var front_scale: float = 1.45
@export var back_scale: float = 1.15
@export var front_vertical_offset: float = -4.3
@export var back_vertical_offset: float = 2.4

var _original_scale: Vector2
var _original_position: Vector2


func _ready() -> void:
	_original_scale = scale
	_original_position = position
	animation_changed.connect(_apply_facing_size)
	_apply_facing_size()


func _apply_facing_size() -> void:
	# Fixed correction per direction preserves the natural walk-cycle motion.
	# Side views restore their exact original transform on every turn.
	var multiplier := 1.0
	var vertical_offset := 0.0
	match animation:
		&"walk_down":
			multiplier = front_scale
			vertical_offset = front_vertical_offset
		&"walk_up":
			multiplier = back_scale
			vertical_offset = back_vertical_offset
	scale = _original_scale * multiplier
	position = _original_position + Vector2(0, vertical_offset)
