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
	var neon_blue := Color(0.18, 0.42, 1.0, 1)
	var dark_building := Color(0.075, 0.07, 0.12, 1)
	var black_glass := Color(0.035, 0.04, 0.07, 0.92)
	var asphalt := Color(0.018, 0.019, 0.024, 1)
	var sidewalk := Color(0.16, 0.16, 0.19, 1)

	## 夜城核心识别：湿润黑色柏油主路 + 十字路 + 混凝土人行道，形成清晰战斗动线。
	_create_box("NightMainRoad", Vector3(0, 0.06, 0), Vector3(12, 0.10, 78), asphalt, Vector3.ZERO, "asphalt", false)
	_create_box("NightCrossRoad", Vector3(0, 0.07, 0), Vector3(76, 0.10, 10), asphalt.lightened(0.02), Vector3.ZERO, "asphalt", false)
	for x_value in [-12.5, 12.5, -39.0, 39.0]:
		var x := float(x_value)
		var width := 5.6 if absf(x) < 20.0 else 7.0
		_create_box("SidewalkStrip%d" % int(x), Vector3(x, 0.11, 0), Vector3(width, 0.12, 78), sidewalk, Vector3.ZERO, "concrete", false)
	for z_value in [-12.5, 12.5]:
		var z := float(z_value)
		_create_box("CrossSidewalkStrip%d" % int(z), Vector3(0, 0.12, z), Vector3(76, 0.12, 5.4), sidewalk.darkened(0.05), Vector3.ZERO, "concrete", false)
	_add_street_surface_details(neon_cyan, neon_pink)

	## 多层玻璃高楼峡谷：主楼负责压迫感，副楼负责天际线层次，窗格/肋条提供真实立面纹理。
	var towers := [
		["TowerA", Vector3(-25, 10.5, -18), Vector3(10, 21, 11), dark_building, neon_purple, 7],
		["TowerB", Vector3(25, 10.5, 18), Vector3(10, 21, 11), dark_building, neon_cyan, 7],
		["TowerC", Vector3(-25, 7.0, 18), Vector3(8, 14, 12), black_glass, neon_pink, 5],
		["TowerD", Vector3(25, 7.0, -18), Vector3(8, 14, 12), black_glass, neon_purple, 5],
		["TowerE", Vector3(-36, 6.0, -2), Vector3(6, 12, 9), Color(0.08, 0.085, 0.13, 1), neon_blue, 4],
		["TowerF", Vector3(36, 6.0, 2), Vector3(6, 12, 9), Color(0.08, 0.075, 0.12, 1), neon_pink, 4],
	]
	for i in range(towers.size()):
		var t: Array = towers[i]
		_build_neon_tower(str(t[0]), t[1] as Vector3, t[2] as Vector3, t[3] as Color, t[4] as Color, int(t[5]))

	## 空中广告牌、扫描线和灯管构成赛博朋克轮廓；保留关键节点名供测试与地图识别使用。
	_add_holo_billboard("HoloBillboardCyan", Vector3(0, 7.2, -30), Vector3(13, 3.8, 0.22), neon_cyan)
	_add_holo_billboard("HoloBillboardPink", Vector3(0, 6.0, 30), Vector3(12, 3.2, 0.22), neon_pink)
	_create_neon_tube("SkybridgeTubeL", Vector3(0, 6.4, -18), 48.0, 0.12, neon_purple, Vector3(0, 0, 90))
	_create_neon_tube("SkybridgeTubeR", Vector3(0, 6.4, 18), 48.0, 0.12, neon_cyan, Vector3(0, 0, 90))
	_create_neon_tube("SkybridgeLowerCableL", Vector3(0, 5.95, -18), 48.0, 0.055, neon_pink, Vector3(0, 0, 90))
	_create_neon_tube("SkybridgeLowerCableR", Vector3(0, 5.95, 18), 48.0, 0.055, neon_blue, Vector3(0, 0, 90))

	## 地面掩体做成真实街区物件：发光交通隔离墩、金属通风机、低矮服务柜，不阻塞主路线。
	var covers := [
		["NeonCover0", Vector3(-12, 0.9, 7), Vector3(5, 1.8, 3), neon_purple],
		["NeonCover1", Vector3(12, 0.9, -7), Vector3(5, 1.8, 3), neon_pink],
		["NeonCover2", Vector3(-9, 0.9, -22), Vector3(5, 1.8, 3), neon_cyan],
		["NeonCover3", Vector3(9, 0.9, 22), Vector3(5, 1.8, 3), neon_purple],
	]
	for i in range(covers.size()):
		var c: Array = covers[i]
		_create_box(str(c[0]), c[1] as Vector3, c[2] as Vector3, c[3] as Color, Vector3.ZERO, "metal", true)
		_create_box("%sGlowPanel" % str(c[0]), (c[1] as Vector3) + Vector3(0, 0.62, -((c[2] as Vector3).z * 0.5 + 0.055)), Vector3((c[2] as Vector3).x * 0.76, 0.34, 0.08), c[3] as Color, Vector3.ZERO, "neon", false, Color((c[3] as Color).r, (c[3] as Color).g, (c[3] as Color).b, 0.58))
	_add_street_props(neon_cyan, neon_pink, neon_purple)
	_add_neon_lighting(neon_cyan, neon_pink, neon_purple)
	_add_theme_props("night_city")

