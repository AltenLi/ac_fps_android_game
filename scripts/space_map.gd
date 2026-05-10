class_name SpaceMap
extends BaseMap

## 太空站：黑色地面，白色金属建筑，科幻风格

func _ready() -> void:
	ground_color = Color(0.06, 0.06, 0.08, 1)
	sky_color = Color(0.02, 0.02, 0.06, 1)
	ambient_color = Color(0.30, 0.35, 0.55, 1)
	sun_energy = 1.2
	super._ready()

func _build_terrain() -> void:
	var white_metal := Color(0.82, 0.84, 0.88, 1)
	var gray_metal := Color(0.42, 0.44, 0.50, 1)
	var glow_blue := Color(0.22, 0.55, 1.0, 1)
	var glow_green := Color(0.15, 0.88, 0.55, 1)

	## 太空站核心模块
	_create_box("CoreModule", Vector3(0, 3.0, 0), Vector3(16, 6, 16), white_metal)
	_create_box("CorridorH", Vector3(0, 2.0, 0), Vector3(60, 4, 6), gray_metal)
	_create_box("CorridorV", Vector3(0, 2.0, 0), Vector3(6, 4, 60), gray_metal)

	## 外围模块
	_create_box("ModuleN", Vector3(0, 3.0, -25), Vector3(12, 6, 10), white_metal)
	_create_box("ModuleS", Vector3(0, 3.0, 25), Vector3(12, 6, 10), white_metal)
	_create_box("ModuleW", Vector3(-25, 3.0, 0), Vector3(10, 6, 12), white_metal)
	_create_box("ModuleE", Vector3(25, 3.0, 0), Vector3(10, 6, 12), white_metal)

	## 发光指示条
	var glows := [
		[Vector3(8.2, 2.0, 0), Vector3(0.3, 4.2, 60.0), glow_blue],
		[Vector3(-8.2, 2.0, 0), Vector3(0.3, 4.2, 60.0), glow_green],
		[Vector3(0, 2.0, 8.2), Vector3(60.0, 4.2, 0.3), glow_blue],
		[Vector3(0, 2.0, -8.2), Vector3(60.0, 4.2, 0.3), glow_green],
	]
	for i in range(glows.size()):
		var g: Array = glows[i]
		_create_box("GlowStrip%d" % i, g[0], g[1], g[2])

	## 设备箱掩体
	var equipment := [
		Vector3(-12, 1.2, -10), Vector3(12, 1.2, 10),
		Vector3(-10, 1.2, 12), Vector3(10, 1.2, -12),
		Vector3(-18, 1.2, 0), Vector3(18, 1.2, 0)
	]
	for i in range(equipment.size()):
		_create_box("Equip%d" % i, equipment[i], Vector3(4, 2.4, 4), gray_metal)
	_add_theme_props("space")

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(0, 1.1, -25), Vector3(0, 1.1, 25),
		Vector3(-25, 1.1, 0), Vector3(25, 1.1, 0),
		Vector3(-12, 1.1, -10), Vector3(12, 1.1, 10),
		Vector3(0, 1.1, -35), Vector3(0, 1.1, 35)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
