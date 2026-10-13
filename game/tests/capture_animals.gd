extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("d9e8d1")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = .45
	env.environment = environment
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = .7
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.8
	camera.position = Vector3(3.8, 2.8, 4.2)
	world.add_child(camera)
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	for id in ["rhino", "owl", "frog", "otter", "elephant", "turtle", "monkey"]:
		var model = load("res://assets/animals/%s.glb" % id).instantiate()
		world.add_child(model)
		await process_frame
		var animation: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		for clip in ["run", "ability"]:
			animation.play(clip)
			animation.pause()
			for phase in range(4):
				animation.seek(animation.get_animation(clip).length * phase / 4, true)
				await process_frame
				await RenderingServer.frame_post_draw
				get_root().get_texture().get_image().save_png("res://../tools/screenshots/animal-%s-%s-%d.png" % [id, clip, phase])
		model.queue_free()
		await process_frame
	print("ANIMAL_ANIMATION_CAPTURES_COMPLETE")
	quit()
