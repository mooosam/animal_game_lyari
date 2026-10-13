class_name AnimalLibrary
extends Node3D

var definitions: Array = []
var index: int = 0
var model: Node3D
var animation: AnimationPlayer
var title_label: Label
var details: Label
var clip_choice: OptionButton

func _ready() -> void:
	definitions = AnimalCatalog.definitions().values()
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("dce9dd")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.5
	env.environment = settings
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	light.shadow_enabled = true
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	add_child(floor_mesh)
	var camera := Camera3D.new()
	camera.position = Vector3(4.0, 3.0, 5.5)
	add_child(camera)
	camera.look_at(Vector3(0, 1.4, 0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var column := VBoxContainer.new()
	canvas.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	column.offset_top = 34
	column.offset_left = 24
	column.offset_right = -24
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("20464c"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	details = Label.new()
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_color_override("font_color", Color("20464c"))
	column.add_child(details)
	var row := HBoxContainer.new()
	column.add_child(row)
	for text in ["← Previous", "Next →"]:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size.y = 52
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var increment := -1 if text.begins_with("←") else 1
		b.pressed.connect(func(): index = posmod(index+increment, definitions.size()); show_animal())
		row.add_child(b)
	clip_choice = OptionButton.new()
	clip_choice.custom_minimum_size.y = 52
	clip_choice.item_selected.connect(func(i): play_clip(clip_choice.get_item_text(i)))
	column.add_child(clip_choice)
	var home := Button.new()
	home.text = "Back to game"
	home.custom_minimum_size.y = 52
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	column.add_child(home)
	show_animal()

func show_animal() -> void:
	if model != null: model.free()
	var animal: AnimalDefinition = definitions[index]
	model = animal.model.instantiate()
	add_child(model)
	model.rotation.y = PI
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	title_label.text = "%d / %d  —  %s" % [index+1, definitions.size(), animal.title]
	details.text = "%s • %d movement clips" % [animal.family.capitalize(), animal.clips.size()]
	clip_choice.clear()
	for clip in animal.clips: clip_choice.add_item(clip)
	var selected := animal.clips.find("walk")
	clip_choice.select(selected)
	play_clip("walk")

func play_clip(clip: String) -> void:
	animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play(clip, 0.18)
