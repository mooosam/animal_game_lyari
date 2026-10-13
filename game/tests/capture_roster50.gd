extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var viewer: AnimalLibrary = load("res://animal_library.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	for i in range(50):
		viewer.index = i
		viewer.show_animal()
		for clip in ["run", "ability"]:
			# Skip cross-fading from the previous clip so each still shows the
			# exact keyed pose at the seek position.
			viewer.animation.play(clip, 0.0)
			viewer.animation.pause()
			viewer.clip_choice.select(viewer.definitions[i].clips.find(clip))
			for phase in range(4):
				viewer.animation.seek(viewer.animation.current_animation_length * phase / 4.0, true)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../tools/screenshots/roster-%s-%s-%d.png" % [viewer.definitions[i].id, clip, phase])
		print("ROSTER_CAPTURE ", viewer.definitions[i].id)
	quit()
