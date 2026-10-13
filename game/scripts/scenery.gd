class_name AnimalScenery
extends Node3D

var random := RandomNumberGenerator.new()
var batches: Dictionary = {}
var terrain_material: ShaderMaterial
var bark_material: ShaderMaterial
var foliage_material: StandardMaterial3D
var stone_material: ShaderMaterial
var flower_material: StandardMaterial3D

func batch(key: String, mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color], mat: Material, shadows: bool = false) -> void:
	if transforms.is_empty(): return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.name = key
	node.multimesh = multi
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func transform(at: Vector3, scale: Vector3, yaw: float = 0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(scale), at)

func stem(a: Vector3, b: Vector3, radius: float) -> Transform3D:
	return Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())).scaled(Vector3(radius, a.distance_to(b), radius)), (a + b) / 2)

func blade() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var t := float(i) / 6
		var u := float(i + 1) / 6
		var a := Vector3(0, sin(t * PI * .7) * .40, t)
		var b := Vector3(0, sin(u * PI * .7) * .40, u)
		var width_a := sin(t * PI) * .17 + .01
		var width_b := sin(u * PI) * .17 + .005
		for point in [a + Vector3(-width_a, 0, 0), a + Vector3(width_a, 0, 0), b + Vector3(-width_b, 0, 0), a + Vector3(width_a, 0, 0), b + Vector3(width_b, 0, 0), b + Vector3(-width_b, 0, 0)]:
			surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()

func terrain(level: LevelDefinition, start: float, end: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1, 1]:
		for z_step in range(24):
			for x_step in range(10):
				var corners: Array[Vector3] = []
				for step in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
					var distance := lerpf(start, end, (z_step + step.y) / 24.0)
					# Keep the background terrain outside the camera's near lane. The
					# old 4.7-unit start could cut a giant triangular sheet through
					# the player and camera during a cliff traversal.
					var x: float = side * (11.5 + (x_step + step.x) * 3.6)
					var rise := smoothstep(11, 22, absf(x)) * (sin(distance * .045 + absf(x) * .27) * 1.5 + .65)
					corners.append(Vector3(x, level.height_at(distance) - .16 + rise, -distance))
				for index in [0, 2, 1, 1, 2, 3]:
					st.set_color(Color("769e45").lerp(Color("405e2c"), random.randf_range(.0, .3)))
					st.add_vertex(corners[index])
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = terrain_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func build(level: LevelDefinition) -> void:
	random.seed = 9971 + level.number
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://assets/scenery_surface.gdshader")
	bark_material = ShaderMaterial.new()
	bark_material.shader = load("res://assets/bark.gdshader")
	stone_material = ShaderMaterial.new()
	stone_material.shader = load("res://assets/scenery_surface.gdshader")
	foliage_material = StandardMaterial3D.new()
	foliage_material.vertex_color_use_as_albedo = true
	foliage_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	foliage_material.roughness = .92
	flower_material = foliage_material.duplicate()
	var trunk := CylinderMesh.new()
	trunk.top_radius = .70
	trunk.bottom_radius = 1.0
	trunk.height = 1.0
	trunk.radial_segments = 12
	var crown := SphereMesh.new()
	crown.radius = 1.0
	crown.height = 2.0
	crown.radial_segments = 14
	crown.rings = 7
	var stone := SphereMesh.new()
	stone.radius = 1.0
	stone.height = 2.0
	stone.radial_segments = 10
	stone.rings = 5
	var leaf := blade()
	for chunk in range(ceili((level.length + 30) / 30)):
		var start := chunk * 30.0 - 15
		terrain(level, start, start + 30)
		var trunks: Array[Transform3D] = []
		var trunk_colors: Array[Color] = []
		var crowns: Array[Transform3D] = []
		var crown_colors: Array[Color] = []
		var leaves: Array[Transform3D] = []
		var leaf_colors: Array[Color] = []
		var stones: Array[Transform3D] = []
		var stone_colors: Array[Color] = []
		var flowers: Array[Transform3D] = []
		var flower_colors: Array[Color] = []
		for side in [-1, 1]:
			for i in range(7):
				var distance := start + i * 4.3 + random.randf_range(-1, 1)
				var x: float = side * random.randf_range(12.5, 26)
				var at := Vector3(x, level.height_at(distance) - .3, -distance)
				var height := random.randf_range(5, 9)
				var root := at
				var top := at + Vector3(random.randf_range(-.4, .4), height, .2)
				trunks.append(stem(root, top, random.randf_range(.24, .42)))
				trunk_colors.append(Color("76503b"))
				for limb in range(4):
					var angle := limb * TAU / 4 + random.randf()
					var end := top + Vector3(cos(angle) * 1.5, random.randf_range(-.7, .5), sin(angle) * 1.5)
					trunks.append(stem(at + Vector3.UP * height * .65, end, .13))
					trunk_colors.append(Color("7f5740"))
					crowns.append(transform(end, Vector3(random.randf_range(1.5, 2.5), 1.15, random.randf_range(1.6, 2.5)), angle))
					crown_colors.append(Color("538537").lerp(Color("a6c968"), random.randf_range(0, .75)))
				for root_index in range(3):
					var angle := root_index * TAU / 3
					trunks.append(stem(at + Vector3.UP * .6, at + Vector3(cos(angle) * .8, -.02, sin(angle) * .8), .13))
					trunk_colors.append(Color("76503b"))
			for i in range(28):
				var distance := random.randf_range(start, start + 30)
				var x: float = side * random.randf_range(5.2, 13)
				if level.biome == "river" and side == -1 and absf(x) > 7.5: continue
				var at := Vector3(x, level.height_at(distance) + .02, -distance)
				var size := random.randf_range(.45, 1.1)
				for frond in range(7):
					leaves.append(transform(at, Vector3.ONE * size, frond * TAU / 7 + random.randf_range(-.2, .2)))
					leaf_colors.append(Color("426d27").lerp(Color("b2c65e"), random.randf_range(.1, .8)))
				if i % 5 == 0:
					stones.append(transform(at + Vector3(.6, .12, 0), Vector3(random.randf_range(.25, .6), .26, .4), random.randf() * TAU))
					stone_colors.append(Color("788071").lerp(Color("ada38c"), random.randf()))
				if i % 3 == 0:
					for bloom in range(3):
						flowers.append(transform(at + Vector3(bloom * .1 - .1, .25, .22), Vector3(.085, .08, .085)))
						flower_colors.append(Color("f5c24e") if (i + chunk) % 2 else Color("dcb0d5"))
		batch("Bark%d" % chunk, trunk, trunks, trunk_colors, bark_material, true)
		batch("Canopies%d" % chunk, crown, crowns, crown_colors, foliage_material)
		batch("Ferns%d" % chunk, leaf, leaves, leaf_colors, foliage_material)
		batch("RiverbankStones%d" % chunk, stone, stones, stone_colors, stone_material)
		batch("Flowers%d" % chunk, crown, flowers, flower_colors, flower_material)
