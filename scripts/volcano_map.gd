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
	var glowing := Color(0.95, 0.52, 0.08, 1)
	var black_rock := Color(0.18, 0.10, 0.06, 1)

	## 中央火山锥
	_create_box("VolcanoCone", Vector3(0, 6.0, 0), Vector3(16, 12, 16), lava_rock)
	_create_box("VolcanoRim", Vector3(0, 12.2, 0), Vector3(18, 0.5, 18), hot_rock)
	_create_box("CraterInner", Vector3(0, 10.0, 0), Vector3(8, 4, 8), glowing)

	## 熔岩流（发光橙色地面条）
	_create_box("LavaFlowN", Vector3(0, 0.1, -20), Vector3(6, 0.3, 20), glowing)
	_create_box("LavaFlowS", Vector3(0, 0.1, 20), Vector3(6, 0.3, 20), glowing)
	_create_box("LavaFlowW", Vector3(-20, 0.1, 0), Vector3(20, 0.3, 6), glowing)
	_create_box("LavaFlowE", Vector3(20, 0.1, 0), Vector3(20, 0.3, 6), glowing)

	## 冷却岩石掩体
	var rocks := [
		Vector3(-12, 1.5, -12), Vector3(12, 1.5, 12),
		Vector3(-12, 1.5, 12), Vector3(12, 1.5, -12),
		Vector3(-22, 1.5, 0), Vector3(22, 1.5, 0),
		Vector3(0, 1.5, -28), Vector3(0, 1.5, 28)
	]
	for i in range(rocks.size()):
		_create_box("LavaRock%d" % i, rocks[i], Vector3(5, 3.0, 4), black_rock if i % 2 == 0 else hot_rock)

	## 火山口周围矮墙
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var r := 12.0
		_create_box("RimBlock%d" % i,
			Vector3(cos(angle) * r, 1.5, sin(angle) * r), Vector3(3.5, 3.0, 3.5), lava_rock)

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
		Vector3(0, 1.1, 0), Vector3(-12, 1.1, -12), Vector3(12, 1.1, 12),
		Vector3(-12, 1.1, 12), Vector3(12, 1.1, -12),
		Vector3(-22, 1.1, 0), Vector3(22, 1.1, 0),
		Vector3(0, 1.1, -28), Vector3(0, 1.1, 28)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
