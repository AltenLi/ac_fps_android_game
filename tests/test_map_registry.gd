extends RefCounted

const MAP_REGISTRY := preload("res://scripts/map_registry.gd")

func run(t) -> void:
	t.equal(MAP_REGISTRY.MAPS.size(), 11, "地图数量应为 11")
	var seen := {}
	for m: Dictionary in MAP_REGISTRY.MAPS:
		var id := str(m.get("id", ""))
		t.is_true(id.length() > 0, "地图 id 不能为空")
		t.is_false(seen.has(id), "地图 id 不应重复：%s" % id)
		seen[id] = true
		t.resource_exists(str(m.get("scene", "")), "地图场景必须存在：%s" % id)
		t.is_true(int(m.get("cost", -1)) >= 0, "地图成本不能为负：%s" % id)
	t.equal(MAP_REGISTRY.get_scene_path("missing"), MAP_REGISTRY.get_scene_path(MAP_REGISTRY.DEFAULT_MAP_ID), "非法地图应回退默认地图")
	t.equal(MAP_REGISTRY.get_free_map_ids(), ["city", "desert", "snow"], "前三张地图应免费")
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
		t.equal(MAP_REGISTRY.get_cost(map_id), int(expected_costs[map_id]), "地图解锁成本应符合递增经济：%s" % map_id)

	var base_source := FileAccess.get_file_as_string("res://scripts/base_map.gd")
	t.is_true(base_source.contains("func _make_procedural_texture"), "地图基础材质应使用程序化纹理")
	t.is_true(base_source.contains("func _create_cylinder"), "地图基础工具应支持圆柱体装饰")
	t.is_true(base_source.contains("func _create_tapered_cylinder"), "地图基础工具应支持圆锥/锥台建模")
	t.is_true(base_source.contains("func _create_sphere"), "地图基础工具应支持球体/树冠/烟雾建模")
	t.is_true(base_source.contains("func _create_neon_tube"), "地图基础工具应支持霓虹灯管建模")
	t.is_true(base_source.contains("func _create_rock"), "地图基础工具应支持不规则岩石/雪堆装饰")
	t.is_true(base_source.contains("func _create_light"), "地图基础工具应支持局部灯光")
	t.is_true(base_source.contains("mat.emission_enabled = true"), "高级材质应支持发光效果")
	t.is_true(base_source.contains("func _add_theme_props(theme: String)"), "所有地图应可添加主题化装饰")

	var night_source := FileAccess.get_file_as_string("res://scripts/night_city_map.gd")
	t.is_true(night_source.contains("NightMainRoad"), "夜城应有黑色主路而不是只换颜色")
	t.is_true(night_source.contains("HoloBillboardCyan"), "夜城应有发光全息广告牌")
	t.is_true(night_source.contains("SkybridgeTube"), "夜城应有霓虹灯管轮廓")

	var volcano_source := FileAccess.get_file_as_string("res://scripts/volcano_map.gd")
	t.is_true(volcano_source.contains("VolcanoCone") and volcano_source.contains("_create_tapered_cylinder"), "火山应使用锥台火山体")
	t.is_true(volcano_source.contains("CraterLavaPool"), "火山应有发光火山口熔岩池")
	t.is_true(volcano_source.contains("SmokePuff"), "火山应有烟雾体积装饰")

	var jungle_source := FileAccess.get_file_as_string("res://scripts/jungle_map.gd")
	t.is_true(jungle_source.contains("TreeTrunk") and jungle_source.contains("TreeCanopy"), "丛林应有圆柱树干和球状树冠")
	t.is_true(jungle_source.contains("HangingVine"), "丛林应有藤蔓装饰")
	t.is_true(jungle_source.contains("CampHutARoof"), "丛林木屋应有茅草屋顶轮廓")

	var themed_maps := {
		"city": "res://scripts/city_map.gd",
		"desert": "res://scripts/desert_map.gd",
		"snow": "res://scripts/snow_map.gd",
		"factory": "res://scripts/factory_map.gd",
		"jungle": "res://scripts/jungle_map.gd",
		"ruins": "res://scripts/ruins_map.gd",
		"harbor": "res://scripts/harbor_map.gd",
		"night_city": "res://scripts/night_city_map.gd",
		"cave": "res://scripts/cave_map.gd",
		"space": "res://scripts/space_map.gd",
		"volcano": "res://scripts/volcano_map.gd",
	}
	for map_id: String in themed_maps.keys():
		var source := FileAccess.get_file_as_string(str(themed_maps[map_id]))
		t.is_true(source.contains("_add_theme_props(\"%s\")" % map_id), "地图应添加符合主题的高级装饰：%s" % map_id)
