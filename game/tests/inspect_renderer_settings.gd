extends SceneTree
func _initialize() -> void:
	for entry in ProjectSettings.get_property_list():
		var key: String = entry.name
		if key.contains("gl_compatibility") or key.contains("canvas") and key.contains("light"):
			print(key, " = ", ProjectSettings.get_setting(key))
	quit()
