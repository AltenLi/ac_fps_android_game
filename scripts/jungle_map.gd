class_name JungleMap
extends BaseMap

## 丛林营地：绿色地面，树桩/植被掩体，弯曲通道

func _ready() -> void:
	ground_color = Color(0.22, 0.40, 0.16, 1)
	sky_color = Color(0.38, 0.56, 0.30, 1)
	ambient_color = Color(0.55, 0.72, 0.38, 1)
	sun_energy = 1.6
	super._ready()

func _build_terrain() -> void:
	var bark := Color(0.35, 0.22, 0.10, 1)
	var dark_green := Color(0.16, 0.30, 0.10, 1)
	var mud := Color(0.28, 0.20, 0.10, 1)
	var stone := Color(0.40, 0.38, 0.28, 1)

	## 粗壮树桩柱
	var trunks := [
		Vector3(-10, 2.5, -12), Vector3(-18, 2.5, 4), Vector3(-6, 2.5, 18),
		Vector3(10, 2.5, 12), Vector3(18, 2.5, -4), Vector3(6, 2.5, -18),
		Vector3(-26, 2.5, -20), Vector3(26, 2.5, 20)
	]
	for i in range(trunks.size()):
		_create_box("Trunk%d" % i, trunks[i], Vector3(3.5, 5.0, 3.5), bark)

	## 营地建筑（木屋/石墙）
	_create_box("CampHutA", Vector3(-22, 2.0, 16), Vector3(12, 4, 8), mud)
	_create_box("CampHutB", Vector3(22, 2.0, -16), Vector3(12, 4, 8), mud)

	## 植被堆掩体
	var bushes := [
		Vector3(0, 1.0, 0), Vector3(-12, 1.0, 6), Vector3(12, 1.0, -6),
		Vector3(0, 1.0, 20), Vector3(0, 1.0, -20),
		Vector3(-20, 1.0, -6), Vector3(20, 1.0, 6)
	]
	for i in range(bushes.size()):
		_create_box("Bush%d" % i, bushes[i], Vector3(5, 2.0, 4), dark_green)

	## 石头掩体
	_create_box("RockA", Vector3(-30, 1.2, 0), Vector3(5, 2.4, 7), stone)
	_create_box("RockB", Vector3(30, 1.2, 0), Vector3(5, 2.4, 7), stone)
	_create_box("RockC", Vector3(0, 1.2, 30), Vector3(7, 2.4, 5), stone)
	_create_box("RockD", Vector3(0, 1.2, -30), Vector3(7, 2.4, 5), stone)

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-18, 1.1, 4), Vector3(18, 1.1, -4),
		Vector3(-10, 1.1, -12), Vector3(10, 1.1, 12),
		Vector3(-22, 1.1, -20), Vector3(22, 1.1, 20),
		Vector3(0, 1.1, -25), Vector3(0, 1.1, 25)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
