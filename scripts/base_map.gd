class_name BaseMap
extends Node3D

## 所有地图的基类，提供通用建筑工具和接口
## 子类覆盖 _build_terrain() 来定义具体地形

var blue_spawns: Array[Vector3] = []
var orange_spawns: Array[Vector3] = []
var patrol_points: Array[Vector3] = []

## 子类配置：地面颜色和尺寸
var ground_color := Color(0.58, 0.43, 0.23, 1)
var sky_color := Color(0.55, 0.63, 0.75, 1)
var ambient_color := Color(0.88, 0.78, 0.62, 1)
var sun_energy := 2.0
var map_size := 86.0

func _ready() -> void:
	_build_lighting()
	_build_ground()
	_build_boundaries()
	_build_terrain()
	_build_spawn_points()
	_build_patrol_points()

func get_spawn_points(team: String) -> Array[Vector3]:
	return blue_spawns if team == "blue" else orange_spawns

func get_patrol_points() -> Array[Vector3]:
	return patrol_points

## 子类覆盖此方法以添加建筑/掩体
func _build_terrain() -> void:
	pass

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = sun_energy
	sun.rotation_degrees = Vector3(-48, 34, 0)
	add_child(sun)

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)

func _build_ground() -> void:
	_create_box("Ground", Vector3(0, -0.55, 0), Vector3(map_size, 1.0, map_size), ground_color)

func _build_boundaries() -> void:
	var hw := map_size * 0.5
	var wall_color := ground_color.darkened(0.25)
	_create_box("NorthWall", Vector3(0, 2.7, -hw), Vector3(map_size, 6.5, 2), wall_color)
	_create_box("SouthWall", Vector3(0, 2.7, hw), Vector3(map_size, 6.5, 2), wall_color)
	_create_box("WestWall", Vector3(-hw, 2.7, 0), Vector3(2, 6.5, map_size), wall_color)
	_create_box("EastWall", Vector3(hw, 2.7, 0), Vector3(2, 6.5, map_size), wall_color)

## 子类覆盖以自定义出生点
func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-32, 1.1, 34), Vector3(-27, 1.1, 34), Vector3(-22, 1.1, 34),
		Vector3(-32, 1.1, 27), Vector3(-24, 1.1, 27)
	]
	orange_spawns = [
		Vector3(32, 1.1, -34), Vector3(27, 1.1, -34), Vector3(22, 1.1, -34),
		Vector3(32, 1.1, -27), Vector3(24, 1.1, -27)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

## 子类覆盖以自定义巡逻点
func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(-30, 1.1, 18), Vector3(-22, 1.1, -20), Vector3(-8, 1.1, -10), Vector3(0, 1.1, 0),
		Vector3(8, 1.1, 10), Vector3(22, 1.1, 20), Vector3(30, 1.1, -18), Vector3(0, 1.1, 24), Vector3(0, 1.1, -24)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])

func _create_marker(marker_name: String, pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = pos
	add_child(marker)

func _create_box(box_name: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = pos
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _make_material(color)
	body.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	return mat
