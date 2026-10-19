extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 0
var max_distance: float = 400.0
var hit_radius: float = 14.0

var traveled: float = 0.0
var target = null

func _ready():
	rotation = direction.angle()

func _process(delta):
	# Слегка доворачиваем к цели, пока она жива
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

	var step = direction * speed * delta
	global_position += step
	traveled += step.length()

	# Улетела слишком далеко — исчезаем
	if traveled >= max_distance:
		queue_free()
		return

	# Попадание
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= hit_radius:
			enemy.take_damage(damage)
			queue_free()
			return
