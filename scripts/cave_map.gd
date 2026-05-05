class_name CaveMap
extends BaseMap

## 地下洞穴：棕褐色，弯曲通道，钟乳石柱

func _ready() -> void:
	ground_color = Color(0.28, 0.22, 0.16, 1)
	sky_color = Color(0.12, 0.10, 0.08, 1)
	ambient_color = Color(0.42, 0.35, 0.25, 1)
	sun_energy = 0.6
	super._ready()

func _build_terrain() -> void:
	var rock := Color(0.38, 0.30, 0.22, 1)
	var dark_rock := Color(0.22, 0.17, 0.12, 1)
	var stalagmite := Color(0.45, 0.36, 0.26, 1)

	## 洞穴通道墙壁
	_create_box("CaveWallL1", Vector3(-14, 3.5, -5), Vector3(4, 7, 30), dark_rock)
	_create_box("CaveWallR1", Vector3(14, 3.5, 5), Vector3(4, 7, 30), dark_rock)
	_create_box("CaveWallL2", Vector3(-8, 3.5, 20), Vector3(3, 7, 20), rock)
	_create_box("CaveWallR2", Vector3(8, 3.5, -20), Vector3(3, 7, 20), rock)

	## 天花板岩柱（钟乳石/石笋柱）
	var pillars := [
		Vector3(-4, 2.5, -8), Vector3(4, 2.5, 8), Vector3(-10, 2.5, 14),
		Vector3(10, 2.5, -14), Vector3(0, 2.5, 0), Vector3(-18, 2.5, -18),
		Vector3(18, 2.5, 18)
	]
	for i in range(pillars.size()):
		_create_box("Pillar%d" % i, pillars[i], Vector3(2.8, 5.0, 2.8), stalagmite)

	## 大岩块掩体
	var boulders := [
		Vector3(-22, 1.5, 0), Vector3(22, 1.5, 0),
		Vector3(0, 1.5, -26), Vector3(0, 1.5, 26),
		Vector3(-16, 1.5, -20), Vector3(16, 1.5, 20)
	]
	for i in range(boulders.size()):
		_create_box("Boulder%d" % i, boulders[i], Vector3(5, 3.0, 4), dark_rock)

func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-28, 1.1, 32), Vector3(-22, 1.1, 32), Vector3(-16, 1.1, 32),
		Vector3(-28, 1.1, 26), Vector3(-20, 1.1, 26)
	]
	orange_spawns = [
		Vector3(28, 1.1, -32), Vector3(22, 1.1, -32), Vector3(16, 1.1, -32),
		Vector3(28, 1.1, -26), Vector3(20, 1.1, -26)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-14, 1.1, -5), Vector3(14, 1.1, 5),
		Vector3(-8, 1.1, 20), Vector3(8, 1.1, -20),
		Vector3(-22, 1.1, 0), Vector3(22, 1.1, 0),
		Vector3(0, 1.1, -24), Vector3(0, 1.1, 24)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
