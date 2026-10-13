extends Node

const INK := Color("20464c")
const CREAM := Color("fff6dc")
const CAMERA_OFFSET := Vector3(6.8, 6.0, 9.2)
const CAMERA_TARGET_OFFSET := Vector3(-1.7, 0.2, -2.4)
var animals: Dictionary = {}
var progress := ProgressStore.new()
var audio: AnimalAudio
var world: Node3D
var camera: Camera3D
var course: AnimalCourse
var ui: Control
var overlay: Control
var player: AnimalRacer
var racers: Array[AnimalRacer] = []
var level: LevelDefinition
var elapsed: float = 0.0
var countdown: float = 3.0
var state: String = "home"
var animal_buttons: Array[Button] = []
var hint: Label
var status: Label
var race_progress: RaceProgress
var countdown_label: Label
var paused: bool = false
var feedback_timer: float = 0.0
var automation: bool = false
var automation_level: int = 1
var screenshot_path: String = ""
var screenshot_taken: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-level="):
			progress.path = "user://automation_progress.json"
	progress.read()
	animals = AnimalCatalog.definitions()
	audio = AnimalAudio.new()
	add_child(audio)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	get_viewport().size_changed.connect(layout_safe_area)
	build_world()
	show_home()
	apply_audio()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-level="):
			automation = true
			automation_level = clampi(int(arg.split("=")[1]), 1, 100)
		if arg.begins_with("--screenshot="):
			screenshot_path = arg.trim_prefix("--screenshot=")
	if automation:
		start_race(automation_level)
	layout_safe_area.call_deferred()

func build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("98efd5")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("ffffff")
	settings.ambient_light_energy = 0.28
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	settings.fog_enabled = true
	settings.fog_light_color = Color("98efd5")
	settings.fog_density = 0.014
	env.environment = settings
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 0.40
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	world.add_child(sun)
	camera = Camera3D.new()
	camera.fov = 50
	camera.far = 100
	world.add_child(camera)
	camera.current = true

func preview_course() -> void:
	clear_race()
	level = LevelDefinition.create(1)
	course = AnimalCourse.new()
	world.add_child(course)
	course.build(level)
	var mascot := AnimalRacer.new()
	world.add_child(mascot)
	mascot.setup(animals, level.team, 0)
	mascot.name_tag.hide()
	mascot.name_pointer.hide()
	mascot.dust.emitting = false
	mascot.position = Vector3(0, 0, -12)
	mascot.rotation.y = PI * 0.85
	racers.append(mascot)
	camera.position = Vector3(7, 7, -3)
	camera.look_at(Vector3(0, 0.8, -12))

func clear_race() -> void:
	if is_instance_valid(course):
		course.queue_free()
	for racer in racers:
		racer.queue_free()
	racers.clear()
	player = null

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	animal_buttons.clear()
	overlay = null

func style(color: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(22)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func label(text: String, size: int = 26, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func button(text: String, action: Callable, color: Color = CREAM) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 66)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", INK)
	b.add_theme_stylebox_override("normal", style(color))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.1), Color("47bc9a"), 3))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.1)))
	b.add_theme_stylebox_override("disabled", style(color))
	b.pressed.connect(func():
		audio.tone(560)
		action.call())
	return b

func panel_box(top: float, bottom: float, tint: Color = Color(1, 0.97, 0.88, 0.97)) -> VBoxContainer:
	var panel := PanelContainer.new()
	ui.add_child(panel)
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = top
	panel.anchor_bottom = bottom
	panel.add_theme_stylebox_override("panel", style(tint))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	return box

func show_home() -> void:
	state = "home"
	paused = false
	clear_ui()
	clear_race()
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/ui/jungle_menu.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := label("ANIMAL\nSWITCH", 58, CREAM)
	ui.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 70
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 10)
	var library_button := button("Meet all 50 animals", func(): get_tree().change_scene_to_file("res://animal_library.tscn"), Color("a3e887"))
	ui.add_child(library_button)
	library_button.anchor_left = 0.20
	library_button.anchor_right = 0.80
	library_button.anchor_top = 0.34
	library_button.anchor_bottom = 0.34
	library_button.offset_bottom = 52
	var box := panel_box(0.53, 0.95)
	box.add_child(label("Little paws. Big adventures.", 24))
	box.add_child(button("PLAY  →", func(): start_race(mini(progress.highest, 100)), Color("a3e887")))
	box.add_child(button("Choose a level", show_levels))
	box.add_child(button("Mode: " + ("Gentle" if progress.gentle else "Challenge"), func():
		progress.gentle = not progress.gentle
		progress.write()
		show_home()))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	for key in ["sound", "music"]:
		var setting_key: String = key
		var b := button(key.capitalize() + (": ON" if progress.get(key) else ": OFF"), func():
			progress.set(setting_key, not progress.get(setting_key))
			progress.write()
			apply_audio()
			show_home())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	box.add_child(label("Tap an animal. Match its power. Race!", 18))

