extends SceneTree

func _initialize() -> void:
	call_deferred("capture_views")

func capture_views() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.progress.path = "user://visual_preview.json"
	for sample in [{"level": 1, "kind": "smash"}, {"level": 2, "kind": "fly"}, {"level": 5, "kind": "swim"}, {"level": 6, "kind": "shield"}, {"level": 9, "kind": "climb"}]:
		game.start_race(sample.level)
		game.paused = true
		var obstacle: Dictionary = game.level.obstacles[0]
		for i in range(game.racers.size()):
			var racer: AnimalRacer = game.racers[i]
			racer.switch_to(racer.correct_animal(sample.kind))
			racer.distance = obstacle.start - 7.0 + (i - 1) * 2.5
			if sample.kind in ["swim", "climb", "shield", "fly"]:
				racer.distance = obstacle.start + obstacle.span * 0.35 + (i - 1) * 2.5
				racer.traversal_kind = sample.kind
				racer.position.y = racer.traversal_height(0.35)
				racer.play_clip("ability")
				racer.wake.visible = sample.kind == "swim"
				racer.wake.position.y = -0.20 - racer.position.y
			racer.position.x = racer.lane
			racer.position.y += game.level.height_at(racer.distance)
			racer.position.z = -racer.distance
			racer.dust.emitting = sample.kind == "smash"
		game.countdown_label.hide()
		game.hint.text = {"smash": "Rhino • smash the rock wall", "fly": "Owl • fly across the cliff", "swim": "Otter • swim across the river", "shield": "Turtle • shelter under your shell", "climb": "Monkey • climb through the trees"}[sample.kind]
		game.refresh_buttons()
		game.hint.hide()
		game.update_camera(0)
		game.race_progress.queue_redraw()
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		var suffix := "" if get_root().size.x == 540 else "-%dx%d" % [get_root().size.x, get_root().size.y]
		get_root().get_texture().get_image().save_png("res://../tools/screenshots/visual-%s%s.png" % [sample.kind, suffix])
		print("VISUAL_CAPTURE ", sample.kind)
	quit()
