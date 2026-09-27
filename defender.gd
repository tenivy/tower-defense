extends Node2D

var is_preview: bool = false

@export var damage: int = 20
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 100.0

var attack_timer: float = 0.0


func _process(delta):
	if is_preview:
		return

	if attack_timer > 0:
		attack_timer -= delta
		return

	var enemy = find_nearest_enemy()

	if enemy:
		attack(enemy)
		attack_timer = attack_cooldown


func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")

	var nearest_enemy = null
	var nearest_distance = INF

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	if nearest_distance <= attack_range:
		return nearest_enemy

	return null


func attack(enemy):
	enemy.take_damage(damage)
	print("Рыцарь атаковал врага на ", damage, " урона")
