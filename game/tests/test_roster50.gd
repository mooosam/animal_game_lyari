extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var roster := AnimalCatalog.definitions()
	assert(roster.size() == 50, "Exactly 50 approved animals")
	DirAccess.make_dir_recursive_absolute("res://assets/animals/definitions")
	var clip_count := 0
	var mesh_count := 0
	for animal: AnimalDefinition in roster.values():
		assert(animal.model != null and animal.portrait != null, animal.id)
		var node := animal.model.instantiate()
		root.add_child(node)
		var skeletons := node.find_children("*", "Skeleton3D", true, false)
		assert(skeletons.size() == 1 and skeletons[0].get_bone_count() >= 14, animal.id+" skeleton")
		var animation: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
		for clip in animal.clips:
			assert(animation.has_animation(clip), animal.id+" missing "+clip)
			var a := animation.get_animation(clip)
			assert(a.length > 0.1 and a.get_track_count() > 2, animal.id+" empty "+clip)
			animation.play(clip)
			animation.seek(a.length * 0.35, true)
			for b in range(skeletons[0].get_bone_count()):
				assert(skeletons[0].get_bone_pose_position(b).is_finite(), animal.id+" invalid pose")
			clip_count += 1
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			for s in range(mesh.mesh.get_surface_count()):
				var mat: StandardMaterial3D = mesh.mesh.surface_get_material(s)
				assert(mat.albedo_texture != null, animal.id+" albedo")
				assert(mat.normal_enabled and mat.normal_texture != null, animal.id+" normal")
				assert(mat.roughness_texture != null, animal.id+" roughness")
				assert(mat.ao_enabled and mat.ao_texture != null, animal.id+" ambient occlusion")
				mesh_count += 1
		ResourceSaver.save(animal, "res://assets/animals/definitions/%s.tres" % animal.id)
		node.free()
		print("ROSTER_TEST_PASS ", animal.id)
	print("ROSTER50_PASS animals=50 clips=", clip_count, " materials=", mesh_count)
	quit()
