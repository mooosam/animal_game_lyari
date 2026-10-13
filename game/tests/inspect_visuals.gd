extends SceneTree
func _initialize() -> void:
	call_deferred("inspect_models")
func inspect_models() -> void:
	for id in ["rhino", "otter", "owl", "monkey"]:
		var model = load("res://assets/animals/%s.glb" % id).instantiate()
		root.add_child(model)
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			print(id, " MESH ", mesh.name, " scale ", mesh.scale, " global ", mesh.global_transform, " aabb ", mesh.mesh.get_aabb())
			for surface in range(mesh.mesh.get_surface_count()):
				var mat = mesh.mesh.surface_get_material(surface)
				print("MAT ", mat.albedo_color if mat is StandardMaterial3D else mat, " VERTEX_COLOR ", mat.vertex_color_use_as_albedo if mat is StandardMaterial3D else false)
		var skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
		var anim = model.find_children("*", "AnimationPlayer", true, false)[0]
		anim.play("run")
		anim.advance(.4)
		for i in range(skeleton.get_bone_count()):
			print("BONE ", skeleton.get_bone_name(i), " rest ", skeleton.get_bone_rest(i), " pose ", skeleton.get_bone_pose(i))
		model.queue_free()
	quit()
