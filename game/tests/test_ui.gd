extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.progress.path = "user://test_ui_progress.json"
	game.progress.highest = 1
	game.progress.gentle = true
	assert(game.state == "home")
	game.show_levels()
	assert(game.state == "levels")
	game.start_race(4)
	assert(game.animal_buttons.size() == 3)
	assert(game.player == game.racers[0])
	game.player.position = Vector3(0, 2.3, -160)
	game.racers[1].position = Vector3(-3, 0, -20)
	game.racers[2].position = Vector3(3, 0, -350)
	game.update_camera(0.016)
	assert(game.camera.global_position.is_equal_approx(game.player.global_position + game.CAMERA_OFFSET))
	assert(game.race_progress.marker_position(0).x < game.race_progress.marker_position(180).x)
	assert(game.race_progress.marker_position(180).x < game.race_progress.marker_position(360).x)
	game.player.position = Vector3.ZERO
	game.choose("owl")
	assert(game.player.chosen == "owl")
	game.show_pause()
	assert(game.paused)
	var before: float = game.player.distance
	game._process(1.0)
	assert(game.player.distance == before)
	game.resume()
	assert(not game.paused)
	game.player.finish_time = 59.0
	game.elapsed = 59.0
	game.show_results()
	assert(game.state == "results" and game.progress.highest == 5)
	game.start_race(8)
	assert(game.level.team == PackedStringArray(["elephant", "owl", "otter"]))
	game.choose("otter")
	assert(game.player.chosen == "otter")
	game.show_home()
	assert(game.state == "home")
	DirAccess.remove_absolute(game.progress.path)
	game.queue_free()
	await process_frame
	print("UI_TEST_PASS home levels switch pause resume results unlock restart")
	quit(0)
