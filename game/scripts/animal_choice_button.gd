class_name AnimalChoiceButton
extends Button

var animal: AnimalDefinition
var selected: bool = false
var suggested: bool = false

func _ready() -> void:
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func stone_rect(rect: Rect2, cut: float) -> PackedVector2Array:
	var a := rect.position
	var b := rect.end
	return PackedVector2Array([a + Vector2(cut, 0), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), b - Vector2(0, cut), b - Vector2(cut, 0), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), a + Vector2(0, cut)])

func _draw() -> void:
	if animal == null: return
	var frame := Rect2(Vector2(4, 4), size - Vector2(8, 10))
	if selected or suggested:
		draw_colored_polygon(stone_rect(Rect2(Vector2.ZERO, size - Vector2(0, 3)), 13), Color("c5ed35") if selected else Color("ffe775"))
	draw_colored_polygon(stone_rect(Rect2(frame.position + Vector2(0, 6), frame.size), 9), Color("536466"))
	draw_colored_polygon(stone_rect(frame, 9), Color("9aa4a6"))
	var face := Rect2(frame.position + Vector2(5, 4), frame.size - Vector2(10, 10))
	draw_colored_polygon(stone_rect(face, 6), Color("c4c9ca") if not is_pressed() else Color("abb3b5"))
	var rim := stone_rect(face, 6)
	for i in range(4): draw_line(rim[i], rim[(i + 1) % rim.size()], Color("eff3ed"), 2, true)
	# Small stone chips give the frame an original, hand-shaped silhouette.
	draw_line(Vector2(6, size.y * 0.34), Vector2(12, size.y * 0.40), Color("eff3ed"), 2, true)
	draw_line(Vector2(size.x - 7, size.y * 0.68), Vector2(size.x - 13, size.y * 0.73), Color("667477"), 2, true)
	var icon := Rect2(Vector2(11, 8), size - Vector2(22, 23))
	draw_texture_rect(animal.portrait, icon, false, Color(1, 1, 1, 0.7 if disabled else 1.0))
	draw_string(get_theme_default_font(), Vector2(size.x - 22, size.y - 14), animal.symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color("425d54"))