func apply_audio() -> void:
	audio.enabled = progress.sound
	audio.music_enabled = progress.music
	if progress.music:
		if not audio.music_player.playing:
			audio.music_player.play()
	else:
		audio.music_player.stop()

func show_levels() -> void:
	state = "levels"
	clear_ui()
	var box := panel_box(0.07, 0.96)
	box.add_child(label("YOUR ADVENTURE", 32))
	box.add_child(label("Finish races to meet new friends", 19))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for n in range(1, 101):
		var item := LevelDefinition.create(n)
		var locked := n > progress.highest
		var b := button(("LOCKED  " if locked else "%02d  " % n) + item.title, func(): start_race(item.number), Color("e4e8de") if locked else CREAM)
		b.disabled = locked
		list.add_child(b)
	box.add_child(label("Complete three races to reveal the next animal • %d / 50 friends met" % progress.unlocked_animals.size(), 16))
	box.add_child(button("← Home", show_home))

func start_race(n: int) -> void:
	clear_ui()
	clear_race()
	paused = false
	state = "race"
	level = LevelDefinition.create(n)
	elapsed = 0.0
	countdown = 3.0
	feedback_timer = 0.0
	course = AnimalCourse.new()
	world.add_child(course)
	course.build(level)
	for i in range(3):
		var racer := AnimalRacer.new()
		world.add_child(racer)
		racer.racer_tint = [Color.WHITE, Color("ef8b70"), Color("d6c44f")][i]
		racer.setup(animals, level.team, [0.0, -3.0, 3.0][i])
		racer.name_tag.text = ["YOU", "PIP", "KIKI"][i]
		racer.name_tag.font_size = 48 if i == 0 else 28
		racer.name_pointer.font_size = 35 if i == 0 else 22
		racer.name_tag.visibility_range_end = 45
		racer.name_pointer.visibility_range_end = 45
		if i != 0:
			racer.distance = 6.0 if i == 1 else 8.0
			racer.position.z = -racer.distance
		racers.append(racer)
	player = racers[0]
	course.racers = racers
	build_hud()
	update_camera(1.0)
	audio.tone(400)

func build_hud() -> void:
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

func choose(id: String) -> void:
	if paused or state != "race":
		return
	if player.switch_to(id):
		audio.tone(650)
		refresh_buttons()

func refresh_buttons() -> void:
	for i in range(animal_buttons.size()):
		var b := animal_buttons[i] as AnimalChoiceButton
		var id: String = level.team[i]
		b.selected = player.chosen == id
		b.suggested = player.waiting and progress.gentle and player.obstacle_index < level.obstacles.size() and animals[id].ability == level.obstacles[player.obstacle_index].kind
		b.disabled = player.finish_time >= 0
		b.queue_redraw()

func _process(delta: float) -> void:
	if state != "race" or paused:
		return
	if countdown > 0.0:
		countdown -= delta
		countdown_label.text = str(ceili(countdown)) if countdown > 0.0 else "GO!"
		if countdown <= 0.0:
			countdown_label.hide()
		return
	elapsed += delta
	feedback_timer = maxf(0, feedback_timer - delta)
	if automation and player.obstacle_index < level.obstacles.size():
		player.switch_to(player.correct_animal(level.obstacles[player.obstacle_index].kind))
	var blocked := progress.gentle and player.waiting
	for i in range(racers.size()):
		var racer := racers[i]
		var speed := 6.2 if i == 0 else 6.0 if i == 1 else 6.1
		if not progress.gentle and i != 0:
			speed = 5.75 if i == 1 else 5.95
		if blocked and i != 0:
			speed *= 0.12
		if progress.gentle and i != 0 and racer.distance > player.distance + 10:
			speed *= 0.35
		var index_before := racer.obstacle_index
		var event := racer.step(delta, level, speed, progress.gentle, i != 0, elapsed)
		if event == "cross" and level.obstacles[index_before].kind == "smash":
			course.smash(index_before, [1, 0, 2][i])
		if i == 0:
			if event == "wrong":
				audio.tone(220, 0.25)
				feedback_timer = 2.0
			elif event == "cross":
				audio.tone(850)
			elif event == "finish":
				show_results()
				return
	race_progress.queue_redraw()
	var ahead := 0
	for racer in racers:
		if racer != player and racer.distance > player.distance:
			ahead += 1
	status.text = "LEVEL %d" % level.number
	if player.obstacle_index < level.obstacles.size():
		var next: Dictionary = level.obstacles[player.obstacle_index]
		var id := player.correct_animal(next.kind)
		if player.waiting:
			hint.text = "Try %s! %s" % [animals[id].title, animals[id].symbol] if progress.gentle else "Pick a new animal!" + ("  +2 seconds" if feedback_timer > 0 else "")
		elif player.traversal > 0:
			hint.text = {"smash": "SMASH! Great choice!", "fly": "Up and away!", "jump": "Hop! Great choice!", "swim": "Splash! Great choice!", "shield": "Safe under your shell!", "climb": "Climb through the canopy!"}[player.traversal_kind]
		else:
			hint.text = "Ahead: " + next.kind.to_upper() + ("  •  " + animals[id].title if progress.gentle and next.start - player.distance < 25 else "")
	else:
		hint.text = "The finish is ahead!"
	hint.visible = player.waiting or (progress.gentle and elapsed < 3.0)
	refresh_buttons()
	update_camera(delta)
	if screenshot_path != "" and not screenshot_taken and elapsed > 6:
		screenshot_taken = true
		capture.call_deferred(screenshot_path)

