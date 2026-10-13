class_name AnimalRacer
extends Node3D

var animals: Dictionary
var team: PackedStringArray
var chosen: String
var distance: float = 0.0
var obstacle_index: int = 0
var traversal: float = 0.0
var traversal_start: float = 0.0
var traversal_span: float = 0.0
var traversal_kind: String = ""
var penalty: float = 0.0
var waiting: bool = false
var finish_time: float = -1.0
var visual: Node3D
var animation: AnimationPlayer
var models: Dictionary = {}
var lane: float = 0.0
var ai_delay: float = -1.0
var current_clip: String = ""
var wake: MeshInstance3D
var traversal_base_start: float = 0.0
var traversal_base_end: float = 0.0
var traversal_progress: float = 0.0
var name_tag: Label3D
var name_pointer: Label3D
var dust: CPUParticles3D
var racer_tint: Color = Color.WHITE
var gait_time: float = 0.0
var landing_pulse: float = 0.0
var splash: CPUParticles3D

func _process(delta: float) -> void:
	# Keep the camera on the stable racer root; anatomical motion belongs to the model.
	if visual == null or animation == null or not animation.is_playing():
		if splash != null: splash.emitting = false
		return
	if splash != null:
		splash.emitting = traversal > 0 and traversal_kind == "swim" and not waiting
	var moving := not waiting and penalty <= 0 and finish_time < 0
	if not moving:
		visual.position.y = lerpf(visual.position.y, 0.35 if chosen == "owl" else 0.0, minf(delta * 12, 1))
		visual.rotation.x = lerpf(visual.rotation.x, 0, minf(delta * 12, 1))
		return
	var period: float = animals[chosen].cycle_seconds
	var phase := fposmod(gait_time / period, 1.0)
	var wave := sin(phase * TAU)
	visual.position.y = 0.0
	visual.rotation.x = 0.0
	visual.rotation.z = 0.0
	if chosen == "frog" and traversal <= 0:
		if current_clip == "run":
			animation.seek(phase * animation.current_animation_length, true)
		# The exported frog rig owns the crouch, hind-leg push, tuck and landing.
		# Keep the model root steady so its body and feet articulate independently.
		dust.emitting = phase > 0.82 and phase < 0.94
	elif chosen == "owl":
		visual.position.y = 0.48 + wave * (0.07 if traversal > 0 else 0.12)
		visual.rotation.x = wave * 0.018
	elif chosen == "otter" and traversal > 0 and traversal_kind == "swim":
		visual.position.y = wave * 0.045
		visual.rotation.z = wave * 0.045
		visual.rotation.x = cos(phase * TAU) * 0.035
	elif chosen in ["elephant", "turtle"]:
		visual.rotation.z = wave * 0.018
	elif chosen == "monkey":
		visual.rotation.z = wave * 0.035
		visual.rotation.x = -0.18 if traversal > 0 and traversal_kind == "climb" else 0.02
	else:
		visual.rotation.z = wave * 0.022

