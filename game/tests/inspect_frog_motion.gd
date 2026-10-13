extends SceneTree

func _init() -> void:
	var defs := AnimalCatalog.definitions()
	var frog: AnimalDefinition = defs["frog"]
	var model := frog.model.instantiate()
	root.add_child(model)
	await process_frame
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	var anim := player.get_animation("ability")
	print("FROG_ANIM length=", anim.length, " tracks=", anim.get_track_count())
	for track in range(anim.get_track_count()):
		var path := str(anim.track_get_path(track))
		if "body" in path or "fore" in path or "hind" in path or "spine" in path:
			var v0 = anim.track_get_key_value(track, 0) if anim.track_get_key_count(track) > 0 else null
			var vm = anim.track_get_key_value(track, anim.track_get_key_count(track) / 2) if anim.track_get_key_count(track) > 1 else null
			print(path, " first=", v0, " mid=", vm)
	quit()
