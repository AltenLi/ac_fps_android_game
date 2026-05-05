extends Node3D

var blue_spawns: Array[Vector3] = []
var orange_spawns: Array[Vector3] = []
var patrol_points: Array[Vector3] = []

func _ready() -> void:
	_build_lighting()
	_build_ground()
	_build_boundaries()
	_build_city_blocks()
	_build_spawn_points()
	_build_patrol_points()

func get_spawn_points(team: String) -> Array[Vector3]:
	return blue_spawns if team == "blue" else orange_spawns

func get_patrol_points() -> Array[Vector3]:
	return patrol_points

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 2.0
	sun.rotation_degrees = Vector3(-48, 34, 0)
	add_child(sun)

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.63, 0.75, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.88, 0.78, 0.62, 1)
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)

func _build_ground() -> void:
	_create_box("SandGround", Vector3(0, -0.55, 0), Vector3(86, 1, 86), Color(0.58, 0.43, 0.23, 1))

func _build_boundaries() -> void:
	_create_box("NorthWall", Vector3(0, 2.7, -43), Vector3(86, 6.5, 2), Color(0.48, 0.36, 0.2, 1))
	_create_box("SouthWall", Vector3(0, 2.7, 43), Vector3(86, 6.5, 2), Color(0.48, 0.36, 0.2, 1))
	_create_box("WestWall", Vector3(-43, 2.7, 0), Vector3(2, 6.5, 86), Color(0.48, 0.36, 0.2, 1))
	_create_box("EastWall", Vector3(43, 2.7, 0), Vector3(2, 6.5, 86), Color(0.48, 0.36, 0.2, 1))

func _build_city_blocks() -> void:
	# 原创低模巷战布局：双出生点、中路、侧巷、平台和掩体，避免复制 dust2 具体路线。
	var wall := Color(0.64, 0.49, 0.27, 1)
	var dark_wall := Color(0.42, 0.31, 0.18, 1)
	var cover := Color(0.33, 0.26, 0.19, 1)
	var accent := Color(0.76, 0.58, 0.32, 1)

	_create_box("BlueSpawnBlock", Vector3(-28, 2.0, 29), Vector3(15, 4, 8), wall)
	_create_box("OrangeSpawnBlock", Vector3(28, 2.0, -29), Vector3(15, 4, 8), wall)

	_create_box("MidGateLeft", Vector3(-5.8, 2.5, 0), Vector3(4, 5, 12), dark_wall)
	_create_box("MidGateRight", Vector3(5.8, 2.5, 0), Vector3(4, 5, 12), dark_wall)
	_create_box("MidGateTop", Vector3(0, 6.0, 0), Vector3(15, 2, 12), dark_wall)

	_create_box("LongA_WallA", Vector3(-25, 2.2, -12), Vector3(5, 4.4, 34), wall)
	_create_box("LongA_WallB", Vector3(-12, 2.2, -25), Vector3(24, 4.4, 5), wall)
	_create_box("LongA_Corner", Vector3(-30, 2.2, -30), Vector3(12, 4.4, 10), dark_wall)

	_create_box("SideAlley_WallA", Vector3(25, 2.2, 12), Vector3(5, 4.4, 34), wall)
	_create_box("SideAlley_WallB", Vector3(12, 2.2, 25), Vector3(24, 4.4, 5), wall)
	_create_box("SideAlley_Corner", Vector3(30, 2.2, 30), Vector3(12, 4.4, 10), dark_wall)

	_create_box("CentralCoverA", Vector3(-12, 0.9, 8), Vector3(7, 1.8, 3), cover)
	_create_box("CentralCoverB", Vector3(12, 0.9, -8), Vector3(7, 1.8, 3), cover)
	_create_box("CrateStackA", Vector3(-2, 1.2, 16), Vector3(4, 2.4, 4), cover)
	_create_box("CrateStackB", Vector3(2, 1.2, -16), Vector3(4, 2.4, 4), cover)
	_create_box("MarketCover", Vector3(17, 0.9, 7), Vector3(9, 1.8, 3), cover)
	_create_box("TunnelCover", Vector3(-17, 0.9, -7), Vector3(9, 1.8, 3), cover)

	_create_box("BluePlatform", Vector3(-30, 1.3, 16), Vector3(12, 2.6, 9), accent)
	_create_box("OrangePlatform", Vector3(30, 1.3, -16), Vector3(12, 2.6, 9), accent)
	_create_box("BlueRamp", Vector3(-23, 0.45, 18), Vector3(7, 0.9, 5), Color(0.5, 0.37, 0.22, 1))
	_create_box("OrangeRamp", Vector3(23, 0.45, -18), Vector3(7, 0.9, 5), Color(0.5, 0.37, 0.22, 1))

	for i in range(8):
		var z := -28.0 + float(i) * 8.0
		_create_box("SmallCoverLeft%d" % i, Vector3(-34, 0.75, z), Vector3(4, 1.5, 3), cover)
		_create_box("SmallCoverRight%d" % i, Vector3(34, 0.75, -z), Vector3(4, 1.5, 3), cover)

func _build_spawn_points() -> void:
	blue_spawns = [
		Vector3(-32, 1.1, 34), Vector3(-27, 1.1, 34), Vector3(-22, 1.1, 34), Vector3(-32, 1.1, 27), Vector3(-24, 1.1, 27)
	]
	orange_spawns = [
		Vector3(32, 1.1, -34), Vector3(27, 1.1, -34), Vector3(22, 1.1, -34), Vector3(32, 1.1, -27), Vector3(24, 1.1, -27)
	]
	for i in range(blue_spawns.size()):
		_create_marker("BlueSpawn%d" % i, blue_spawns[i])
	for i in range(orange_spawns.size()):
		_create_marker("OrangeSpawn%d" % i, orange_spawns[i])

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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
