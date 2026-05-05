class_name FactoryMap
extends BaseMap

## 废弃工厂：灰色大型工业建筑，仓库走廊

func _ready() -> void:
	ground_color = Color(0.28, 0.28, 0.26, 1)
	sky_color = Color(0.32, 0.34, 0.38, 1)
	ambient_color = Color(0.55, 0.55, 0.60, 1)
	sun_energy = 1.4
	super._ready()

func _build_terrain() -> void:
	var metal := Color(0.42, 0.42, 0.40, 1)
	var dark_metal := Color(0.25, 0.25, 0.23, 1)
	var rust := Color(0.52, 0.30, 0.14, 1)

	## 大型厂房
	_create_box("FactoryHallA", Vector3(-16, 4.0, -8), Vector3(20, 8, 22), metal)
	_create_box("FactoryHallB", Vector3(16, 4.0, 8), Vector3(20, 8, 22), metal)

	## 中路走廊
	_create_box("CorridorWallL", Vector3(-3, 2.5, 0), Vector3(2.5, 5, 40), dark_metal)
	_create_box("CorridorWallR", Vector3(3, 2.5, 0), Vector3(2.5, 5, 40), dark_metal)

	## 机器/箱子掩体
	var crates := [
		Vector3(-10, 1.2, 4), Vector3(-10, 1.2, -4), Vector3(10, 1.2, 4), Vector3(10, 1.2, -4),
		Vector3(0, 1.2, 15), Vector3(0, 1.2, -15), Vector3(-20, 1.2, 0), Vector3(20, 1.2, 0)
	]
	for i in range(crates.size()):
		_create_box("Crate%d" % i, crates[i], Vector3(4, 2.4, 4), rust if i % 2 == 0 else dark_metal)

	## 平台/阶台
	_create_box("PlatformL", Vector3(-28, 2.0, -15), Vector3(10, 4, 8), metal.darkened(0.1))
	_create_box("PlatformR", Vector3(28, 2.0, 15), Vector3(10, 4, 8), metal.darkened(0.1))

	## 烟囱装饰
	_create_box("ChimneyA", Vector3(-22, 6.0, 22), Vector3(3, 12, 3), dark_metal)
	_create_box("ChimneyB", Vector3(22, 6.0, -22), Vector3(3, 12, 3), dark_metal)

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
		Vector3(0, 1.1, 0), Vector3(-16, 1.1, -8), Vector3(16, 1.1, 8),
		Vector3(-10, 1.1, 15), Vector3(10, 1.1, -15),
		Vector3(-28, 1.1, -15), Vector3(28, 1.1, 15),
		Vector3(0, 1.1, -28), Vector3(0, 1.1, 28)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
