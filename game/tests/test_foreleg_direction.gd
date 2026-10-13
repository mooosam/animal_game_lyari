extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var checked := 0
	for animal: AnimalDefinition in AnimalCatalog.definitions().values():
		var model := animal.model.instantiate()
		root.add_child(model)
		var skeletons := model.find_children("*", "Skeleton3D", true, false)
		assert(skeletons.size() == 1, animal.id + " skeleton")
		var skeleton: Skeleton3D = skeletons[0]
		var lower := skeleton.find_bone("fore_lower_1")
		if lower < 0:
			model.free()
			continue # Birds articulate their forelimbs as wings instead.
		var players := model.find_children("*", "AnimationPlayer", true, false)
		assert(not players.is_empty(), animal.id + " animation player")
		var player: AnimationPlayer = players[0]
		assert(player.has_animation("run"), animal.id + " run clip")
		player.play("run")
		var greatest_flex := -INF
		var animation := player.get_animation("run")
		for sample in range(33):
			player.seek(animation.length * float(sample) / 32.0, true)
			var bend := skeleton.get_bone_pose_rotation(lower).get_euler().x
			greatest_flex = maxf(greatest_flex, bend)
		# Positive local-X flexes the front elbow caudally in this rig. Harbor
		# seals use propulsive flippers, so their forearm segment does not flex.
		if animal.id != "harbour_seal":
			assert(greatest_flex > 0.08, animal.id + " front elbow does not flex toward tail")
			checked += 1
		model.free()
	assert(checked >= 40, "All articulated quadrupeds and frogs are direction-checked")
	print("FORELEG_DIRECTION_PASS animals=", checked)
	quit()
