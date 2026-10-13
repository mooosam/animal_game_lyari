class_name AnimalCourse
extends Node3D

var obstacles: Array[Array] = []
var materials: Dictionary = {}
var debris: Array[Dictionary] = []
var clock: float = 0.0
var effects_paused: bool = false
var water_material := ShaderMaterial.new()
var waterfall_material := ShaderMaterial.new()
var road_material := ShaderMaterial.new()
var grass_material := ShaderMaterial.new()
var rng := RandomNumberGenerator.new()
var definition: LevelDefinition
var fragments: Array[Dictionary] = []
var racers: Array = []
var stone_shader := preload("res://assets/stone.gdshader")

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key): return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	mat.metallic_specular = 0.15
	if color in [Color("804523"), Color("a95e2d"), Color("b66b30"), Color("845734")]:
		mat.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	materials[key] = mat
	return mat

func shape(mesh: Mesh, at: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = material(color)
	parent.add_child(node)
	return node

func box(size: Vector3, at: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return shape(mesh, at, color, parent)

func rock(at: Vector3, size: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var rings: Array[PackedVector3Array] = []
	for ring in range(5):
		var points := PackedVector3Array()
		for i in range(10):
			var a := TAU * i / 10.0
			var radius: float = [0.48, 0.85, 1.0, 0.78, 0.32][ring] * rng.randf_range(0.90, 1.10)
			points.append(Vector3(cos(a) * size.x * radius, size.y * [0.0, 0.22, 0.53, 0.84, 1.0][ring], sin(a) * size.z * radius))
		rings.append(points)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(4):
		for i in range(10):
			var j := (i + 1) % 10
			for v in [rings[ring][i], rings[ring][j], rings[ring + 1][i], rings[ring][j], rings[ring + 1][j], rings[ring + 1][i]]: st.add_vertex(v)
	for i in range(10):
		for v in [rings[4][i], rings[4][(i + 1) % 10], Vector3(0, size.y * 1.03, 0)]: st.add_vertex(v)
	st.generate_normals()
	var node := shape(st.commit(), at, color, parent)
	var surface := ShaderMaterial.new()
	surface.shader = stone_shader
	surface.set_shader_parameter("rock_color", color)
	node.material_override = surface
	return node

func water(at: Vector3, width: float, length: float) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(width, length)
	mesh.subdivide_width = 12
	mesh.subdivide_depth = mini(80, int(length * 2))
	var node := shape(mesh, at, Color.WHITE)
	node.material_override = water_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func waterfall(at: Vector3, width: float = 3.4, height: float = 4.8) -> void:
	# Layered vertical sheets make a readable cascade from the fixed race camera.
	# The shader animates each sheet with a different phase and a noisy edge.
	for layer in range(3):
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(width * (1.0 - layer * .12), height * (1.0 - layer * .04))
		mesh.subdivide_width = 8
		mesh.subdivide_depth = 18
		var sheet := MeshInstance3D.new()
		sheet.mesh = mesh
		sheet.position = at + Vector3((layer - 1) * .16, height * .5, layer * .08)
		sheet.rotation_degrees.x = 90
		sheet.material_override = waterfall_material
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sheet)
	var foam := SphereMesh.new()
	foam.radius = width * .52
	foam.height = .28
	foam.radial_segments = 18
	foam.rings = 6
	var pool := shape(foam, at + Vector3(0, .12, .15), Color("d9fbf4"))
	pool.scale = Vector3(1.0, .35, .55)
	pool.material_override = material(Color("d9fbf4"))

func branch(a: Vector3, b: Vector3, radius: float, parent: Node3D = self) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.72
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 20
	var node := shape(mesh, (a + b) / 2.0, Color("996035"), parent)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func tree(at: Vector3, height: float, parent: Node3D = self) -> void:
	branch(at, at + Vector3(0, height, 0), 0.26, parent)
	for side in [-1, 1]:
		branch(at + Vector3(0, height * 0.65, 0), at + Vector3(side * 1.0, height * 0.93, 0), 0.14, parent)
		var mesh := SphereMesh.new()
		mesh.radius = minf(height * 0.30, 1.1)
		mesh.height = minf(height * 0.42, 1.4)
		mesh.radial_segments = 14
		mesh.rings = 6
		var leaves := shape(mesh, at + Vector3(side * 0.65, height, 0), Color("59b83a") if side == 1 else Color("79ce46"), parent)
		leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func palm(at: Vector3, height: float) -> void:
	for i in range(3):
		branch(at + Vector3(i * 0.12, height * i / 3.0, 0), at + Vector3((i + 1) * 0.12, height * (i + 1) / 3.0, 0), 0.18)
	var crown := at + Vector3(0.36, height, 0)
	for i in range(7):
		var angle := TAU * i / 7.0
		var along := Vector3(cos(angle), 0, sin(angle))
		var across := Vector3(-sin(angle), 0, cos(angle))
		var mid := crown + along * 1.35 + Vector3.UP * 0.38
		var tip := crown + along * 2.7 - Vector3.UP * 0.70
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [crown, mid - across * 0.42, mid, crown, mid, mid + across * 0.42, mid - across * 0.42, tip, mid, mid, tip, mid + across * 0.42]: st.add_vertex(v)
		st.generate_normals()
		var leaf := shape(st.commit(), Vector3.ZERO, Color("7dab3d") if i % 2 else Color("abc449"))
		leaf.material_override = grass_material
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func shrubs(at: Vector3) -> void:
	for i in range(3):
		var mesh := SphereMesh.new()
		mesh.radius = 0.7
		mesh.height = 0.9
		mesh.radial_segments = 14
		mesh.rings = 7
		var leaf := shape(mesh, at + Vector3((i - 1) * 0.6, 0.24 + i % 2 * 0.2, (i % 2) * 0.3), Color("559946") if i % 2 else Color("7cb747"))
		leaf.scale = Vector3(1.3, 0.75, 0.8)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func cliff_face(z: float, top: float, front: bool) -> void:
	# Broad jagged faces, rather than a row of rounded columns.
	for i in range(11):
		var x := -6.6 + i * 1.2
		var dz := rng.randf_range(-0.18, 0.18)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var a := Vector3(x, -4.5, z + dz)
		var b := Vector3(x + 1.25, -4.5, z + dz + 0.12)
		var c := Vector3(x, top - rng.randf_range(0.03, 0.20), z + dz)
		var d := Vector3(x + 1.25, top - rng.randf_range(0.03, 0.20), z + dz + 0.12)
		var vertices: Array = [a, c, b, b, c, d] if front else [a, b, c, b, d, c]
		for v in vertices: st.add_vertex(v)
		st.generate_normals()
		var face := shape(st.commit(), Vector3.ZERO, Color("894620") if i % 3 else Color("9c5327"))
		var strata := ShaderMaterial.new()
		strata.shader = stone_shader
		strata.set_shader_parameter("rock_color", Color("956843"))
		strata.set_shader_parameter("strata_strength", 0.22)
		face.material_override = strata
		var cap := rock(Vector3(x + 0.6, top - 0.22, z + dz), Vector3(0.8, 0.19, 0.42), Color("a96931"))
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i % 3 != 0:
			# Moss clings to the ledge rather than forming floating green shelves
			# down the face.
			box(Vector3(1.24, 0.16, 0.38), Vector3(x + 0.6, top - 0.08, z + dz), Color("6f9f3b"))
		if i % 2 == 0:
			rock(Vector3(x + 0.22, top - 0.18, z + dz + 0.04), Vector3(0.34, 0.20, 0.24), Color("a66c3b"))

func build(level: LevelDefinition) -> void:
	definition = level
	rng.seed = level.number * 881
	water_material.shader = load("res://assets/water.gdshader")
	waterfall_material.shader = load("res://assets/waterfall.gdshader")
	road_material.shader = load("res://assets/road.gdshader")
	grass_material.shader = load("res://assets/grass.gdshader")
	box(Vector3(85, 0.7, level.length + 90), Vector3(0, -5.5, -level.length / 2), Color("70bc40"))
	if level.biome == "river": water(Vector3(-12, -3.2, -level.length / 2), 12, level.length + 70)
	for side in [-1, 1]:
		for i in range(8):
			var mesh := SphereMesh.new()
			mesh.radius = 10.0
			mesh.height = 20.0
			mesh.radial_segments = 16
			mesh.rings = 8
			var hill := shape(mesh, Vector3(side * (29 + i % 2 * 4), -4, -i * 55 - 20), Color("76cd79") if i % 2 else Color("55b88a"))
			hill.scale = Vector3(1.6, 0.75, 2.1)
	var cursor := -15.0
	for obstacle in level.obstacles:
		if obstacle.kind in ["fly", "swim"]:
			ground(cursor, obstacle.start)
			cursor = obstacle.start + obstacle.span
	ground(cursor, level.length + 18)
	for obstacle in level.obstacles:
		var z: float = -obstacle.start
		var base_y := level.height_at(obstacle.start)
		if obstacle.kind == "fly":
			cliff_face(z - 0.08, base_y, false)
			cliff_face(z - obstacle.span + 0.08, level.height_at(obstacle.start + obstacle.span), true)
		elif obstacle.kind == "swim":
			water(Vector3(0, base_y - 0.28, z - obstacle.span / 2), 13.5, obstacle.span)
			waterfall(Vector3(-6.2, base_y - 0.1, z - obstacle.span + .35), 3.2, 4.5)
			for bank in [0.0, obstacle.span]:
				for x in range(-6, 7): rock(Vector3(x, base_y - 0.55, z - bank), Vector3(0.65, 0.28, 0.65), Color("e2ac58"))
		var lane_nodes: Array = []
		for lane in [-3.0, 0.0, 3.0]:
			var group := Node3D.new()
			add_child(group)
			group.position.y = base_y
			lane_nodes.append(group)
			match obstacle.kind:
				"smash":
					for row in range(2):
						for col in range(3):
							var boulder := rock(Vector3(lane + (col - 1) * 0.9, row * 0.85, z - row * 0.12), Vector3(0.60, rng.randf_range(0.8, 1.25), 0.58), Color("979bc0") if col % 2 else Color("aeb3d4"), group)
							boulder.set_meta("intact", true)
				"jump":
					branch(Vector3(lane - 1.3, 0.38, z), Vector3(lane + 1.3, 0.38, z), 0.38, group)
				"shield":
					box(Vector3(2.95, 0.02, obstacle.span), Vector3(lane, 0.025, z - obstacle.span / 2), Color("a95e2d"), group)
					for j in range(14): rock(Vector3(lane + rng.randf_range(-1.4, 1.4), 0.04, z - rng.randf_range(0, obstacle.span)), Vector3(0.35, 0.12, 0.48), Color("b66b30"), group)
					for j in range(9):
						var piece := rock(Vector3(lane + rng.randf_range(-1.2, 1.2), 3, z - rng.randf_range(0, obstacle.span)), Vector3(0.22, 0.38, 0.25), Color("804523"), group)
						debris.append({"node": piece, "base": piece.position, "age": -rng.randf_range(0, 2.0), "velocity": Vector3.ZERO, "bounces": 0})
					for side in [-1, 1]: rock(Vector3(lane + side * 1.30, 0, z - 2), Vector3(0.28, 1.0, 0.35), Color("845734"), group)
				"climb":
					tree(Vector3(lane - 1.2, 0, z - 1.5), 6.7, group)
					tree(Vector3(lane + 1.2, 0, z - obstacle.span + 1), 7.0, group)
					branch(Vector3(lane - 1.35, 1.1, z), Vector3(lane + 1.35, 1.3, z - obstacle.span), 0.48, group)
					branch(Vector3(lane - 0.8, 3.2, z - 1.5), Vector3(lane + 0.8, 3.3, z - obstacle.span + 1), 0.16, group)
		obstacles.append(lane_nodes)
	for i in range(42):
		var x := rng.randf_range(8, 20) * (-1 if i % 2 == 0 else 1)
		var z := -i * 9.5 + 12
		if i % 3 == 0: palm(Vector3(x, level.height_at(-z) - 0.4, z), rng.randf_range(5.0, 7.0))
		else: tree(Vector3(x, level.height_at(-z) - 0.4, z), rng.randf_range(3.5, 6))
		if i % 2 == 0: rock(Vector3(x * 0.76, level.height_at(-z) - 0.4, z + 2), Vector3(0.9, 1.1, 0.7), Color("b4c4cb"))
		shrubs(Vector3(signf(x) * rng.randf_range(6.5, 10.5), level.height_at(-z) - 0.15, z - 1.5))
	var scenery := AnimalScenery.new()
	add_child(scenery)
	scenery.build(level)
	var finish_height := level.height_at(level.length)
	for row in range(2):
		for col in range(12): box(Vector3(0.75, 0.02, 0.75), Vector3(-4.125 + col * 0.75, finish_height + 0.03, -level.length - row * 0.75), Color.WHITE if (row + col) % 2 else Color("25484b"))
	for side in [-1, 1]: branch(Vector3(side * 4.7, finish_height, -level.length), Vector3(side * 4.7, finish_height + 5, -level.length), 0.20)
	box(Vector3(6.5, 1.2, 0.12), Vector3(0, finish_height + 4.6, -level.length), Color("8174a4"))
	var finish := Label3D.new()
	finish.text = "FINISH"
	finish.font_size = 90
	finish.pixel_size = 0.012
	finish.modulate = Color.WHITE
	finish.position = Vector3(0, finish_height + 4.6, -level.length + 0.2)
	add_child(finish)

func ground(start: float, end: float) -> void:
	if end <= start: return
	var y := definition.height_at(start)
	var road := box(Vector3(9.2, 0.8, end - start), Vector3(0, y - 0.4, -(start + end) / 2), Color.WHITE)
	road.material_override = road_material
	box(Vector3(9.2, y + 3.7, end - start), Vector3(0, (y - 5.3) / 2, -(start + end) / 2), Color("965b32"))
	for side in [-1, 1]:
		var lawn := box(Vector3(18, 0.3, end - start), Vector3(side * 13.6, y - 0.28, -(start + end) / 2), Color("84ad40"))
		lawn.material_override = grass_material
		for i in range(int((end - start) / 6) + 1):
			var chip := box(Vector3(rng.randf_range(0.45, 1.05), 0.06, rng.randf_range(1.3, 3.8)), Vector3(side * 4.48, y + 0.02, -minf(end, start + i * 6)), Color("84ad40"))
			chip.rotation.y = rng.randf_range(-0.45, 0.45)
			chip.material_override = grass_material


func _process(delta: float) -> void:
	if effects_paused: return
	clock += delta
	water_material.set_shader_parameter("water_time", clock)
	waterfall_material.set_shader_parameter("water_time", clock)
	for item in debris:
		var node: MeshInstance3D = item.node
		item.age += delta
		node.visible = item.age >= 0
		if item.age < 0: continue
		var floor_y := 0.12
		for racer in racers:
			if is_instance_valid(racer) and racer.chosen == "turtle" and racer.traversal_kind == "shield" and racer.traversal > 0:
				if node.global_position.y >= racer.position.y + 0.9 and Vector2(node.global_position.x-racer.position.x, node.global_position.z-racer.position.z).length() < 0.85:
					floor_y = maxf(floor_y, racer.position.y - node.get_parent().position.y + 1.0)
		item.velocity += Vector3.DOWN * 12.0 * delta
		node.position += item.velocity * delta
		node.rotate_x(delta * 2.1 * pow(0.45, item.bounces))
		node.rotate_z(delta * 1.4 * pow(0.45, item.bounces))
		if node.position.y <= floor_y and item.velocity.y < 0:
			node.position.y = floor_y
			item.velocity = Vector3(rng.randf_range(-1.1, 1.1), -item.velocity.y * 0.28, rng.randf_range(-0.6, 0.6))
			item.bounces += 1
		if item.age > 2.8:
			item.age = -rng.randf_range(0.1, 0.7)
			node.position = item.base + Vector3.UP * 2.2
			item.velocity = Vector3.ZERO
			item.bounces = 0
	for i in range(fragments.size()-1, -1, -1):
		var item := fragments[i]
		var node: MeshInstance3D = item.node
		item.age += delta
		item.velocity += Vector3.DOWN * 14.0 * delta
		node.position += item.velocity * delta
		node.rotation += item.spin * delta
		if node.position.y < item.floor:
			node.position.y = item.floor
			item.velocity.y = absf(item.velocity.y) * 0.30
			item.velocity.x *= 0.62
			item.velocity.z *= 0.62
			item.spin *= 0.55
		if item.age > 4.0:
			node.scale = Vector3.ONE * maxf(0.0, 5.0 - item.age)
		if item.age >= 5.0:
			node.queue_free()
			fragments.remove_at(i)

func smash(index: int, lane_index: int) -> void:
	if index >= obstacles.size(): return
	var group: Node3D = obstacles[index][lane_index]
	for child in group.get_children():
		if child is MeshInstance3D and child.mesh is ArrayMesh:
			if not child.get_meta("intact", false): continue
			child.set_meta("intact", false)
			fragments.append({"node": child, "velocity": Vector3(rng.randf_range(-3, 3), rng.randf_range(3.0, 5.5), -rng.randf_range(3, 6)), "spin": Vector3(rng.randf_range(-3, 3), rng.randf_range(-3, 3), 2.0), "floor": 0.08, "age": 0.0})


