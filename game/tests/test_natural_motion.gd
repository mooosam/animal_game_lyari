extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var course := AnimalCourse.new()
	root.add_child(course)
	course.build(LevelDefinition.create(1))
	course.smash(0, 1)
	assert(course.fragments.size() == 6, "Six wall rocks receive impact impulses")
	var part: Dictionary = course.fragments[0]
	var initial: float = part.velocity.y
	course._process(0.1)
	assert(part.velocity.y < initial, "Gravity reduces upward velocity")
	var held: Vector3 = part.node.position
	course.effects_paused = true
	course._process(0.5)
	assert(part.node.position == held, "Pause freezes physics effects")
	course.effects_paused = false
	for i in range(310): course._process(1.0 / 60.0)
	assert(course.fragments.is_empty(), "Spent fragments are removed")
	var frog := AnimalRacer.new()
	root.add_child(frog)
	var animal := AnimalDefinition.create("frog", "Frog", "jump", "∩", Color.WHITE)
	frog.setup({"frog": animal}, PackedStringArray(["frog"]), 0.0)
	frog.play_clip("run")
	var skeletons: Array[Node] = frog.visual.find_children("*", "Skeleton3D", true, false)
	assert(skeletons.size() == 1, "Frog has an articulated skeleton")
	var skeleton: Skeleton3D = skeletons[0]
	var body_bone := skeleton.find_bone("body")
	var hind_bone := skeleton.find_bone("hind_1")
	assert(body_bone >= 0 and hind_bone >= 0, "Frog body and propulsion limbs are rigged")
	frog.animation.seek(0.0, true)
	var body_start := skeleton.get_bone_pose_position(body_bone)
	var hind_start := skeleton.get_bone_pose_rotation(hind_bone)
	frog.gait_time = animal.cycle_seconds * 0.45
	frog._process(0.0)
	frog.animation.seek(frog.animation.current_animation_length * 0.45, true)
	var body_airborne := skeleton.get_bone_pose_position(body_bone)
	var hind_extended := skeleton.get_bone_pose_rotation(hind_bone)
	assert(body_airborne.distance_to(body_start) > 0.15, "Frog body visibly compresses and lifts in the run cycle")
	assert(absf(hind_extended.angle_to(hind_start)) > 0.1, "Frog hind legs extend during the hop")
	assert(is_zero_approx(frog.visual.position.y), "Frog rig animates while its root stays planted")
	frog.gait_time = 0.0
	frog._process(0.0)
	assert(is_zero_approx(frog.visual.position.y), "Hop returns to ground contact")
	frog.step(0.05, LevelDefinition.create(3), 6.2, true, false, 0.05)
	assert(is_zero_approx(frog.distance), "Crouching frog keeps its feet planted")
	frog.step(0.30, LevelDefinition.create(3), 6.2, true, false, 0.35)
	assert(frog.distance > 0.5, "Push-off carries the frog forward")
	frog.traversal_kind = "jump"
	assert(is_equal_approx(frog.traversal_height(0.25), frog.traversal_height(0.75)), "Ballistic arc is symmetric")
	frog.free()
	course.free()
	print("NATURAL_MOTION_PASS gravity pause cleanup frog_skeletal_hop planted_root frog_contact ballistic_arc")
	quit()
