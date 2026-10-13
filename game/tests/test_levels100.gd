extends SceneTree

func _init() -> void:
	var catalog := AnimalCatalog.definitions()
	var min_count := 99
	var max_count := 0
	var river := 0
	for n in range(1, 101):
		var level := LevelDefinition.create(n)
		min_count = mini(min_count, level.obstacles.size())
		max_count = maxi(max_count, level.obstacles.size())
		if level.biome == "river": river += 1
		if level.team.size() != 3:
			push_error("LEVEL_TEAM_FAIL %d" % n)
			quit(1)
		for obstacle in level.obstacles:
			var passable := false
			for id in level.team:
				if catalog[id].ability == obstacle.kind:
					passable = true
			if not passable:
				push_error("LEVEL_UNSOLVABLE %d %s" % [n, obstacle.kind])
				quit(1)
	print("LEVELS100_PASS min_obstacles=%d max_obstacles=%d river_levels=%d" % [min_count, max_count, river])
	quit(0)
