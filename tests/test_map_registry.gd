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

	var map_select_source := FileAccess.get_file_as_string("res://scripts/map_select.gd")
	t.is_true(map_select_source.contains("const MAP_REGISTRY := preload(\"res://scripts/map_registry.gd\")"), "地图选择页应通过脚本类型访问地图注册表静态函数")
	t.is_false(map_select_source.contains("MapRegistry.get_cost("), "地图选择页不应通过 Autoload 实例调用静态 get_cost")
	t.is_true(map_select_source.contains("func _reward_amount_for_unlock(cost: int) -> int"), "星星不足时应有按地图缺口补足奖励的入口")
	t.is_true(map_select_source.contains("正在加载地图"), "进入比赛前应显示正在加载地图")
	t.is_true(map_select_source.contains("return maxi(1, cost - PlayerData.total_stars)"), "解锁奖励应按当前缺口补足，而不是固定 +3")
	t.is_false(map_select_source.contains("var amount := 3"), "解锁奖励不应固定只加 3 星")

	var base_source := FileAccess.get_file_as_string("res://scripts/base_map.gd")
	t.is_true(base_source.contains("func _make_procedural_texture"), "地图基础材质应使用程序化纹理")
	t.is_true(base_source.contains("func _create_cylinder"), "地图基础工具应支持圆柱体装饰")
	t.is_true(base_source.contains("func _create_tapered_cylinder"), "地图基础工具应支持圆锥/锥台建模")
	t.is_true(base_source.contains("func _create_sphere"), "地图基础工具应支持球体/树冠/烟雾建模")
	t.is_true(base_source.contains("func _create_neon_tube"), "地图基础工具应支持霓虹灯管建模")
	t.is_true(base_source.contains("func _create_rock"), "地图基础工具应支持不规则岩石/雪堆装饰")
	t.is_true(base_source.contains("func _create_light"), "地图基础工具应支持局部灯光")
	t.is_true(base_source.contains("func _create_trash_bin") and base_source.contains("func _create_lamp_post"), "地图基础工具应支持高细节垃圾桶和灯柱")
	t.is_true(base_source.contains("cylinder.radial_segments = 32"), "圆柱类道具应提高细分，避免低模外观")
	t.is_true(base_source.contains("mat.emission_enabled = true"), "高级材质应支持发光效果")
	t.is_true(base_source.contains("func _add_theme_props(theme: String)"), "所有地图应可添加主题化装饰")
	t.is_true(base_source.contains("MATERIAL_BRIGHTNESS_BOOST := 0.18"), "所有地图材质应统一进一步提亮")
	t.is_true(base_source.contains("func _improve_material_color"), "地图材质应通过公共入口改善颜色")
	t.is_true(base_source.contains("MATERIAL_TEXTURE_CONTRAST := 1.2"), "地图纹理应进一步增强细节对比")

	var model_source := FileAccess.get_file_as_string("res://scripts/model_factory.gd")
	t.is_true(model_source.contains("func _make_premium_material"), "Characters and weapons should use premium procedural materials")
	t.is_true(model_source.contains("mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED"), "Characters and weapons should stay opaque on Android")
	t.is_true(model_source.contains("mat.cull_mode = BaseMaterial3D.CULL_DISABLED"), "Characters and weapons should render from stable mobile angles")
	t.is_true(model_source.contains("mat.metallic = 0.72"), "Gun metal should have a stronger metallic finish")
	t.is_true(model_source.contains("mat.emission_energy_multiplier = 1.65"), "Highlighted parts should have premium glow")
	var soldier := ModelFactory.create_soldier_model("blue")
	t.is_true(soldier.get_child_count() > 0, "Soldier model should create visible mesh parts")
	var m416 := ModelFactory.create_weapon_model("m416", true)
	t.is_true(m416.get_child_count() > 0, "Weapon model should create visible mesh parts")

	var player_source := FileAccess.get_file_as_string("res://scripts/player_controller.gd")
	t.is_false(player_source.contains("_spectate_target.set_spectate_hidden(true)"), "Spectator camera should not hide the watched teammate model")

	var night_source := FileAccess.get_file_as_string("res://scripts/night_city_map.gd")
	t.is_true(night_source.contains("NightMainRoad"), "夜城应有黑色主路而不是只换颜色")
	t.is_true(night_source.contains("HoloBillboardCyan"), "夜城应有发光全息广告牌")
	t.is_true(night_source.contains("SkybridgeTube"), "夜城应有霓虹灯管轮廓")
	t.is_true(night_source.contains("WetPuddle") and night_source.contains("CrosswalkStripe"), "夜城应有湿润柏油、斑马线等真实街道细节")
	t.is_true(night_source.contains("FacadeRib") and night_source.contains("StreetVent"), "夜城应有建筑立面和街道金属细节")
	t.is_true(night_source.contains("StreetTrashBin") and night_source.contains("NightLampPost"), "夜城应有高细节垃圾桶和真实灯柱")

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