func update_camera(_delta: float) -> void:
	# A constant player-relative offset. Opponent positions never affect framing.
	camera.global_position = player.global_position + CAMERA_OFFSET
	camera.look_at(player.global_position + CAMERA_TARGET_OFFSET)

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("SCREENSHOT ", path)

func show_pause() -> void:
	if state != "race" or paused:
		return
	paused = true
	course.effects_paused = true
	for racer in racers:
		if racer.animation:
			racer.animation.pause()
		racer.dust.emitting = false
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.15, 0.17, 0.6)
	ui.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay = backdrop
	var panel := PanelContainer.new()
	backdrop.add_child(panel)
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.32
	panel.anchor_bottom = 0.69
	panel.add_theme_stylebox_override("panel", style(CREAM))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	box.add_child(label("Take a little break", 31))
	box.add_child(button("Keep racing →", resume))
	box.add_child(button("Restart", func(): start_race(level.number)))
	box.add_child(button("Home", show_home))

func resume() -> void:
	paused = false
	course.effects_paused = false
	if is_instance_valid(overlay):
		overlay.queue_free()
	for racer in racers:
		if racer.animation:
			racer.animation.play()

func show_results() -> void:
	state = "results"
	var place := 1
	for racer in racers:
		if racer != player and racer.finish_time >= 0 and racer.finish_time < player.finish_time:
			place += 1
	var unlock := progress.complete(level.number, place)
	clear_ui()
	audio.tone(1046, 0.5)
	var box := panel_box(0.24, 0.91)
	var success := progress.gentle or place == 1
	box.add_child(label("YOU DID IT!" if success else "GOOD RACE!", 42))
	box.add_child(label("Place %d of 3  •  %.1f seconds" % [place, elapsed], 23))
	box.add_child(label("Every animal has a special power.", 20))
	if unlock != "":
		var portrait := TextureRect.new()
		portrait.texture = animals[unlock].portrait
		portrait.custom_minimum_size.y = 150
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(portrait)
		box.add_child(label("NEW FRIEND: " + animals[unlock].title.to_upper(), 28))
		box.add_child(label("Power: " + animals[unlock].ability.to_upper(), 22))
	if success and level.number < 100:
		box.add_child(button("Next adventure →", func(): start_race(level.number + 1), Color("a3e887")))
	elif success:
		box.add_child(label("All 100 adventures complete!", 26))
	else:
		box.add_child(label("Finish first to open the next adventure", 19))
	box.add_child(button("Race again", func(): start_race(level.number)))
	box.add_child(button("Choose a level", show_levels))
	box.add_child(button("Home", show_home))
	if automation:
		print("AUTORACE_PASS level=", level.number, " place=", place, " seconds=", elapsed, " fps=", Engine.get_frames_per_second())
		get_tree().quit(0)

func layout_safe_area() -> void:
	# Percentage-based panels remain inside the safe region on phones and tablets.
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0 and screen.y > 0:
			ui.offset_top = float(safe.position.y) / screen.y * get_viewport().get_visible_rect().size.y
			ui.offset_bottom = -float(screen.y - safe.end.y) / screen.y * get_viewport().get_visible_rect().size.y

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "race" and not automation:
		show_pause()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "race":
			if paused:
				resume()
			else:
				show_pause()
		else:
			show_home()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			if paused:
				resume()
			elif state == "race":
				show_pause()
			else:
				show_home()
		if state == "race" and not paused:
			for i in range(3):
				if event.keycode == KEY_1 + i:
					choose(level.team[i])
