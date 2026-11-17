extends Node2D

const ANGER_SHADER = preload("res://assets/shaders/enemy_anger.gdshader")
@onready var body = $Body
@onready var animated_sprite = $Body/AnimatedSprite2D

@export var speed: float = 100.0
@export var health: int = 100
@export var reward: int = 10
@export var castle_damage: int = 10
@export var voice_sound: StringName = &""

# Параметры визуального эффекта получения урона
@export var shake_duration: float = 0.25
@export var shake_amplitude: float = 4.0
@export var flash_duration: float = 0.12
@export var flash_color: Color = Color(1.0, 0.4, 0.4, 1.0)

# Параметры визуального эффекта смерти
@export var death_pause: float = 0.12
@export var death_particle_count: int = 28
@export var death_explosion_duration: float = 0.5
@export var death_particle_size: int = 3

var path_points: PackedVector2Array
var current_point: int = 0
var current_facing: String = "down"
var body_start_position: Vector2
var damage_tween: Tween
var is_dead: bool = false
var variant_tier: int = 0


func apply_variant(tier: int) -> void:
	assert(not is_node_ready(), "Configure variants before adding the enemy to the tree")
	variant_tier = clampi(tier, 0, WaveCatalog.TIERS.size() - 1)
	var variant: Dictionary = WaveCatalog.TIERS[variant_tier]
	health = roundi(health * variant.health)
	speed *= variant.speed
	reward = roundi(reward * variant.reward)
	castle_damage = roundi(castle_damage * variant.damage)
	# Scale the parent body, preserving the werewolf's independent facing correction.
	var visual: Control = get_node("Body")
	visual.pivot_offset = Vector2(15, 55)
	visual.scale = Vector2.ONE * variant.size
	if variant.angry:
		var rage := ShaderMaterial.new()
		rage.shader = ANGER_SHADER
		get_node("Body/AnimatedSprite2D").material = rage

func _ready():
	# The legacy off-map test instance has no path and must never consume attacks or wave counts.
	if path_points.is_empty():
		remove_from_group("enemies")
	else:
		add_to_group("enemies")
	body_start_position = body.position
	animated_sprite.play("walk_" + current_facing)

func setup_path(points: PackedVector2Array):
	path_points = points
	current_point = 0

	if path_points.size() > 0:
		add_to_group("enemies")
		global_position = path_points[0]
		SoundManager.play(voice_sound)


func _process(delta):
	if is_dead:
		return

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
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()
	else:
		SoundManager.play(voice_sound)
		play_damage_effect()


func play_damage_effect():
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()

	body.position = body_start_position
	animated_sprite.modulate = flash_color

	damage_tween = create_tween()
	damage_tween.set_parallel(true)
	damage_tween.tween_method(shake_body, 0.0, 1.0, shake_duration)
	damage_tween.tween_property(animated_sprite, "modulate", Color.WHITE, flash_duration)
	damage_tween.chain().tween_callback(finish_damage_effect)


# Трясем только визуальный узел, не корень врага
func shake_body(_progress: float):
	body.position = body_start_position + Vector2(
		randf_range(-shake_amplitude, shake_amplitude),
		randf_range(-shake_amplitude, shake_amplitude)
	)


func finish_damage_effect():
	body.position = body_start_position
	animated_sprite.modulate = Color.WHITE


func die():
	if is_dead:
		return

	is_dead = true
	remove_from_group("enemies")

	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()

	body.position = body_start_position
	animated_sprite.modulate = Color.WHITE
	animated_sprite.stop()

	var main = get_tree().current_scene

	if main.has_method("add_gold"):
		main.add_gold(reward)

	if main.has_method("enemy_finished"):
		main.enemy_finished()

	# Tween привязан к врагу и автоматически остановится при его удалении
	var death_tween = create_tween()
	death_tween.tween_interval(death_pause)
	death_tween.tween_callback(play_death_explosion)
	death_tween.tween_interval(death_explosion_duration)
	death_tween.tween_callback(queue_free)


func play_death_explosion():
	animated_sprite.hide()

	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = death_particle_count
	particles.lifetime = death_explosion_duration
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector2.RIGHT
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2.ZERO
	particles.color = Color(1.0, 0.5, 0.2, 1.0)

	# Квадратная текстура создаётся в памяти, без файла в assets
	var image = Image.create_empty(
		death_particle_size,
		death_particle_size,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(image)

	# Альфа постепенно уменьшается, и частицы исчезают к концу жизни
	var gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = gradient

	add_child(particles)
	particles.emitting = true


func reach_castle():
	if is_dead:
		return
	# queue_free is deferred: remove it from combat immediately to prevent a second finish/reward.
	is_dead = true
	remove_from_group("enemies")

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