func setup(definitions: Dictionary, lineup: PackedStringArray, x: float) -> void:
	animals = definitions
	team = lineup
	lane = x
	for id in team:
		var model: Node3D = animals[id].model.instantiate()
		add_child(model)
		model.rotation.y = PI
		model.scale = Vector3.ONE * animals[id].model_scale
		if id == "otter": model.scale.x *= 1.6
		var outline := ShaderMaterial.new()
		outline.shader = load("res://assets/animal_outline.gdshader")
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source = mesh.mesh.surface_get_material(surface)
				if source is StandardMaterial3D:
					var mat: StandardMaterial3D = source.duplicate()
					mat.vertex_color_use_as_albedo = false
					mat.next_pass = outline
					mat.roughness = 0.75
					mat.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
					if racer_tint != Color.WHITE and mat.albedo_color.s > 0.1:
						mat.albedo_color = mat.albedo_color.lerp(racer_tint, 0.60)
					mesh.set_surface_override_material(surface, mat)
		model.visible = false
		models[id] = model
	wake = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.80
	ring.outer_radius = 0.92
	ring.rings = 24
	ring.ring_segments = 6
	wake.mesh = ring
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color("daffff")
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wake.material_override = foam
	wake.scale = Vector3(1, 0.1, 1.6)
	add_child(wake)
	wake.hide()
	splash = CPUParticles3D.new()
	splash.amount = 18
	splash.lifetime = 0.55
	splash.local_coords = false
	splash.emitting = false
	splash.position = Vector3(0, 0.2, 0.3)
	splash.direction = Vector3(0, 0.5, 1)
	splash.spread = 45
	splash.gravity = Vector3(0, -4.0, 0)
	splash.initial_velocity_min = 0.7
	splash.initial_velocity_max = 1.4
	splash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	splash.emission_box_extents = Vector3(0.55, 0.02, 0.45)
	var droplet := SphereMesh.new()
	droplet.radius = 0.045
	droplet.height = 0.09
	droplet.radial_segments = 6
	droplet.rings = 3
	droplet.material = foam
	splash.mesh = droplet
	splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(splash)
	name_tag = Label3D.new()
	name_tag.text = "YOU"
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.font_size = 48
	name_tag.pixel_size = 0.010
	name_tag.outline_size = 8
	name_tag.outline_modulate = Color("27392d")
	name_tag.no_depth_test = true
	add_child(name_tag)
	name_pointer = Label3D.new()
	name_pointer.text = "▼"
	name_pointer.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_pointer.font_size = 35
	name_pointer.pixel_size = 0.010
	name_pointer.outline_size = 7
	name_pointer.outline_modulate = Color("27392d")
	name_pointer.no_depth_test = true
	add_child(name_pointer)
	dust = CPUParticles3D.new()
	dust.amount = 12
	dust.lifetime = 0.4
	dust.local_coords = false
	dust.direction = Vector3(0, 0.2, 1)
	dust.spread = 28
	dust.gravity = Vector3(0, 0.2, 0)
	dust.initial_velocity_min = 0.6
	dust.initial_velocity_max = 1.3
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.8
	dust.position = Vector3(0, 0.12, 0.6)
	var puff := SphereMesh.new()
	puff.radius = 0.10
	puff.height = 0.20
	puff.radial_segments = 6
	puff.rings = 3
	var dust_mat := StandardMaterial3D.new()
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.albedo_color = Color(1.0, 0.77, 0.38, 0.30)
	puff.material = dust_mat
	dust.mesh = puff
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)
	switch_to(team[0])
	position = Vector3(lane, 0, -distance)

func switch_to(id: String) -> bool:
	if not id in team or finish_time >= 0.0:
		return false
	if id == chosen and visual != null: return true
	if visual != null:
		visual.visible = false
	chosen = id
	gait_time = 0.0
	visual = models[id]
	visual.visible = true
	visual.position.y = 0.35 if id == "owl" else 0.0
	animation = find_animation(visual)
	current_clip = ""
	play_clip("ability" if traversal > 0 and matches(traversal_kind) else "idle" if waiting else "run")
	var tag_height: float = animals[id].model_height * animals[id].model_scale
	name_tag.position.y = tag_height + 0.6
	name_pointer.position.y = tag_height + 0.16
	return true

func find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := find_animation(child)
		if found != null:
			return found
	return null

func play_clip(clip: String) -> void:
	if animation == null or current_clip == clip:
		return
	for name in animation.get_animation_list():
		if name == clip or name.ends_with("/" + clip):
			animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
			animation.play(name, 0.12)
			current_clip = clip
			return

func matches(kind: String) -> bool:
	return animals[chosen].ability == kind

func correct_animal(kind: String) -> String:
	for id in team:
		if animals[id].ability == kind:
			return id
	return ""

