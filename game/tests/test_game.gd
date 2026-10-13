extends SceneTree

var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var animals := {
		"rhino": AnimalDefinition.create("rhino", "Rhino", "smash", "◆", Color.WHITE),
		"owl": AnimalDefinition.create("owl", "Owl", "fly", "↑", Color.WHITE),
		"frog": AnimalDefinition.create("frog", "Frog", "jump", "∩", Color.WHITE),
		"otter": AnimalDefinition.create("otter", "Otter", "swim", "≈", Color.WHITE),
		"elephant": AnimalDefinition.create("elephant", "Elephant", "smash", "◆", Color.WHITE),
		"turtle": AnimalDefinition.create("turtle", "Turtle", "shield", "⬟", Color.WHITE),
		"monkey": AnimalDefinition.create("monkey", "Monkey", "climb", "↟", Color.WHITE)}
	for id in animals:
		var model: Node = animals[id].model.instantiate()
		root.add_child(model)
		var skeletons := model.find_children("*", "Skeleton3D", true, false)
		check(not skeletons.is_empty(), id + " skeleton")
		var players := model.find_children("*", "AnimationPlayer", true, false)
		if id == "rhino":
			var widest := 0.0
			for mesh in model.find_children("*", "MeshInstance3D", true, false):
				widest = maxf(widest, mesh.mesh.get_aabb().size.x)
			check(widest > 0.7, "mirrored animal keeps full body width")
		check(not players.is_empty(), id + " animation player")
		for clip in ["idle", "run", "ability", "celebrate"]:
			var found := false
			for name in players[0].get_animation_list():
				if name == clip or name.ends_with("/" + clip):
					found = true
			check(found, id + " " + clip)
		model.queue_free()
	for n in range(1, 11):
		var level := LevelDefinition.create(n)
		check(level.team.size() == 3, "three buttons")
		var racer := AnimalRacer.new()
		root.add_child(racer)
		racer.setup(animals, level.team, 0)
		var previous_end := 0.0
		for obstacle in level.obstacles:
			check(racer.correct_animal(obstacle.kind) != "", "course solvable")
			check(obstacle.start - 1.5 > previous_end, "obstacles do not overlap")
			previous_end = obstacle.start + obstacle.span + 1.5
		var time := 0.0
		while racer.finish_time < 0.0 and time < 100.0:
			if racer.obstacle_index < level.obstacles.size():
				racer.switch_to(racer.correct_animal(level.obstacles[racer.obstacle_index].kind))
			time += 0.05
			racer.step(0.05, level, 6.2, true, false, time)
		check(racer.finish_time > 45 and racer.finish_time < 75, "race length %d" % n)
		check(racer.obstacle_index == level.obstacles.size(), "all obstacles crossed")
		check(is_equal_approx(racer.position.y, level.height_at(level.length)), "finishes at course elevation")
		racer.queue_free()
	for n in [6, 9]:
		for gentle in [true, false]:
			var special := LevelDefinition.create(n)
			var animal := AnimalRacer.new()
			root.add_child(animal)
			animal.setup(animals, special.team, 0)
			animal.switch_to(special.team[1])
			animal.distance = special.obstacles[0].start - 1.6
			animal.step(0.1, special, 6.2, gentle, false, 0.1)
			check(animal.waiting, "new obstacle rejects wrong animal")
			check(animal.penalty == (0.0 if gentle else 2.0), "new obstacle mode penalty")
			animal.switch_to(special.team[0])
			animal.step(2.1, special, 6.2, gentle, false, 2.2)
			animal.step(0.1, special, 6.2, gentle, false, 2.3)
			check(animal.traversal > 0, "new ability traverses obstacle")
			check(animal.switch_to(special.team[1]), "can switch inside new obstacle")
			var at_switch := animal.distance
			animal.step(0.1, special, 6.2, gentle, false, 2.4)
			check(animal.waiting and animal.distance == at_switch, "wrong mid-obstacle choice stops safely")
			animal.queue_free()
	var level := LevelDefinition.create(1)
	var racer := AnimalRacer.new()
	root.add_child(racer)
	racer.setup(animals, level.team, 0)
	racer.switch_to("owl")
	racer.distance = level.obstacles[0].start - 1.6
	racer.step(0.1, level, 6.2, true, false, 1)
	check(racer.waiting and racer.penalty == 0, "gentle pause")
	var stopped := racer.distance
	racer.step(1, level, 6.2, true, false, 2)
	check(racer.distance == stopped, "cannot pass wrong obstacle")
	racer.switch_to("rhino")
	racer.step(0.1, level, 6.2, true, false, 3)
	check(racer.traversal > 0, "correct animal starts traversal")
	check(racer.switch_to("owl"), "switch during an obstacle")
	var at_switch := racer.distance
	racer.step(0.1, level, 6.2, true, false, 3.1)
	check(racer.waiting and racer.distance == at_switch, "safe mid-obstacle stop")
	check(racer.switch_to("rhino"), "recover with the correct animal")
	racer.step(0.1, level, 6.2, true, false, 3.2)
	check(racer.distance > at_switch, "continues from traversal progress after switching")
	racer.queue_free()
	var challenge := AnimalRacer.new()
	root.add_child(challenge)
	challenge.setup(animals, level.team, 0)
	challenge.switch_to("owl")
	challenge.distance = level.obstacles[0].start - 1.6
	challenge.step(0.1, level, 6.2, false, false, 1)
	check(challenge.penalty == 2, "challenge penalty")
	challenge.step(1.0, level, 6.2, false, false, 2)
	check(challenge.penalty == 1, "penalty duration")
	challenge.queue_free()
	var pace := AnimalRacer.new()
	root.add_child(pace)
	pace.setup(animals, LevelDefinition.create(1).team, 0)
	pace.step(1.0, LevelDefinition.create(1), 6.2, true, false, 1.0)
	var rhino_stride := pace.distance
	pace.switch_to("frog")
	pace.step(1.0, LevelDefinition.create(1), 6.2, true, false, 2.0)
	check(pace.distance - rhino_stride > rhino_stride, "fast animal gains ground on ordinary road")
	pace.queue_free()
	var flyer := AnimalRacer.new()
	root.add_child(flyer)
	var flying_level := LevelDefinition.create(2)
	flyer.setup(animals, flying_level.team, 0)
	flyer.switch_to("owl")
	flyer.distance = flying_level.obstacles[0].start - 1.6
	flyer.step(0.1, flying_level, 6.2, true, false, 0.1)
	flyer.step(0.3, flying_level, 6.2, true, false, 0.4)
	var in_flight := flyer.distance
	flyer.step(0.1, flying_level, 1.0, true, false, 0.5)
	check(flyer.distance > in_flight, "speed changes never rewind a crossing")
	var midair_position := flyer.position
	check(flyer.switch_to("frog"), "can transform in flight")
	flyer.step(0.1, flying_level, 6.2, true, false, 0.6)
	check(flyer.waiting and flyer.position.is_equal_approx(midair_position), "Gentle mode prevents midair falls")
	flyer.switch_to("owl")
	flyer.step(0.1, flying_level, 6.2, true, false, 0.7)
	check(flyer.distance > in_flight and not flyer.waiting, "flight resumes after the correct transformation")
	flyer.queue_free()
	var store := ProgressStore.new()
	store.path = "user://test_progress.json"
	store.highest = 1
	store.gentle = false
	store.complete(4, 2)
	check(store.highest == 1, "challenge loss does not unlock")
	check(store.complete(4, 1) == "otter", "otter unlock")
	check(store.complete(7, 1) == "elephant", "elephant unlock")
	var extra_unlocks := ProgressStore.new()
	extra_unlocks.path = "user://test_extra_unlocks.json"
	extra_unlocks.highest = 5
	check(extra_unlocks.complete(5, 1) == "turtle", "turtle unlock")
	extra_unlocks.highest = 8
	check(extra_unlocks.complete(8, 1) == "monkey", "monkey unlock")
	DirAccess.remove_absolute(extra_unlocks.path)
	var reloaded := ProgressStore.new()
	reloaded.path = store.path
	reloaded.read()
	check(reloaded.highest == 8 and not reloaded.gentle, "progress persists")
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("broken json")
	file.close()
	reloaded = ProgressStore.new()
	reloaded.path = store.path
	reloaded.read()
	check(reloaded.highest == 1 and reloaded.gentle, "invalid save defaults")
	DirAccess.remove_absolute(store.path)
	print("TEST_PASS checks=", checks)
	quit(0)
