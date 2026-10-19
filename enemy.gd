extends Node2D

@onready var animated_sprite = $Body/AnimatedSprite2D

@export var speed: float = 100.0
@export var health: int = 100
@export var reward: int = 10
@export var castle_damage: int = 10

var path_points: PackedVector2Array
var current_point: int = 0
var current_facing: String = "down"

func _ready():
	add_to_group("enemies")
	animated_sprite.play("walk_" + current_facing)

func setup_path(points: PackedVector2Array):
	path_points = points
	current_point = 0

	if path_points.size() > 0:
		global_position = path_points[0]


func _process(delta):
	if path_points.is_empty():
		return

	if current_point >= path_points.size():
		reach_castle()
		return

	var target = path_points[current_point]

	var direction = global_position.direction_to(target)
	update_facing(direction)
	var distance = global_position.distance_to(target)

	if distance <= speed * delta:
		global_position = target

		# Если это последняя точка пути —
		# враг достиг замка
		if current_point == path_points.size() - 1:
			reach_castle()
			return

		current_point += 1
	else:
		global_position += direction * speed * delta


func take_damage(amount: int):
	health -= amount

	if health <= 0:
		die()


func die():
	var main = get_tree().current_scene

	if main.has_method("add_gold"):
		main.add_gold(reward)

	if main.has_method("enemy_finished"):
		main.enemy_finished()

	queue_free()


func reach_castle():
	var main = get_tree().current_scene

	if main.has_method("damage_castle"):
		main.damage_castle(castle_damage)

	if main.has_method("enemy_finished"):
		main.enemy_finished()

	queue_free()

# Выбирает один из 4 ракурсов по направлению движения
func update_facing(direction: Vector2):
	var new_facing: String
	if abs(direction.x) > abs(direction.y):
		new_facing = "right" if direction.x > 0 else "left"
	else:
		new_facing = "down" if direction.y > 0 else "up"
	if new_facing != current_facing:
		current_facing = new_facing
		animated_sprite.play("walk_" + current_facing)

# Возвращает, насколько далеко враг продвинулся по дороге
func get_progress() -> int:
	return current_point
