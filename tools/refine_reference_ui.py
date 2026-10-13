from pathlib import Path
path=Path(__file__).resolve().parents[1]/'game/scripts/main.gd'
text=path.read_text(encoding='utf-8')
start=text.index('func build_hud() -> void:')
end=text.index('func choose(id:',start)
text=text[:start]+'''func build_hud() -> void:
	race_progress = RaceProgress.new()
	ui.add_child(race_progress)
	race_progress.anchor_left = 0.22
	race_progress.anchor_right = 0.80
	race_progress.anchor_top = 0.08
	race_progress.anchor_bottom = 0.08
	race_progress.offset_bottom = 55
	race_progress.course_length = level.length
	race_progress.racers = racers
	race_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status = label("LEVEL %d" % level.number, 21, Color.WHITE)
	ui.add_child(status)
	status.anchor_left = 0.34
	status.anchor_right = 0.68
	status.anchor_top = 0.035
	status.anchor_bottom = 0.072
	status.add_theme_color_override("font_outline_color", Color("619b76"))
	status.add_theme_constant_override("outline_size", 6)
	var pause := button("Ⅱ", show_pause, Color(0.20, 0.42, 0.32, 0.50))
	pause.custom_minimum_size = Vector2(44, 44)
	ui.add_child(pause)
	pause.anchor_left = 0.04
	pause.anchor_right = 0.13
	pause.anchor_top = 0.033
	pause.anchor_bottom = 0.079
	pause.add_theme_color_override("font_color", Color.WHITE)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	ui.add_child(buttons)
	buttons.anchor_left = 0.06
	buttons.anchor_right = 0.94
	buttons.anchor_top = 0.80
	buttons.anchor_bottom = 0.935
	for id in level.team:
		var b := AnimalChoiceButton.new()
		b.animal = animals[id]
		b.tooltip_text = "%s • %s" % [animals[id].title, animals[id].ability.to_upper()]
		b.custom_minimum_size = Vector2(80, 100)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(choose.bind(id))
		buttons.add_child(b)
		animal_buttons.append(b)
	hint = label("", 20, Color.WHITE)
	ui.add_child(hint)
	hint.anchor_left = 0.08
	hint.anchor_right = 0.92
	hint.anchor_top = 0.72
	hint.anchor_bottom = 0.77
	hint.add_theme_color_override("font_outline_color", INK)
	hint.add_theme_constant_override("outline_size", 6)
	countdown_label = label("3", 90, CREAM)
	ui.add_child(countdown_label)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -170
	countdown_label.offset_right = 170
	countdown_label.offset_top = -100
	countdown_label.offset_bottom = 50
	countdown_label.add_theme_color_override("font_outline_color", INK)
	countdown_label.add_theme_constant_override("outline_size", 12)
	refresh_buttons()

''' + text[end:]
start=text.index('func refresh_buttons() -> void:')
end=text.index('func _process(',start)
text=text[:start]+'''func refresh_buttons() -> void:
	for i in range(animal_buttons.size()):
		var b := animal_buttons[i] as AnimalChoiceButton
		var id: String = level.team[i]
		b.selected = player.chosen == id
		b.suggested = player.waiting and progress.gentle and player.obstacle_index < level.obstacles.size() and animals[id].ability == level.obstacles[player.obstacle_index].kind
		b.disabled = player.finish_time >= 0
		b.queue_redraw()

''' + text[end:]
text=text.replace('status.text = "Level %d • %s • %d/3" % [level.number, "Gentle" if progress.gentle else "Challenge", ahead + 1]','status.text = "LEVEL %d" % level.number')
text=text.replace('\trefresh_buttons()\n\tupdate_camera(delta)','\thint.visible = player.waiting or (progress.gentle and elapsed < 3.0)\n\trefresh_buttons()\n\tupdate_camera(delta)')
path.write_text(text,encoding='utf-8')
