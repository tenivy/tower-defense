extends Node2D

@export var defender_scene: PackedScene
@export var path_clearance: float = 2.0
@export var defender_clearance: float = 60.0

@onready var defenders = $Defenders
@onready var enemy_path = $Map/EnemyPath
@onready var gold_label = $GoldLabel

var preview_defender
var selected_defender = false

var gold = 100
var knight_cost = 20

func update_gold_label():
	gold_label.text = "Gold: " + str(gold)

func _ready():
	print("Игра запущена")
	update_gold_label()
	start_enemy()

func select_knight():
	selected_defender = true

	if preview_defender:
		preview_defender.queue_free()

	preview_defender = defender_scene.instantiate()
	add_child(preview_defender)

func _process(_delta):
	if preview_defender:
		update_preview()

func update_preview():
	var position = get_global_mouse_position()
	preview_defender.position = position

	var can_place = can_place_defender(position)

	var body = preview_defender.get_node("Body")

	if can_place:
		body.color = Color(0.2, 1.0, 0.2, 0.5)
	else:
		body.color = Color(1.0, 0.2, 0.2, 0.5)

func _input(event):
	if not selected_defender:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			var mouse_position = get_global_mouse_position()

			var shop_rect = $Shop.get_global_rect()

			if shop_rect.has_point(mouse_position):
				return

			place_defender(mouse_position)

func place_defender(position: Vector2):
	if not can_place_defender(position):
		print("Сюда ставить нельзя")
		return

	gold -= knight_cost
	update_gold_label()

	var defender = defender_scene.instantiate()
	defender.position = position
	defenders.add_child(defender)

	print("Рыцарь установлен. Золото: ", gold)


func can_place_defender(position: Vector2) -> bool:
	if gold < knight_cost:
		return false

	if is_too_close_to_path(position):
		return false

	if is_too_close_to_defender(position):
		return false

	return true


func is_too_close_to_defender(position: Vector2) -> bool:
	for defender in defenders.get_children():
		var distance = position.distance_to(defender.position)

		if distance < defender_clearance:
			return true

	return false


func is_too_close_to_path(position: Vector2) -> bool:
	var path = $Map/EnemyPath
	var points = path.points

	var local_position = path.to_local(position)

	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]

		var segment = end - start
		var length_squared = segment.length_squared()

		if length_squared == 0:
			continue

		var t = (local_position - start).dot(segment) / length_squared
		t = clamp(t, 0.0, 1.0)

		var closest_point = start + segment * t

		if local_position.distance_to(closest_point) < path_clearance:
			return true

	return false


func _on_knight_button_pressed():
	select_knight()

func start_enemy():
	var enemy_scene = preload("res://Enemy.tscn")

	var enemy = enemy_scene.instantiate()
	$Enemies.add_child(enemy)

	var points = enemy_path.get_global_transform() * enemy_path.points
	enemy.setup_path(points)
