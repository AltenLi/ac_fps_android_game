extends RefCounted

func run(t) -> void:
	t.equal(MapRegistry.MAPS.size(), 11, "地图数量应为 11")
	var seen := {}
	for m: Dictionary in MapRegistry.MAPS:
		var id := str(m.get("id", ""))
		t.is_true(id.length() > 0, "地图 id 不能为空")
		t.is_false(seen.has(id), "地图 id 不应重复：%s" % id)
		seen[id] = true
		t.resource_exists(str(m.get("scene", "")), "地图场景必须存在：%s" % id)
		t.is_true(int(m.get("cost", -1)) >= 0, "地图成本不能为负：%s" % id)
	t.equal(MapRegistry.get_scene_path("missing"), MapRegistry.get_scene_path(MapRegistry.DEFAULT_MAP_ID), "非法地图应回退默认地图")
	t.equal(MapRegistry.get_free_map_ids(), ["city", "desert", "snow"], "前三张地图应免费")
	var expected_costs := {
		"city": 0,
		"desert": 0,
		"snow": 0,
		"factory": 6,
		"jungle": 10,
		"ruins": 10,
		"harbor": 12,
		"night_city": 12,
		"cave": 15,
		"space": 15,
		"volcano": 18,
	}
	for map_id: String in expected_costs.keys():
		t.equal(MapRegistry.get_cost(map_id), int(expected_costs[map_id]), "地图解锁成本应符合递增经济：%s" % map_id)
