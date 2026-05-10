class_name DesertMap
extends BaseMap

## 沙漠要塞：开阔沙地，低矮掩体，中央堡垒

func _ready() -> void:
	ground_color = Color(0.78, 0.62, 0.28, 1)
	sky_color = Color(0.82, 0.74, 0.52, 1)
	ambient_color = Color(1.0, 0.88, 0.62, 1)
	sun_energy = 2.6
	super._ready()

func _build_terrain() -> void:
	var sand := Color(0.72, 0.54, 0.22, 1)
	var dark_sand := Color(0.52, 0.37, 0.14, 1)
	var stone := Color(0.58, 0.50, 0.38, 1)

	## 中央堡垒
	_create_box("FortCenter", Vector3(0, 3.0, 0), Vector3(14, 6, 14), stone)
	_create_box("FortGateN", Vector3(0, 1.5, -7), Vector3(5, 3, 2), stone.darkened(0.1))
	_create_box("FortGateS", Vector3(0, 1.5, 7), Vector3(5, 3, 2), stone.darkened(0.1))

	## 四角塔楼
	for sign_x in [-1, 1]:
		for sign_z in [-1, 1]:
			_create_box("Tower%d%d" % [sign_x, sign_z],
				Vector3(sign_x * 18, 2.5, sign_z * 18), Vector3(6, 5, 6), stone)

	## 散落掩体
	var positions := [
		Vector3(-8, 0.9, -18), Vector3(8, 0.9, -18),
		Vector3(-8, 0.9, 18), Vector3(8, 0.9, 18),
		Vector3(-20, 0.9, 0), Vector3(20, 0.9, 0),
		Vector3(-14, 0.9, -8), Vector3(14, 0.9, 8)
	]
	for i in range(positions.size()):
		_create_box("Cover%d" % i, positions[i], Vector3(5, 1.8, 2.5), dark_sand)

	## 沙丘（低矮斜坡模拟）
	for i in range(6):
		var angle := float(i) * TAU / 6.0
		var r := 28.0
		_create_box("Dune%d" % i,
			Vector3(cos(angle) * r, 0.6, sin(angle) * r), Vector3(8, 1.2, 4), sand)
	_add_theme_props("desert")

func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-30, 1.1, 32), Vector3(-25, 1.1, 32), Vector3(-20, 1.1, 32),
		Vector3(-30, 1.1, 26), Vector3(-22, 1.1, 26)
	]
	orange_spawns = [
		Vector3(30, 1.1, -32), Vector3(25, 1.1, -32), Vector3(20, 1.1, -32),
		Vector3(30, 1.1, -26), Vector3(22, 1.1, -26)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-18, 1.1, -18), Vector3(18, 1.1, 18),
		Vector3(18, 1.1, -18), Vector3(-18, 1.1, 18),
		Vector3(0, 1.1, -25), Vector3(0, 1.1, 25),
		Vector3(-25, 1.1, 0), Vector3(25, 1.1, 0)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
