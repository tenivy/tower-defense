extends Node2D

var is_preview: bool = false
var attack_range_circle: Line2D

# Уровень рыцаря
var upgrade_level: int = 1

# Характеристики каждого уровня
@export var damage_by_level = [20, 35, 55]
@export var attack_range_by_level = [100.0, 120.0, 140.0]
@export var attack_cooldown_by_level = [1.0, 0.9, 0.75]

@export var cost: int = 100
@export var damage: int = 20
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 100.0

@export var texture_level_1: Texture2D
@export var texture_level_2: Texture2D
@export var texture_level_3: Texture2D

@export var uses_projectile: bool = false
@export var projectile_scene: PackedScene = null
@export var projectile_speed: float = 600.0

var attack_timer: float = 0.0

func _ready():
	# Устанавливаем характеристики текущего уровня
	update_stats()

	attack_range_circle = Line2D.new()
	add_child(attack_range_circle)

	attack_range_circle.width = 2.0
	attack_range_circle.default_color = Color(0.2, 1.0, 0.2, 0.35)

	var points = PackedVector2Array()

	for i in range(65):
		var angle = TAU * i / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * attack_range)

	attack_range_circle.points = points
	attack_range_circle.visible = is_preview
	
	$Body.visible = false
	update_sprite()

func _process(delta):
	if is_preview:
		return

	if attack_timer > 0:
		attack_timer -= delta

	var enemy = find_nearest_enemy()

	if enemy:
		look_at(enemy.global_position)

		if attack_timer <= 0:
			attack(enemy)
			attack_timer = attack_cooldown

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")

	var best_enemy = null
	var best_distance_to_castle = INF

	var castle = get_tree().current_scene.get_node("Map/Castle")

	for enemy in enemies:
		var distance_to_defender = global_position.distance_to(enemy.global_position)

		# Враг должен находиться в радиусе атаки
		if distance_to_defender > attack_range:
			continue

		# Расстояние от врага до замка
		var distance_to_castle = enemy.global_position.distance_to(castle.global_position)

		if distance_to_castle < best_distance_to_castle:
			best_distance_to_castle = distance_to_castle
			best_enemy = enemy

	return best_enemy

func attack(enemy):
	if uses_projectile and projectile_scene:
		var projectile = projectile_scene.instantiate()
		var projectiles = get_tree().current_scene.get_node("Projectiles")
		projectiles.add_child(projectile)
		projectile.global_position = global_position
		projectile.direction = (enemy.global_position - global_position).normalized()
		projectile.target = enemy
		projectile.damage = damage
		projectile.speed = projectile_speed
		projectile.max_distance = attack_range + 60
	else:
		enemy.take_damage(damage)
		print("Рыцарь атаковал врага на ", damage, " урона")
# Обновление характеристик по уровню
func update_stats():
	damage = damage_by_level[upgrade_level - 1]
	attack_range = attack_range_by_level[upgrade_level - 1]
	attack_cooldown = attack_cooldown_by_level[upgrade_level - 1]

# Улучшение рыцаря
func upgrade():
	if upgrade_level >= 3:
		print("Рыцарь уже максимального уровня")
		return

	upgrade_level += 1
	update_stats()
	update_attack_range_circle()
	update_sprite()

	print("Рыцарь улучшен до уровня ", upgrade_level)
	print("Урон: ", damage)
	print("Радиус: ", attack_range)
	print("Перезарядка: ", attack_cooldown)

func _on_attack_range_input_event(viewport, event, shape_idx):
	if is_preview:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Рыцарь выбран")

func update_attack_range_circle():
	var points = PackedVector2Array()
	for i in range(65):
		var angle = TAU * i / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * attack_range)
	attack_range_circle.points = points

func update_sprite():
	if upgrade_level == 1:
		$KnightSprite.texture = texture_level_1
	elif upgrade_level == 2:
		$KnightSprite.texture = texture_level_2
	else:
		$KnightSprite.texture = texture_level_3
