class_name VolcanoMap
extends BaseMap

## 火山熔岩：橙红色地面，岩浆色掩体，熔岩地貌

func _ready() -> void:
	ground_color = Color(0.24, 0.12, 0.06, 1)
	sky_color = Color(0.52, 0.24, 0.08, 1)
	ambient_color = Color(0.80, 0.42, 0.16, 1)
	sun_energy = 2.0
	super._ready()

func _build_terrain() -> void:
	var lava_rock := Color(0.32, 0.14, 0.06, 1)
	var hot_rock := Color(0.55, 0.22, 0.06, 1)
	var glowing := Color(1.0, 0.34, 0.04, 1)
	var black_rock := Color(0.14, 0.08, 0.055, 1)
	var smoke := Color(0.22, 0.18, 0.16, 0.62)

	## 火山一眼识别：圆锥火山 + 发光火山口，不再是方块山
	_create_tapered_cylinder("VolcanoCone", Vector3(0, 5.2, 0), 13.5, 5.2, 10.4, lava_rock, Vector3.ZERO, "stone", true)
	_create_tapered_cylinder("VolcanoRim", Vector3(0, 10.7, 0), 7.0, 8.8, 1.0, hot_rock, Vector3.ZERO, "stone", false)
	_create_cylinder("CraterLavaPool", Vector3(0, 11.28, 0), 4.6, 0.22, glowing, Vector3.ZERO, "lava", false, Color(1.0, 0.24, 0.02, 0.95))
	_create_light("CraterCoreLight", Vector3(0, 12.2, 0), Color(1.0, 0.22, 0.04, 1), 1.7, 18.0)
	for i in range(4):
		_create_sphere("SmokePuff%d" % i, Vector3(-1.5 + i, 13.4 + i * 0.65, 0.8 - i * 0.35), Vector3(1.1 + i * 0.25, 0.7, 1.1 + i * 0.25), smoke, "smoke", false)

	## 发光熔岩流：视觉层无碰撞，保持通行但强烈区分主题
	var flows := [
		["LavaFlowN", Vector3(0, 0.12, -23), Vector3(5.6, 0.16, 22), Vector3.ZERO],
		["LavaFlowS", Vector3(0, 0.12, 23), Vector3(5.6, 0.16, 22), Vector3.ZERO],
		["LavaFlowW", Vector3(-23, 0.12, 0), Vector3(22, 0.16, 5.6), Vector3.ZERO],
		["LavaFlowE", Vector3(23, 0.12, 0), Vector3(22, 0.16, 5.6), Vector3.ZERO],
	]
	for f in flows:
		_create_box(str(f[0]), f[1], f[2], glowing, f[3], "lava", false, Color(1.0, 0.20, 0.02, 0.85))

	## 冷却岩石掩体改成不规则岩块
	var rocks := [
		Vector3(-16, 1.1, -15), Vector3(16, 1.1, 15),
		Vector3(-16, 1.1, 15), Vector3(16, 1.1, -15),
		Vector3(-29, 1.1, 3), Vector3(29, 1.1, -3),
		Vector3(-5, 1.1, -32), Vector3(5, 1.1, 32)
	]
	for i in range(rocks.size()):
		_create_rock("ObsidianRock%d" % i, rocks[i], Vector3(2.4, 1.35, 1.8), black_rock if i % 2 == 0 else hot_rock, "stone", true)

	## 环形火山碎石与熔岩裂缝
	for i in range(10):
		var angle := float(i) * TAU / 10.0
		var r := 15.0
		_create_rock("RimBasalt%d" % i, Vector3(cos(angle) * r, 1.0, sin(angle) * r), Vector3(1.45, 0.9, 1.2), lava_rock, "stone", true)
		_create_neon_tube("HotCrackTube%d" % i, Vector3(cos(angle) * 24.0, 0.18, sin(angle) * 24.0), 7.0, 0.10, glowing, Vector3(90, rad_to_deg(-angle), 0))
	_add_theme_props("volcano")

func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-30, 1.1, 34), Vector3(-24, 1.1, 34), Vector3(-18, 1.1, 34),
		Vector3(-30, 1.1, 28), Vector3(-22, 1.1, 28)
	]
	orange_spawns = [
		Vector3(30, 1.1, -34), Vector3(24, 1.1, -34), Vector3(18, 1.1, -34),
		Vector3(30, 1.1, -28), Vector3(22, 1.1, -28)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(-24, 1.1, -10), Vector3(24, 1.1, 10),
		Vector3(-24, 1.1, 10), Vector3(24, 1.1, -10),
		Vector3(-33, 1.1, 0), Vector3(33, 1.1, 0),
		Vector3(-8, 1.1, -32), Vector3(8, 1.1, 32),
		Vector3(0, 1.1, -36), Vector3(0, 1.1, 36)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
