class_name SnowMap
extends BaseMap

## 雪原基地：白色开阔地形，少量建筑掩体

func _ready() -> void:
	ground_color = Color(0.88, 0.92, 0.96, 1)
	sky_color = Color(0.72, 0.80, 0.92, 1)
	ambient_color = Color(0.82, 0.88, 1.0, 1)
	sun_energy = 1.8
	super._ready()

func _build_terrain() -> void:
	var concrete := Color(0.62, 0.65, 0.70, 1)
	var dark := Color(0.38, 0.40, 0.44, 1)
	var snow_wall := Color(0.78, 0.82, 0.88, 1)

	## 中央基地建筑群
	_create_box("MainBuilding", Vector3(0, 3.5, 0), Vector3(18, 7, 10), concrete)
	_create_box("SideWingL", Vector3(-14, 2.0, 0), Vector3(8, 4, 18), concrete.darkened(0.1))
	_create_box("SideWingR", Vector3(14, 2.0, 0), Vector3(8, 4, 18), concrete.darkened(0.1))

	## 雪地掩体（雪堆风格，较宽）
	var covers := [
		Vector3(-22, 1.0, -12), Vector3(22, 1.0, 12),
		Vector3(-10, 1.0, -22), Vector3(10, 1.0, 22),
		Vector3(-28, 1.0, 5), Vector3(28, 1.0, -5),
		Vector3(0, 1.0, -30), Vector3(0, 1.0, 30)
	]
	for i in range(covers.size()):
		_create_box("SnowCover%d" % i, covers[i], Vector3(8, 2.0, 3.5), snow_wall)

	## 围墙残段
	_create_box("WallFragA", Vector3(-32, 2.5, -10), Vector3(3, 5, 15), dark)
	_create_box("WallFragB", Vector3(32, 2.5, 10), Vector3(3, 5, 15), dark)
	_create_box("WallFragC", Vector3(-8, 2.5, 32), Vector3(20, 5, 3), dark)
	_create_box("WallFragD", Vector3(8, 2.5, -32), Vector3(20, 5, 3), dark)
	_add_theme_props("snow")

func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-32, 1.1, 36), Vector3(-26, 1.1, 36), Vector3(-20, 1.1, 36),
		Vector3(-32, 1.1, 30), Vector3(-24, 1.1, 30)
	]
	orange_spawns = [
		Vector3(32, 1.1, -36), Vector3(26, 1.1, -36), Vector3(20, 1.1, -36),
		Vector3(32, 1.1, -30), Vector3(24, 1.1, -30)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-14, 1.1, 0), Vector3(14, 1.1, 0),
		Vector3(-22, 1.1, -12), Vector3(22, 1.1, 12),
		Vector3(0, 1.1, -28), Vector3(0, 1.1, 28),
		Vector3(-28, 1.1, 0), Vector3(28, 1.1, 0)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