func step(delta: float, level: LevelDefinition, speed: float, gentle: bool, ai: bool, elapsed: float) -> String:
	dust.emitting = chosen != "owl" and traversal <= 0 and penalty <= 0 and not waiting and finish_time < 0
	wake.visible = traversal > 0 and traversal_kind == "swim"
	wake.position.y = level.height_at(distance) - 0.20 - position.y
	if wake.visible:
		wake.scale.x = 1.0 + sin(elapsed * 7) * 0.1
	if finish_time >= 0.0:
		return ""
	if penalty > 0.0:
		penalty = maxf(0.0, penalty - delta)
		play_clip("idle")
		return ""
	var previous_gait_time := gait_time
	gait_time += delta
	if traversal > 0.0:
		if ai and not matches(traversal_kind): switch_to(correct_animal(traversal_kind))
		if not matches(traversal_kind):
			play_clip("idle")
			if not waiting:
				waiting = true
				if not gentle: penalty = 2.0
				return "wrong"
			return ""
		waiting = false
		play_clip("ability")
		var action_speed := speed * 1.25
		traversal_progress = minf(1.0, traversal_progress + delta * action_speed / traversal_span)
		traversal = (1.0 - traversal_progress) * traversal_span / action_speed
		var t := traversal_progress
		distance = traversal_start + traversal_span * t
		position = Vector3(lane, lerpf(traversal_base_start, traversal_base_end, t) + traversal_height(t), -distance)
		if traversal_progress >= 1.0:
			obstacle_index += 1
			if chosen == "frog": gait_time = 0.0
			play_clip("run")
		return ""
	speed *= animals[chosen].run_multiplier
	if chosen == "frog" and delta > 0:
		# Integrate a hop's travel exactly: feet remain planted during crouch and
		# landing, while the airborne phase carries the animal forward.
		var hop_period: float = animals[chosen].cycle_seconds
		var before := previous_gait_time / hop_period
		var after := gait_time / hop_period
		var travel_before := floorf(before) + clampf((fposmod(before, 1.0) - 0.18) / 0.65, 0, 1)
		var travel_after := floorf(after) + clampf((fposmod(after, 1.0) - 0.18) / 0.65, 0, 1)
		speed *= (travel_after - travel_before) * hop_period / delta
	var event := ""
	if obstacle_index < level.obstacles.size():
		var obstacle: Dictionary = level.obstacles[obstacle_index]
		var stop: float = obstacle.start - 1.5
		if ai and distance >= stop - 14.0 and ai_delay == -1.0:
			ai_delay = randf_range(0.2, 1.2) if randf() > 0.12 else 2.8
		if ai and ai_delay >= 0.0:
			ai_delay -= delta
			if ai_delay <= 0.0:
				switch_to(correct_animal(obstacle.kind))
				ai_delay = -2.0
		if distance + speed * delta >= stop:
			distance = stop
			if not matches(obstacle.kind):
				if not waiting:
					event = "wrong"
					if not gentle:
						penalty = 2.0
				waiting = true
				play_clip("idle")
				position = Vector3(lane, level.height_at(distance), -distance)
				return event
			waiting = false
			traversal_start = stop
			traversal_span = obstacle.span + 3.0
			traversal_kind = obstacle.kind
			traversal_base_start = level.height_at(stop)
			traversal_base_end = level.height_at(stop + traversal_span)
			traversal = traversal_span / speed
			traversal_progress = 0.0
			ai_delay = -1.0
			play_clip("ability")
			return "cross"
	waiting = false
	play_clip("run")
	distance = minf(level.length, distance + speed * delta)
	position = Vector3(lane, level.height_at(distance), -distance)
	if distance >= level.length:
		finish_time = elapsed
		play_clip("celebrate")
		return "finish"
	return event

func traversal_height(t: float) -> float:
	match traversal_kind:
		"fly": return sin(t * PI) * 3.2
		"jump": return 4.0 * t * (1.0 - t) * 2.3
		"swim": return -smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.85, 1.0, t)) * 0.38
		"climb": return sin(t * PI) * 3.3
	return 0.0