func _build_neon_tower(tower_name: String, pos: Vector3, size: Vector3, facade_color: Color, accent: Color, rows: int) -> void:
	_create_box(tower_name, pos, size, facade_color, Vector3.ZERO, "glass")
	_create_box("%sRoofGlow" % tower_name, pos + Vector3(0, size.y * 0.5 + 0.18, 0), Vector3(size.x + 0.6, 0.22, size.z + 0.6), accent, Vector3.ZERO, "neon", false, Color(accent.r, accent.g, accent.b, 0.82))
	for side in [-1, 1]:
		_create_box("%sFacadeRibX%d" % [tower_name, side], pos + Vector3(float(side) * (size.x * 0.5 + 0.045), 0, 0), Vector3(0.07, size.y * 0.92, 0.18), accent.darkened(0.1), Vector3.ZERO, "neon", false, Color(accent.r, accent.g, accent.b, 0.45))
		_create_box("%sFacadeRibZ%d" % [tower_name, side], pos + Vector3(0, 0, float(side) * (size.z * 0.5 + 0.045)), Vector3(0.18, size.y * 0.92, 0.07), accent.darkened(0.1), Vector3.ZERO, "neon", false, Color(accent.r, accent.g, accent.b, 0.45))
	for row in range(rows):
		var y := pos.y - size.y * 0.5 + 1.8 + float(row) * 2.35
		if y > pos.y + size.y * 0.5 - 0.8:
			continue
		_create_box("%sLitWindowFront%d" % [tower_name, row], Vector3(pos.x, y, pos.z - size.z * 0.5 - 0.055), Vector3(size.x * 0.58, 0.48, 0.06), accent, Vector3.ZERO, "screen", false, Color(accent.r, accent.g, accent.b, 0.58))
		_create_box("%sLitWindowSide%d" % [tower_name, row], Vector3(pos.x + size.x * 0.5 + 0.055, y, pos.z), Vector3(0.06, 0.48, size.z * 0.50), accent.lightened(0.1), Vector3.ZERO, "screen", false, Color(accent.r, accent.g, accent.b, 0.42))

