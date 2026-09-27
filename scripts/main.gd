extends Node2D

@export var defender_scene: PackedScene
@export var path_clearance: float = 2.0
@export var defender_clearance: float = 60.0

@onready var defenders = $Defenders
@onready var enemy_path = $Map/EnemyPath
@onready var gold_label = $GoldLabel
@onready var castle_health_bar = $CastleHealthBar

var preview_defender
var selected_defender = false

var castle_health = 100
var castle_max_health = 100

var current_round = 0
var enemies_to_spawn = 5
var enemies_spawned = 0
var enemies_remaining = 0

var spawn_interval = 1.5
var round_reward = 50

var gold = 100
var knight_cost = 20

func update_gold_label():
	gold_label.text = "Gold: " + str(gold)

func _ready():
	print("Игра запущена")
	update_gold_label()
	start_round()

func select_knight():
	selected_defender = true

	if preview_defender:
		preview_defender.queue_free()

	preview_defender = defender_scene.instantiate()
	preview_defender.is_preview = true
	add_child(preview_defender)

func _process(_delta):
	if preview_defender:
		update_preview()

func update_preview():
	var mouse_position = get_global_mouse_position()
	preview_defender.global_position = mouse_position

	var can_place = can_place_defender(mouse_position)

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
	defenders.add_child(defender)
	defender.global_position = position

	print("Рыцарь установлен. Золото: ", gold)

func damage_castle(amount: int):
	castle_health -= amount

	if castle_health < 0:
		castle_health = 0

	print("Замок получил урон: ", amount, " | HP: ", castle_health)

	if castle_health_bar:
		castle_health_bar.value = castle_health

	if castle_health <= 0:
		game_over()

func game_over():
	print("ПОРАЖЕНИЕ! Замок разрушен.")
	get_tree().paused = true

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

func spawn_enemy():
	if enemies_spawned >= enemies_to_spawn:
		return

	var enemy_scene = preload("res://Enemy.tscn")

	var enemy = enemy_scene.instantiate()
	$Enemies.add_child(enemy)

	var points = enemy_path.get_global_transform() * enemy_path.points
	enemy.setup_path(points)

	enemies_spawned += 1

	print("Создан враг ", enemies_spawned, " из ", enemies_to_spawn)

func start_round():
	current_round += 1

	enemies_to_spawn = 5 + (current_round - 1) * 2
	enemies_spawned = 0
	enemies_remaining = enemies_to_spawn

	print("Начался раунд ", current_round)
	print("Врагов: ", enemies_to_spawn)

	spawn_enemy()

	if enemies_spawned < enemies_to_spawn:
		$SpawnTimer.start()

func _on_spawn_timer_timeout():
	if enemies_spawned < enemies_to_spawn:
		spawn_enemy()

	if enemies_spawned >= enemies_to_spawn:
		$SpawnTimer.stop()

func add_gold(amount: int):
	gold += amount
	update_gold_label()

	print("Получено золота: ", amount, " | Всего: ", gold)

func enemy_finished():
	enemies_remaining -= 1

	print("Осталось врагов: ", enemies_remaining)

	if enemies_remaining <= 0:
		end_round()

func end_round():
	add_gold(round_reward)

	print("Раунд ", current_round, " завершён!")
	print("Награда за раунд: ", round_reward)
