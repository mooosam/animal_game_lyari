from pathlib import Path
p=Path(__file__).resolve().parents[1]/'game/scripts/course.gd'
t=p.read_text(encoding='utf-8')
a=t.index('\t\t\tvar post :=')
b=t.index('\t\tobstacles.append(lane_nodes)',a)
t=t[:a]+t[b:]
a=t.index('\t\tif obstacle.kind in ["fly", "swim"]:', t.index('\t\tvar base_y'))
b=t.index('\t\tvar lane_nodes:',a)
t=t[:a]+'''\t\tif obstacle.kind == "fly":
			cliff_face(z + 0.4, base_y, false)
			cliff_face(z - obstacle.span - 0.4, level.height_at(obstacle.start + obstacle.span), true)
		elif obstacle.kind == "swim":
			water(Vector3(0, base_y - 0.28, z - obstacle.span / 2), 13.5, obstacle.span)
			for bank in [0.0, obstacle.span]:
				for x in range(-6, 7): rock(Vector3(x, base_y - 0.55, z - bank), Vector3(0.65, 0.28, 0.65), Color("e2ac58"))
''' +t[b:]
t=t.replace('Color("b8c7d4") if col % 2 else Color("d5dee8")','Color("979bc0") if col % 2 else Color("aeb3d4")')
t=t.replace('for i in range(85):','for i in range(42):')
t=t.replace('var z := -i * 4.7 + 12','var z := -i * 9.5 + 12')
t=t.replace('Color("87c63f")','Color("84ad40")')
a=t.index('\t\tfor i in range(int((end - start) / 3) + 1):')
b=t.index('\n\nfunc _process',a)
t=t[:a]+'''\t\tfor i in range(int((end - start) / 6) + 1):
			var chip := box(Vector3(rng.randf_range(0.45, 1.05), 0.06, rng.randf_range(1.3, 3.8)), Vector3(side * 4.48, y + 0.02, -minf(end, start + i * 6)), Color("84ad40"))
			chip.rotation.y = rng.randf_range(-0.45, 0.45)
''' +t[b:]
t=t.replace('\t\t\t\t"shield":\n','''\t\t\t\t"shield":
					box(Vector3(2.95, 0.02, obstacle.span), Vector3(lane, 0.025, z - obstacle.span / 2), Color("a95e2d"), group)
					for j in range(14): rock(Vector3(lane + rng.randf_range(-1.4, 1.4), 0.04, z - rng.randf_range(0, obstacle.span)), Vector3(0.35, 0.12, 0.48), Color("be7738"), group)
''')
p.write_text(t,encoding='utf-8')
