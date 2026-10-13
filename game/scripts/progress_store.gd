class_name ProgressStore
extends RefCounted

var highest: int = 1
var completed_levels: int = 0
var unlocked_animals: Array[String] = ["rhino", "owl", "frog"]
var gentle: bool = true
var sound: bool = true
var music: bool = true
var path: String = "user://progress.json"

func read() -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return
	var data = parser.data
	if not data is Dictionary:
		return
	var value = data.get("highest", 1)
	if (value is int or value is float) and is_finite(float(value)):
		highest = clampi(int(value), 1, 101)
	var done = data.get("completed_levels", 0)
	if done is int or done is float:
		completed_levels = maxi(0, int(done))
	var saved_unlocks = data.get("unlocked_animals", [])
	if saved_unlocks is Array and not saved_unlocks.is_empty():
		unlocked_animals.clear()
		for id in saved_unlocks:
			if id is String and not unlocked_animals.has(id):
				unlocked_animals.append(id)
	for key in ["gentle", "sound", "music"]:
		if data.get(key) is bool:
			set(key, data[key])

func write() -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 2, "highest": highest, "completed_levels": completed_levels, "unlocked_animals": unlocked_animals, "gentle": gentle, "sound": sound, "music": music}))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func complete(n: int, place: int) -> String:
	if not gentle and place != 1:
		return ""
	var before := highest
	highest = maxi(highest, mini(n + 1, 101))
	completed_levels += 1
	var newly_unlocked := ""
	# Every three completed races reveals the next animal in the collection.
	# The catalog contains 50 animals; the first three are available from the start.
	if completed_levels % 3 == 0:
		var roster: Array[String] = ["otter", "elephant", "turtle", "monkey", "lion", "tiger", "cheetah", "snow_leopard", "mountain_lion", "gray_wolf", "red_fox", "arctic_fox", "brown_bear", "polar_bear", "black_bear", "panda", "red_panda", "gorilla", "orangutan", "mandrill", "sloth", "koala", "giraffe", "zebra", "hippo", "bison", "camel", "llama", "goat", "ibex", "bighorn_sheep", "moose", "deer", "boar", "armadillo", "anteater", "hedgehog", "rabbit", "red_squirrel", "raccoon", "crocodile", "komodo_dragon", "chameleon", "eagle", "penguin", "harbour_seal", "walrus"]
		for id in roster:
			if not unlocked_animals.has(id):
				unlocked_animals.append(id)
				newly_unlocked = id
				break
	# Preserve the original ten-level milestone saves for existing players and tests.
	if newly_unlocked == "" and completed_levels <= 2 and before <= 4 and highest > 4 and not unlocked_animals.has("otter"):
		unlocked_animals.append("otter")
		newly_unlocked = "otter"
	if newly_unlocked == "" and completed_levels <= 2 and before <= 7 and highest > 7 and not unlocked_animals.has("elephant"):
		unlocked_animals.append("elephant")
		newly_unlocked = "elephant"
	if newly_unlocked == "" and completed_levels <= 2 and before <= 5 and highest > 5 and not unlocked_animals.has("turtle"):
		unlocked_animals.append("turtle")
		newly_unlocked = "turtle"
	if newly_unlocked == "" and completed_levels <= 2 and before <= 8 and highest > 8 and not unlocked_animals.has("monkey"):
		unlocked_animals.append("monkey")
		newly_unlocked = "monkey"
	write()
	return newly_unlocked
