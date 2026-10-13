class_name LevelDefinition
extends Resource

@export var number: int
@export var title: String
@export var team: PackedStringArray
@export var biome: String
@export var obstacles: Array[Dictionary]
@export var length: float = 360.0

const ABILITY_ANIMALS := {
	"smash": ["rhino", "elephant", "brown_bear", "gorilla", "bison", "boar"],
	"fly": ["owl", "eagle"],
	"jump": ["frog", "lion", "tiger", "cheetah", "zebra", "deer", "rabbit"],
	"swim": ["otter", "polar_bear", "hippo", "crocodile", "penguin", "harbour_seal", "walrus"],
	"shield": ["turtle", "armadillo", "hedgehog"],
	"climb": ["monkey", "black_bear", "panda", "red_panda", "orangutan", "sloth", "koala", "goat", "ibex", "raccoon", "chameleon"]
}
const TITLES := ["Morning Meadow", "Pebble Pass", "Bamboo Bend", "Rainforest Run", "River Welcome", "Shell Shelter", "Otter Rapids", "Elephant Parade", "Monkey Canopy", "Animal Champions", "Fern Valley", "Misty Rapids", "Sunstone Trail", "Palm Grove", "Thunder Ridge", "Bluewater Bay", "Canyon Echo", "Pollen Path", "Hidden Lagoon", "Treetop Turn", "Golden Savanna", "Mossy Steps", "Driftwood Dash", "Vine Valley", "Cloud Forest", "Red Rock Run", "Boulder Brook", "Firefly Field", "Wildflower Way", "Rain Drum Road"]

static func create(n: int) -> LevelDefinition:
	var l := LevelDefinition.new()
	l.number = clampi(n, 1, 100)
	if n <= 10:
		l.title = ["Rhino Rumble", "Wings Away", "Hop Along", "Jungle Friends", "River Welcome", "Shell Shelter", "River Rally", "Elephant Parade", "Monkey Canopy", "Animal Champions"][n - 1]
		l.team = PackedStringArray(["rhino", "owl", "frog"] if n <= 4 else ["rhino", "owl", "otter"] if n <= 7 else ["elephant", "owl", "otter"])
		l.biome = "jungle" if n <= 4 else "river"
		var kinds: Array = ["smash"] if n == 1 else ["fly"] if n == 2 else ["jump"] if n == 3 else ["smash", "fly", "jump"] if n == 4 else ["swim", "smash", "fly"]
		if n == 6:
			l.team = PackedStringArray(["turtle", "rhino", "otter"]); kinds = ["shield", "swim", "smash"]
		elif n == 9:
			l.team = PackedStringArray(["monkey", "owl", "otter"]); kinds = ["climb", "swim", "fly"]
		elif n == 10:
			l.team = PackedStringArray(["monkey", "turtle", "otter"]); kinds = ["shield", "climb", "swim"]
		var tutorial_count := 6 + n / 2
		for i in range(tutorial_count): _add_obstacle(l, kinds[i % kinds.size()], 32.0 + i * (290.0 / tutorial_count), i)
		return l
	var seed := n * 7919 + 17
	var biome_index := (n - 1) / 10
	l.biome = "river" if biome_index % 3 != 0 else "jungle"
	l.title = TITLES[(n - 1) % TITLES.size()] + " %02d" % n
	l.length = 220.0 + float((n * 37) % 16) * 24.0
	var patterns: Array = [["smash", "jump", "shield"], ["fly", "jump", "smash"], ["swim", "fly", "climb"], ["smash", "swim", "jump"], ["climb", "shield", "fly"], ["swim", "smash", "fly"]]
	var kinds: Array = patterns[(n - 11) % patterns.size()]
	var count := 3 + ((n * 17) % 18)
	var chosen: Array[String] = []
	for kind in kinds:
		var candidates: Array = ABILITY_ANIMALS[kind]
		chosen.append(candidates[(seed + chosen.size() * 3) % candidates.size()])
	l.team = PackedStringArray(chosen)
	var spacing := (l.length - 52.0) / float(count)
	for i in range(count):
		var kind: String = kinds[(i + (n % 3)) % kinds.size()]
		var jitter := float(((seed + i * 13) % 9) - 4) * (0.6 if n % 4 == 0 else 1.4)
		var start := 28.0 + float(i) * spacing + jitter
		var span: float = float({"smash": 1.35, "jump": 1.8, "fly": 7.5, "swim": 16.0, "shield": 5.5, "climb": 6.5}[kind])
		_add_obstacle(l, kind, clampf(start, 22.0, l.length - span - 8.0), i)
	return l

static func _add_obstacle(l: LevelDefinition, kind: String, start: float, index: int) -> void:
	var span: float = float({"smash": 1.2, "jump": 1.5, "fly": 7.0, "swim": 18.0, "shield": 5.0, "climb": 6.0}[kind])
	l.obstacles.append({"kind": kind, "start": start, "span": span, "index": index})

func height_at(distance: float) -> float:
	var height := 0.0
	var cliff_index := 0
	for obstacle in obstacles:
		if obstacle.kind != "fly": continue
		var rise := 4.8 if cliff_index % 2 == 0 else -4.8
		cliff_index += 1
		if distance < obstacle.start: return height
		if distance < obstacle.start + obstacle.span: return height + rise * (distance - obstacle.start) / obstacle.span
		height += rise
	return height
