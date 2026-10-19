extends Node2D

var is_preview: bool = false
var attack_range_circle: Line2D
var current_facing: String = "right"

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

@export var uses_projectile: bool = false
@export var projectile_scene: PackedScene = null
@export var projectile_speed: float = 600.0

@export var idle_frame: int = 0
@export var mirrored_facing: bool = true

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
	
	update_sprite()

func _process(delta):
	if is_preview:
		return

	if attack_timer > 0:
		attack_timer -= delta

	var enemy = find_nearest_enemy()

	if enemy:
		update_facing(enemy.global_position)
		update_sprite()

		if attack_timer <= 0:
			attack(enemy)
			attack_timer = attack_cooldown
	else:
		stop_sprite()

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")

	var best_enemy = null
	var best_progress = -1

	for enemy in enemies:
		var distance_to_defender = global_position.distance_to(enemy.global_position)

		# Враг должен находиться в радиусе атаки
		if distance_to_defender > attack_range:
			continue

		# Прогресс врага по дороге (чем больше, тем опаснее)
		var progress = enemy.get_progress()

		if progress > best_progress:
			best_progress = progress
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

func update_stats():
	damage = damage_by_level[upgrade_level - 1]
	attack_range = attack_range_by_level[upgrade_level - 1]
	attack_cooldown = attack_cooldown_by_level[upgrade_level - 1]

# Улучшение рыцаря
func upgrade():
	if upgrade_level >= 3:
		return

	upgrade_level += 1
	update_stats()
	update_attack_range_circle()
	update_sprite()

func update_attack_range_circle():
	var points = PackedVector2Array()
	for i in range(65):
		var angle = TAU * i / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * attack_range)
	attack_range_circle.points = points

func update_sprite():
	$KnightSprite.play("level_" + str(upgrade_level) + "_" + current_facing)

# Ракурсы в анимации направлены противоположно,
# поэтому left/right и up/down назначаются наоборот.
# Выбирает один из 4 ракурсов по позиции цели
# Выбирает один из 4 ракурсов по позиции цели
func update_facing(target_position: Vector2):
	var direction = (target_position - global_position).normalized()
	var new_facing: String
	if abs(direction.x) > abs(direction.y):
		new_facing = "right" if direction.x > 0 else "left"
	else:
		new_facing = "down" if direction.y > 0 else "up"
	if mirrored_facing:
		# Арт рыцаря направлен противоположно сторонам света
		match new_facing:
			"right":
				new_facing = "left"
			"left":
				new_facing = "right"
			"up":
				new_facing = "down"
			"down":
				new_facing = "up"
	if new_facing != current_facing:
		current_facing = new_facing
		update_sprite()

# Бездействие: показываем выбранный статичный кадр
func stop_sprite():
	$KnightSprite.stop()
	$KnightSprite.frame = idle_frame
