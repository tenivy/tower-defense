extends Node2D

func _ready():
	add_to_group("enemies")

@export var speed: float = 100.0
@export var health: int = 100
@export var reward: int = 10

var path_points: PackedVector2Array
var current_point: int = 0


func setup_path(points: PackedVector2Array):
	path_points = points
	current_point = 0

	if path_points.size() > 0:
		global_position = path_points[0]


func _process(delta):
	if path_points.is_empty():
		return

	if current_point >= path_points.size():
		return

	var target = path_points[current_point]

	var direction = global_position.direction_to(target)
	var distance = global_position.distance_to(target)

	if distance <= speed * delta:
		global_position = target
		current_point += 1
	else:
		global_position += direction * speed * delta

func take_damage(amount: int):
	health -= amount

	print("Враг получил урон: ", amount, " | HP: ", health)

	if health <= 0:
		die()

func die():
	queue_free()