func _add_holo_billboard(billboard_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	_create_box(billboard_name, pos, size, color, Vector3.ZERO, "hologram", false, Color(color.r, color.g, color.b, 0.9))
	_create_box("%sFrameTop" % billboard_name, pos + Vector3(0, size.y * 0.5 + 0.12, 0), Vector3(size.x + 0.7, 0.12, 0.32), color.lightened(0.05), Vector3.ZERO, "neon", false, Color(color.r, color.g, color.b, 0.85))
	_create_box("%sFrameBottom" % billboard_name, pos - Vector3(0, size.y * 0.5 + 0.12, 0), Vector3(size.x + 0.7, 0.12, 0.32), color.lightened(0.05), Vector3.ZERO, "neon", false, Color(color.r, color.g, color.b, 0.85))
	for i in range(4):
		var y := pos.y - size.y * 0.32 + float(i) * size.y * 0.21
		_create_box("%sScanline%d" % [billboard_name, i], Vector3(pos.x, y, pos.z - 0.13), Vector3(size.x * 0.82, 0.045, 0.06), color.lightened(0.18), Vector3.ZERO, "hologram", false, Color(color.r, color.g, color.b, 0.65))

func _add_street_surface_details(neon_cyan: Color, neon_pink: Color) -> void:
	for z_value in [-30.0, -18.0, -6.0, 6.0, 18.0, 30.0]:
		var z := float(z_value)
		_create_neon_tube("RoadCyanStripe%d" % int(z), Vector3(-6.4, 0.18, z), 7.0, 0.08, neon_cyan, Vector3(90, 0, 0))
		_create_neon_tube("RoadPinkStripe%d" % int(z), Vector3(6.4, 0.18, z), 7.0, 0.08, neon_pink, Vector3(90, 0, 0))
	for i in range(9):
		var z := -32.0 + float(i) * 8.0
		_create_box("RoadCenterDash%d" % i, Vector3(0, 0.16, z), Vector3(0.32, 0.055, 3.6), Color(0.90, 0.82, 0.45, 1), Vector3.ZERO, "paint", false)
	for i in range(7):
		var x := -4.8 + float(i) * 1.6
		_create_box("CrosswalkStripeNorth%d" % i, Vector3(x, 0.17, -8.2), Vector3(0.82, 0.055, 4.6), Color(0.76, 0.78, 0.82, 1), Vector3.ZERO, "paint", false)
		_create_box("CrosswalkStripeSouth%d" % i, Vector3(x, 0.17, 8.2), Vector3(0.82, 0.055, 4.6), Color(0.76, 0.78, 0.82, 1), Vector3.ZERO, "paint", false)
	for i in range(5):
		var x := -18.0 + float(i) * 9.0
		var z := -25.0 if i % 2 == 0 else 23.0
		_create_box("WetPuddle%d" % i, Vector3(x, 0.18, z), Vector3(4.8, 0.035, 2.2), Color(0.05, 0.12, 0.18, 0.58), Vector3(0, float(i) * 17.0, 0), "water", false)

func _add_street_props(neon_cyan: Color, neon_pink: Color, neon_purple: Color) -> void:
	for i in range(4):
		var z := -24.0 + float(i) * 16.0
		_create_box("StreetVent%d" % i, Vector3(-16.5, 0.26, z), Vector3(2.8, 0.18, 1.0), Color(0.08, 0.09, 0.105, 1), Vector3.ZERO, "metal", false)
		for slat in range(3):
			_create_box("StreetVent%dSlat%d" % [i, slat], Vector3(-16.5, 0.39, z - 0.28 + float(slat) * 0.28), Vector3(2.4, 0.055, 0.055), Color(0.22, 0.26, 0.30, 1), Vector3.ZERO, "metal", false)
		_create_cylinder("BollardCyan%d" % i, Vector3(7.6, 0.65, z), 0.16, 1.3, neon_cyan, Vector3.ZERO, "neon", false, Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, 0.7))
		_create_cylinder("BollardPink%d" % i, Vector3(-7.6, 0.65, -z), 0.16, 1.3, neon_pink, Vector3.ZERO, "neon", false, Color(neon_pink.r, neon_pink.g, neon_pink.b, 0.7))
		var bin_color := neon_cyan if i % 2 == 0 else neon_pink
		_create_trash_bin("StreetTrashBin%d" % i, Vector3(-18.5 if i % 2 == 0 else 18.5, 0.14, z + 3.4), 0.0, Color(0.030, 0.036, 0.046, 1), bin_color.darkened(0.45))
		_create_lamp_post("NightLampPost%d" % i, Vector3(10.6 if i % 2 == 0 else -10.6, 0.13, z - 3.4), bin_color, Color(0.025, 0.028, 0.034, 1), 4.8, 0.48, 8.5)
	for i in range(3):
		var x := -28.0 + float(i) * 28.0
		_create_cylinder("Manhole%d" % i, Vector3(x, 0.19, -2.5), 0.72, 0.06, Color(0.10, 0.11, 0.12, 1), Vector3.ZERO, "metal", false)
		_create_neon_tube("ServiceCable%d" % i, Vector3(x, 0.42, 16.0), 7.5, 0.035, neon_purple, Vector3(90, 0, 0))

func _add_neon_lighting(neon_cyan: Color, neon_pink: Color, neon_purple: Color) -> void:
	_create_light("NeonCyanKeyLight", Vector3(-18, 5.2, -24), neon_cyan, 0.75, 11.0)
	_create_light("NeonPinkKeyLight", Vector3(18, 5.0, 24), neon_pink, 0.75, 11.0)
	_create_light("NeonPurpleMidGlow", Vector3(0, 6.2, 0), neon_purple, 0.55, 12.5)
	for i in range(4):
		var z := -30.0 + float(i) * 20.0
		var color := neon_cyan if i % 2 == 0 else neon_pink
		_create_light("StreetLampGlow%d" % i, Vector3(-10.5 if i % 2 == 0 else 10.5, 3.4, z), color, 0.42, 7.5)

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-15, 1.1, -6), Vector3(15, 1.1, 6),
		Vector3(-14, 1.1, 24), Vector3(14, 1.1, -24),
		Vector3(-34, 1.1, 10), Vector3(34, 1.1, -10),
		Vector3(0, 1.1, -32), Vector3(0, 1.1, 32)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
