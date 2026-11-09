extends Node
## Contours use source-image coordinates, independent of Main/Map transforms.

const CONTOURS = preload("res://assets/maps/level-01-placement.tres")

@onready var terrain: Sprite2D = get_parent()


func get_terrain_at(world_position: Vector2) -> String:
	var rect := terrain.get_rect()
	var pixel := terrain.to_local(world_position) - rect.position
	if not Rect2(Vector2.ZERO, rect.size).has_point(pixel):
		return "outside"
	if terrain.flip_h:
		pixel.x = rect.size.x - pixel.x
	if terrain.flip_v:
		pixel.y = rect.size.y - pixel.y
	# Keep the contour registration when the sprite's displayed frame is resized.
	pixel *= Vector2(CONTOURS.get_meta("source_size")) / rect.size
	# Foreground castle/trees take precedence over the river behind them.
	var zones: Array = CONTOURS.get_meta("zones")
	for index in range(zones.size() - 1, -1, -1):
		var zone: Dictionary = zones[index]
		if Geometry2D.is_point_in_polygon(pixel, zone["polygon"]):
			return zone["kind"]
	return ""


func is_blocked(world_position: Vector2) -> bool:
	return not get_terrain_at(world_position).is_empty()
