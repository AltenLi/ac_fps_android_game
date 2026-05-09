extends Node

## 地图注册表：统一管理全部11张地图的元数据。

const DEFAULT_MAP_ID := "city"

const MAPS: Array[Dictionary] = [
	{
		"id": "city",
		"name": "城市巷战",
		"desc": "中路、侧巷、掩体、屋顶平台的沙色城市地图。",
		"scene": "res://scenes/city_map.tscn",
		"color": Color(0.56, 0.42, 0.22, 1),
		"cost": 0,
	},
	{
		"id": "desert",
		"name": "沙漠要塞",
		"desc": "开阔黄沙地形，中央堡垒四角瞭望塔，低矮掩体遍布。",
		"scene": "res://scenes/desert_map.tscn",
		"color": Color(0.78, 0.62, 0.28, 1),
		"cost": 0,
	},
	{
		"id": "snow",
		"name": "雪原基地",
		"desc": "白茫茫雪地，宽阔通道，混凝土碉堡居中。",
		"scene": "res://scenes/snow_map.tscn",
		"color": Color(0.82, 0.88, 0.95, 1),
		"cost": 0,
	},
	{
		"id": "factory",
		"name": "废弃工厂",
		"desc": "灰色钢铁厂房，锈色钢架，仓库通道与铁箱掩体。",
		"scene": "res://scenes/factory_map.tscn",
		"color": Color(0.38, 0.35, 0.30, 1),
		"cost": 6,
	},
	{
		"id": "jungle",
		"name": "丛林营地",
		"desc": "绿色丛林，巨型树桩柱，木屋营地，石堆掩体。",
		"scene": "res://scenes/jungle_map.tscn",
		"color": Color(0.22, 0.45, 0.18, 1),
		"cost": 10,
	},
	{
		"id": "ruins",
		"name": "古城遗迹",
		"desc": "棕色石砖古迹，双门神殿居中，残垣断壁散布全图。",
		"scene": "res://scenes/ruins_map.tscn",
		"color": Color(0.52, 0.42, 0.28, 1),
		"cost": 10,
	},
	{
		"id": "harbor",
		"name": "海港码头",
		"desc": "蓝灰色港口，彩色集装箱堆叠，钢铁仓库扼守两端。",
		"scene": "res://scenes/harbor_map.tscn",
		"color": Color(0.22, 0.38, 0.52, 1),
		"cost": 12,
	},
	{
		"id": "night_city",
		"name": "霓虹都市",
		"desc": "赛博朋克暗夜都市，紫青粉霓虹灯高楼，夜色掩体。",
		"scene": "res://scenes/night_city_map.tscn",
		"color": Color(0.28, 0.08, 0.45, 1),
		"cost": 12,
	},
	{
		"id": "cave",
		"name": "地下洞穴",
		"desc": "幽暗地下洞穴，弯曲通道，石笋柱，巨型岩块掩体。",
		"scene": "res://scenes/cave_map.tscn",
		"color": Color(0.28, 0.22, 0.16, 1),
		"cost": 15,
	},
	{
		"id": "space",
		"name": "太空站",
		"desc": "深空站，白色金属核心模块，蓝绿发光走廊，设备箱掩体。",
		"scene": "res://scenes/space_map.tscn",
		"color": Color(0.18, 0.22, 0.38, 1),
		"cost": 15,
	},
	{
		"id": "volcano",
		"name": "火山熔岩",
		"desc": "橙红火山地貌，熔岩流贯穿全图，火山锥居中爆发。",
		"scene": "res://scenes/volcano_map.tscn",
		"color": Color(0.55, 0.22, 0.06, 1),
		"cost": 18,
	},
]

static func get_map(map_id: String) -> Dictionary:
	for m: Dictionary in MAPS:
		if str(m.get("id", "")) == map_id:
			return m
	return MAPS[0]

static func is_valid_map_id(map_id: String) -> bool:
	for m: Dictionary in MAPS:
		if str(m.get("id", "")) == map_id:
			return true
	return false

static func get_scene_path(map_id: String) -> String:
	return str(get_map(map_id).get("scene", MAPS[0]["scene"]))

static func get_cost(map_id: String) -> int:
	return maxi(0, int(get_map(map_id).get("cost", 0)))

static func is_free_map(map_id: String) -> bool:
	return get_cost(map_id) <= 0

static func get_free_map_ids() -> Array[String]:
	var ids: Array[String] = []
	for m: Dictionary in MAPS:
		if int(m.get("cost", 0)) <= 0:
			ids.append(str(m.get("id", "")))
	return ids
