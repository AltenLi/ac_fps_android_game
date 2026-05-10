class_name NightCityMap
extends BaseMap

## 霓虹都市：深色地面，发光边框建筑，赛博朋克风格

func _ready() -> void:
	ground_color = Color(0.08, 0.08, 0.10, 1)
	sky_color = Color(0.06, 0.04, 0.12, 1)
	ambient_color = Color(0.22, 0.16, 0.40, 1)
	sun_energy = 0.8
	super._ready()

func _build_terrain() -> void:
	var neon_purple := Color(0.62, 0.10, 0.88, 1)
	var neon_cyan := Color(0.10, 0.78, 0.88, 1)
	var neon_pink := Color(0.90, 0.12, 0.55, 1)
	var dark_building := Color(0.10, 0.09, 0.15, 1)
	var black_glass := Color(0.04, 0.04, 0.075, 1)

	## 夜城一眼识别：中轴黑色柏油路 + 两侧高楼峡谷
	_create_box("NightMainRoad", Vector3(0, 0.06, 0), Vector3(12, 0.10, 78), Color(0.025, 0.026, 0.032, 1), Vector3.ZERO, "asphalt", false)
	_create_box("NightCrossRoad", Vector3(0, 0.07, 0), Vector3(76, 0.10, 10), Color(0.028, 0.028, 0.036, 1), Vector3.ZERO, "asphalt", false)
	for z in [-30.0, -18.0, -6.0, 6.0, 18.0, 30.0]:
		_create_neon_tube("RoadCyanStripe%d" % int(z), Vector3(-6.4, 0.18, z), 7.0, 0.08, neon_cyan, Vector3(90, 0, 0))
		_create_neon_tube("RoadPinkStripe%d" % int(z), Vector3(6.4, 0.18, z), 7.0, 0.08, neon_pink, Vector3(90, 0, 0))

	## 高楼建筑群，使用金属/玻璃纹理；窗口和招牌单独发光
	var towers := [
		["TowerA", Vector3(-25, 9.0, -18), Vector3(10, 18, 11), dark_building, neon_purple],
		["TowerB", Vector3(25, 9.0, 18), Vector3(10, 18, 11), dark_building, neon_cyan],
		["TowerC", Vector3(-25, 6.0, 18), Vector3(8, 12, 12), black_glass, neon_pink],
		["TowerD", Vector3(25, 6.0, -18), Vector3(8, 12, 12), black_glass, neon_purple],
	]
	for i in range(towers.size()):
		var t: Array = towers[i]
		_create_box(str(t[0]), t[1], t[2], t[3], Vector3.ZERO, "sci_fi")
		_create_box("TowerGlowCap%d" % i, t[1] + Vector3(0, (t[2] as Vector3).y * 0.5 + 0.18, 0), Vector3((t[2] as Vector3).x + 0.6, 0.22, (t[2] as Vector3).z + 0.6), t[4], Vector3.ZERO, "neon", false, Color((t[4] as Color).r, (t[4] as Color).g, (t[4] as Color).b, 0.85))
		for row in range(4):
			_create_box("LitWindow%d_%d" % [i, row], t[1] + Vector3(0, 3.2 + row * 2.7, -((t[2] as Vector3).z * 0.5 + 0.06)), Vector3(5.8, 0.65, 0.08), t[4], Vector3.ZERO, "screen", false, Color((t[4] as Color).r, (t[4] as Color).g, (t[4] as Color).b, 0.62))

	## 空中广告牌和发光灯管，形成赛博朋克轮廓
	_create_box("HoloBillboardCyan", Vector3(0, 7.2, -30), Vector3(13, 3.8, 0.22), neon_cyan, Vector3.ZERO, "screen", false, Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, 0.9))
	_create_box("HoloBillboardPink", Vector3(0, 6.0, 30), Vector3(12, 3.2, 0.22), neon_pink, Vector3.ZERO, "screen", false, Color(neon_pink.r, neon_pink.g, neon_pink.b, 0.9))
	_create_neon_tube("SkybridgeTubeL", Vector3(0, 6.4, -18), 48.0, 0.12, neon_purple, Vector3(0, 0, 90))
	_create_neon_tube("SkybridgeTubeR", Vector3(0, 6.4, 18), 48.0, 0.12, neon_cyan, Vector3(0, 0, 90))

	## 地面掩体仍可打，但降低体量，避免挡住主路
	var covers := [
		[Vector3(-12, 0.9, 7), Vector3(5, 1.8, 3), neon_purple],
		[Vector3(12, 0.9, -7), Vector3(5, 1.8, 3), neon_pink],
		[Vector3(-9, 0.9, -22), Vector3(5, 1.8, 3), neon_cyan],
		[Vector3(9, 0.9, 22), Vector3(5, 1.8, 3), neon_purple],
	]
	for i in range(covers.size()):
		var c: Array = covers[i]
		_create_box("NeonCover%d" % i, c[0], c[1], c[2], Vector3.ZERO, "neon", true, Color((c[2] as Color).r, (c[2] as Color).g, (c[2] as Color).b, 0.5))
	_add_theme_props("night_city")

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-15, 1.1, -6), Vector3(15, 1.1, 6),
		Vector3(-14, 1.1, 24), Vector3(14, 1.1, -24),
		Vector3(-34, 1.1, 10), Vector3(34, 1.1, -10),
		Vector3(0, 1.1, -32), Vector3(0, 1.1, 32)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
