class_name HarborMap
extends BaseMap

## 海港码头：蓝灰色，长条形集装箱/栈道布局

func _ready() -> void:
	ground_color = Color(0.22, 0.28, 0.32, 1)
	sky_color = Color(0.38, 0.56, 0.70, 1)
	ambient_color = Color(0.60, 0.75, 0.88, 1)
	sun_energy = 2.2
	super._ready()

func _build_terrain() -> void:
	var container_blue := Color(0.15, 0.32, 0.52, 1)
	var container_red := Color(0.58, 0.18, 0.12, 1)
	var container_yellow := Color(0.72, 0.62, 0.10, 1)
	var dock := Color(0.38, 0.32, 0.22, 1)
	var metal := Color(0.30, 0.32, 0.36, 1)

	## 长条码头平台
	_create_box("DockA", Vector3(-16, 0.4, 0), Vector3(6, 0.8, 70), dock)
	_create_box("DockB", Vector3(16, 0.4, 0), Vector3(6, 0.8, 70), dock)

	## 集装箱堆叠
	var cx := [-26.0, -20.0, -10.0, 0.0, 10.0, 20.0, 26.0]
	var colors := [container_blue, container_red, container_yellow, container_blue, container_red, container_yellow, container_blue]
	for i in range(cx.size()):
		_create_box("ContainerA%d" % i, Vector3(cx[i], 1.5, -8), Vector3(5, 3, 8), colors[i])
		_create_box("ContainerB%d" % i, Vector3(-cx[i], 1.5, 8), Vector3(5, 3, 8), colors[(i + 2) % colors.size()])

	## 仓库建筑
	_create_box("WarehouseA", Vector3(-28, 4.0, -20), Vector3(14, 8, 16), metal)
	_create_box("WarehouseB", Vector3(28, 4.0, 20), Vector3(14, 8, 16), metal)

	## 小木箱掩体
	var crates := [
		Vector3(0, 1.0, 0), Vector3(-8, 1.0, 14), Vector3(8, 1.0, -14),
		Vector3(-20, 1.0, 0), Vector3(20, 1.0, 0)
	]
	for i in range(crates.size()):
		_create_box("WoodCrate%d" % i, crates[i], Vector3(3.5, 2.0, 3.5), dock)

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-16, 1.1, -15), Vector3(16, 1.1, 15),
		Vector3(-26, 1.1, -8), Vector3(26, 1.1, 8),
		Vector3(0, 1.1, -25), Vector3(0, 1.1, 25),
		Vector3(-28, 1.1, 20), Vector3(28, 1.1, -20)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
