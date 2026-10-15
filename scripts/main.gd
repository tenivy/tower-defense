extends Node2D

@export var defender_scene: PackedScene
@export var path_clearance: float = 2.0
@export var defender_clearance: float = 60.0

@onready var defenders = $Defenders
@onready var enemy_path = $Map/EnemyPath
@onready var gold_label = $GoldLabel
@onready var castle_health_bar = $CastleHealthBar
@onready var round_label = $Shop/RoundLabel

var preview_defender
var selected_defender = false
var selected_placed_defender = null
var defender_click_radius = 25

var castle_health = 100
var castle_max_health = 100

var archer_scene = preload("res://Archer.tscn")
var placement_scene: PackedScene = null

var round_in_progress = false
var current_round = 0
var enemies_to_spawn = 5
var enemies_spawned = 0
var enemies_remaining = 0

var spawn_interval = 1.5
var round_reward = 50

var gold = 100
var upgrade_costs_by_level = [50, 100]

func update_gold_label():
	gold_label.text = "Gold: " + str(gold)

func _ready():
	print("Игра запущена")
	update_gold_label()
	$DefenderPanel.visible = false

func select_knight():
	start_defender_placement(defender_scene)

func select_archer():
	start_defender_placement(archer_scene)

func start_defender_placement(scene):
	selected_defender = true
	placement_scene = scene
	if preview_defender:
		preview_defender.queue_free()
	preview_defender = scene.instantiate()
	preview_defender.is_preview = true
	add_child(preview_defender)

func _process(_delta):
	if preview_defender:
		update_preview()

func update_preview():
	var mouse_position = get_global_mouse_position()
	preview_defender.global_position = mouse_position
	var can_place = can_place_defender(mouse_position)
	var sprite = preview_defender.get_node("KnightSprite")
	var attack_range_circle = preview_defender.attack_range_circle
	if can_place:
		sprite.modulate = Color(0.2, 1.0, 0.2, 0.5)
		attack_range_circle.default_color = Color(0.2, 1.0, 0.2, 0.35)
	else:
		sprite.modulate = Color(1.0, 0.2, 0.2, 0.5)
		attack_range_circle.default_color = Color(1.0, 0.2, 0.2, 0.35)

func _input(event):
	# Отмена установки Рыцаря по ПКМ
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_defender_placement()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = get_global_mouse_position()

			# Не обрабатываем клики по самой панели
			if $DefenderPanel.visible:
				var panel_rect = $DefenderPanel.get_global_rect()
				if panel_rect.has_point(mouse_position):
					return

			# Если Рыцарь выбран для установки — ставим
			if selected_defender:
				var shop_rect = $Shop.get_global_rect()
				if shop_rect.has_point(mouse_position):
					return
				place_defender(mouse_position)
				return

			# Иначе проверяем, не кликнули ли по уже стоящему Рыцарю
			var defender = get_defender_at(mouse_position)
			if defender:
				select_placed_defender(defender)
			else:
				deselect_placed_defender()

func place_defender(position: Vector2):
	if not can_place_defender(position):
		print("Сюда ставить нельзя")
		return
	var defender = placement_scene.instantiate()
	defenders.add_child(defender)
	defender.global_position = position
	gold -= defender.cost
	update_gold_label()
	if preview_defender:
		preview_defender.queue_free()
		preview_defender = null
	selected_defender = false
	print("Защитник установлен. Золото: ", gold)

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
	if preview_defender and gold < preview_defender.cost:
		return false
	if is_too_close_to_path(position):
		return false
	if is_too_close_to_defender(position):
		return false
	return true

func is_too_close_to_defender(position: Vector2) -> bool:
	for defender in defenders.get_children():
		var distance = position.distance_to(defender.global_position)

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
	if round_in_progress:
		return

	round_in_progress = true
	current_round += 1
	update_round_label()

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

	round_in_progress = false

	print("Раунд ", current_round, " завершён!")
	print("Награда за раунд: ", round_reward)

func _on_start_round_button_pressed():
	start_round()

func cancel_defender_placement():
	if preview_defender:
		preview_defender.queue_free()
		preview_defender = null

	selected_defender = false

	print("Установка Рыцаря отменена")

func update_round_label():
	round_label.text = "Раунд " + str(current_round)

func get_defender_at(position: Vector2):
	var best_defender = null
	var best_distance = INF
	for defender in defenders.get_children():
		var distance = position.distance_to(defender.global_position)
		if distance <= defender_click_radius and distance < best_distance:
			best_distance = distance
			best_defender = defender
	return best_defender

func select_placed_defender(defender):
	deselect_placed_defender()
	selected_placed_defender = defender
	defender.attack_range_circle.visible = true
	$DefenderPanel.visible = true
	print("Рыцарь выбран")
	update_upgrade_button()

func deselect_placed_defender():
	if selected_placed_defender:
		selected_placed_defender.attack_range_circle.visible = false
	selected_placed_defender = null
	$DefenderPanel.visible = false

func _on_upgrade_button_pressed():
	if selected_placed_defender == null:
		return
	var level = selected_placed_defender.upgrade_level
	if level >= 3:
		print("Рыцарь уже максимального уровня")
		return
	var cost = upgrade_costs_by_level[level - 1]
	if gold < cost:
		print("Недостаточно золота. Нужно: ", cost)
		return
	gold -= cost
	update_gold_label()
	selected_placed_defender.upgrade()
	update_upgrade_button()

func _on_sell_button_pressed():

	if selected_placed_defender == null:
		return
	var defender = selected_placed_defender
	var invested = defender.cost
	for i in range(defender.upgrade_level - 1):
		invested += upgrade_costs_by_level[i]
	var refund = invested / 2
	gold += refund
	update_gold_label()
	deselect_placed_defender()
	defender.queue_free()
	print("Рыцарь продан. Возврат: ", refund)

func update_upgrade_button():
	var level = selected_placed_defender.upgrade_level
	if level >= 3:
		$DefenderPanel/UpgradeButton.text = "Макс. уровень"
	else:
		var cost = upgrade_costs_by_level[level - 1]
		$DefenderPanel/UpgradeButton.text = "Улучшить (" + str(cost) + ")"
