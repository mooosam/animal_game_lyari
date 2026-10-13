class_name RaceProgress
extends Control

var course_length: float = 360.0
var racers: Array[AnimalRacer] = []

func marker_position(distance: float) -> Vector2:
	return Vector2(lerpf(12.0, size.x - 12.0, clampf(distance / course_length, 0.0, 1.0)), 20.0)

func _draw() -> void:
	if size.x < 40:
		return
	var start := marker_position(0)
	var end := marker_position(course_length)
	draw_line(start, end, Color(1, 1, 1, 0.8), 4, true)
	draw_circle(start, 3, Color.WHITE, true, -1, true)
	draw_circle(end, 3, Color.WHITE, true, -1, true)
	# Paint the player last so its exact position remains easy to identify.
	for i in [1, 2, 0]:
		if i >= racers.size() or not is_instance_valid(racers[i]):
			continue
		var racer := racers[i]
		var center := marker_position(racer.distance)
		var line_position := center
		var crowded := false
		for other in racers:
			if other != racer and is_instance_valid(other) and absf(marker_position(other.distance).x - center.x) < 31:
				crowded = true
		if crowded and i != 0:
			center.y += -18 if i == 1 else 18
		var radius := 11.0 if i == 0 else 9.0
		var tint: Color = [Color("57d785"), Color("f37c83"), Color("ffc25b")][i]
		if center != line_position:
			draw_line(line_position, center, tint, 2, true)
		draw_circle(center, radius + 2, Color("ffffff"), true, -1, true)
		draw_circle(center, radius, tint, true, -1, true)
		var portrait: Texture2D = racer.animals[racer.chosen].portrait
		draw_texture_rect(portrait, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), false)
		if i == 0:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-4, 19), center + Vector2(4, 19), center + Vector2(0, 24)]), tint)
