class_name RuinsMap
extends BaseMap

## 古城遗迹：棕色断壁残垣，不规则废墟布局

func _ready() -> void:
	ground_color = Color(0.48, 0.38, 0.26, 1)
	sky_color = Color(0.60, 0.54, 0.44, 1)
	ambient_color = Color(0.78, 0.68, 0.50, 1)
	sun_energy = 1.9
	super._ready()

func _build_terrain() -> void:
	var stone := Color(0.52, 0.44, 0.32, 1)
	var dark_stone := Color(0.34, 0.28, 0.20, 1)
	var broken := Color(0.44, 0.36, 0.26, 1)

	## 古城中央神庙
	_create_box("TempleBase", Vector3(0, 1.5, 0), Vector3(20, 3, 20), stone)
	_create_box("TempleTop", Vector3(0, 4.5, 0), Vector3(14, 3, 14), stone.darkened(0.1))
	_create_box("TempleGateN", Vector3(0, 1.5, -10), Vector3(5, 3, 2), dark_stone)
	_create_box("TempleGateS", Vector3(0, 1.5, 10), Vector3(5, 3, 2), dark_stone)

	## 断裂城墙
	var walls := [
		Vector3(-20, 3.0, -10), Vector3(-20, 3.0, 8), Vector3(20, 3.0, 10), Vector3(20, 3.0, -8),
		Vector3(-8, 3.0, -22), Vector3(8, 3.0, -22), Vector3(-8, 3.0, 22), Vector3(8, 3.0, 22)
	]
	var wall_sizes := [
		Vector3(3, 6, 14), Vector3(3, 4, 10), Vector3(3, 6, 14), Vector3(3, 4, 10),
		Vector3(10, 6, 3), Vector3(10, 4, 3), Vector3(10, 6, 3), Vector3(10, 4, 3)
	]
	for i in range(walls.size()):
		_create_box("RuinWall%d" % i, walls[i], wall_sizes[i], broken if i % 2 == 0 else dark_stone)

	## 散落石块
	var rubble_pos := [
		Vector3(-12, 0.8, 6), Vector3(12, 0.8, -6), Vector3(-6, 0.8, -16),
		Vector3(6, 0.8, 16), Vector3(-26, 0.8, 0), Vector3(26, 0.8, 0)
	]
	for i in range(rubble_pos.size()):
		_create_box("Rubble%d" % i, rubble_pos[i], Vector3(4, 1.6, 3), dark_stone)
	_add_theme_props("ruins")

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 4.5, 0), Vector3(-20, 1.1, -10), Vector3(20, 1.1, 10),
		Vector3(-8, 1.1, -22), Vector3(8, 1.1, 22),
		Vector3(-28, 1.1, 0), Vector3(28, 1.1, 0),
		Vector3(0, 1.1, -30), Vector3(0, 1.1, 30)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
