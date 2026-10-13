class_name AnimalCatalog
extends RefCounted

static func definitions() -> Dictionary:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animals/roster.json"))
	var roster: Dictionary = {}
	var icons := {"smash": "◆", "fly": "↑", "jump": "∩", "swim": "≈", "shield": "⬟", "climb": "↟", "reach": "↥", "dig": "↓"}
	for entry in entries:
		var animal := AnimalDefinition.create(entry.id, entry.title, entry.ability, icons.get(entry.ability, "•"), Color.WHITE)
		animal.family = entry.family
		animal.model_scale = entry.model_scale
		animal.cycle_seconds = entry.period
		animal.model_height = entry.height
		animal.clips = PackedStringArray(entry.clips)
		roster[animal.id] = animal
	return roster
