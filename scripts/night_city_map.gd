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
	var dark_building := Color(0.12, 0.10, 0.16, 1)
	var darker := Color(0.08, 0.07, 0.10, 1)

	## 高楼建筑群
	_create_box("TowerA", Vector3(-22, 8.0, -14), Vector3(12, 16, 10), dark_building)
	_create_box("TowerB", Vector3(22, 8.0, 14), Vector3(12, 16, 10), dark_building)
	_create_box("TowerC", Vector3(-10, 5.0, 14), Vector3(8, 10, 12), darker)
	_create_box("TowerD", Vector3(10, 5.0, -14), Vector3(8, 10, 12), darker)

	## 霓虹灯管装饰（细长盒子，亮色）
	var neons := [
		[Vector3(-22, 16.2, -14), Vector3(12.5, 0.4, 10.5), neon_purple],
		[Vector3(22, 16.2, 14), Vector3(12.5, 0.4, 10.5), neon_cyan],
		[Vector3(-10, 10.2, 14), Vector3(8.5, 0.4, 12.5), neon_pink],
		[Vector3(10, 10.2, -14), Vector3(8.5, 0.4, 12.5), neon_purple],
	]
	for i in range(neons.size()):
		var n: Array = neons[i]
		_create_box("Neon%d" % i, n[0], n[1], n[2])

	## 地面掩体（低矮霓虹边框）
	var covers := [
		[Vector3(0, 0.9, 0), Vector3(6, 1.8, 3), neon_cyan],
		[Vector3(-12, 0.9, 8), Vector3(5, 1.8, 3), neon_purple],
		[Vector3(12, 0.9, -8), Vector3(5, 1.8, 3), neon_pink],
		[Vector3(-8, 0.9, -18), Vector3(5, 1.8, 3), neon_cyan],
		[Vector3(8, 0.9, 18), Vector3(5, 1.8, 3), neon_purple],
		[Vector3(-28, 0.9, 0), Vector3(3, 1.8, 6), neon_pink],
		[Vector3(28, 0.9, 0), Vector3(3, 1.8, 6), neon_cyan],
	]
	for i in range(covers.size()):
		var c: Array = covers[i]
		_create_box("Cover%d" % i, c[0], c[1], c[2])

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-22, 1.1, -14), Vector3(22, 1.1, 14),
		Vector3(-10, 1.1, 14), Vector3(10, 1.1, -14),
		Vector3(-28, 1.1, 0), Vector3(28, 1.1, 0),
		Vector3(0, 1.1, -28), Vector3(0, 1.1, 28)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
