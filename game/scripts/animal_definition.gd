class_name AnimalDefinition
extends Resource

@export var id: String
@export var title: String
@export var ability: String
@export var symbol: String
@export var color: Color
@export var model: PackedScene
@export var portrait: Texture2D
@export var run_multiplier: float = 1.0
@export var family: String = "quadruped"
@export var model_scale: float = 1.15
@export var cycle_seconds: float = 1.0
@export var model_height: float = 2.0
@export var clips: PackedStringArray

static func create(key: String, label: String, power: String, icon: String, tint: Color) -> AnimalDefinition:
	var a := AnimalDefinition.new()
	a.id = key
	a.title = label
	a.ability = power
	a.symbol = icon
	a.color = tint
	a.model_scale = {"rhino": 1.4, "owl": 1.5, "frog": 1.25, "otter": 1.25, "elephant": 1.05, "turtle": 1.25, "monkey": 1.1}.get(key, 1.15)
	a.cycle_seconds = {"frog": 0.74, "rhino": 0.83, "elephant": 1.2, "turtle": 1.43, "otter": 0.67, "owl": 0.73, "monkey": 0.8}.get(key, 1.0)
	a.run_multiplier = {"rhino": 0.90, "owl": 1.03, "frog": 1.20, "otter": 1.02, "elephant": 0.85, "turtle": 0.78, "monkey": 1.16}.get(key, 1.0)
	a.model = load("res://assets/animals/%s.glb" % key)
	a.portrait = load("res://assets/animals/%s.png" % key)
	return a
