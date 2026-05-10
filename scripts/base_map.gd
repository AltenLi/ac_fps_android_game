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
	_create_box("Ground", Vector3(0, -0.55, 0), Vector3(map_size, 1.0, map_size), ground_color, Vector3.ZERO, "ground")

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

func _create_box(box_name: String, pos: Vector3, size: Vector3, color: Color, rotation_deg: Vector3 = Vector3.ZERO, material_kind: String = "", collision_enabled: bool = true, emission: Color = Color(0, 0, 0, 0)) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = pos
	body.rotation_degrees = rotation_deg
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _make_material(color, material_kind, emission)
	body.add_child(mesh)

	if collision_enabled:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return body

func _create_cylinder(cylinder_name: String, pos: Vector3, radius: float, height: float, color: Color, rotation_deg: Vector3 = Vector3.ZERO, material_kind: String = "", collision_enabled: bool = false, emission: Color = Color(0, 0, 0, 0)) -> Node3D:
	return _create_tapered_cylinder(cylinder_name, pos, radius, radius, height, color, rotation_deg, material_kind, collision_enabled, emission)

func _create_tapered_cylinder(cylinder_name: String, pos: Vector3, bottom_radius: float, top_radius: float, height: float, color: Color, rotation_deg: Vector3 = Vector3.ZERO, material_kind: String = "", collision_enabled: bool = false, emission: Color = Color(0, 0, 0, 0)) -> Node3D:
	var body := StaticBody3D.new()
	body.name = cylinder_name
	body.position = pos
	body.rotation_degrees = rotation_deg
	add_child(body)

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top_radius
	cylinder.bottom_radius = bottom_radius
	cylinder.height = height
	cylinder.radial_segments = 32
	mesh.mesh = cylinder
	mesh.material_override = _make_material(color, material_kind, emission)
	body.add_child(mesh)

	if collision_enabled:
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = maxf(bottom_radius, top_radius)
		shape.height = height
		collision.shape = shape
		body.add_child(collision)
	return body

func _create_sphere(sphere_name: String, pos: Vector3, scale: Vector3, color: Color, material_kind: String = "", collision_enabled: bool = false, emission: Color = Color(0, 0, 0, 0)) -> Node3D:
	var body := StaticBody3D.new()
	body.name = sphere_name
	body.position = pos
	add_child(body)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	mesh.scale = scale
	mesh.material_override = _make_material(color, material_kind, emission)
	body.add_child(mesh)

	if collision_enabled:
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = maxf(scale.x, maxf(scale.y, scale.z))
		collision.shape = shape
		body.add_child(collision)
	return body

func _create_neon_tube(tube_name: String, pos: Vector3, length: float, radius: float, color: Color, rotation_deg: Vector3 = Vector3.ZERO) -> Node3D:
	return _create_cylinder(tube_name, pos, radius, length, color, rotation_deg, "neon", false, Color(color.r, color.g, color.b, 0.9))

func _create_rock(rock_name: String, pos: Vector3, scale: Vector3, color: Color, material_kind: String = "stone", collision_enabled: bool = false) -> Node3D:
	var body := StaticBody3D.new()
	body.name = rock_name
	body.position = pos
	add_child(body)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.45
	sphere.radial_segments = 18
	sphere.rings = 9
	mesh.mesh = sphere
	mesh.scale = scale
	mesh.rotation_degrees = Vector3(randf_range(-8.0, 8.0), randf_range(0.0, 180.0), randf_range(-8.0, 8.0))
	mesh.material_override = _make_material(color, material_kind)
	body.add_child(mesh)

	if collision_enabled:
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = maxf(scale.x, maxf(scale.y, scale.z))
		collision.shape = shape
		body.add_child(collision)
	return body

func _create_light(light_name: String, pos: Vector3, color: Color, energy: float = 1.2, radius: float = 8.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	add_child(light)
	return light

func _create_trash_bin(bin_name: String, pos: Vector3, rotation_y: float = 0.0, body_color: Color = Color(0.08, 0.10, 0.10, 1), accent_color: Color = Color(0.18, 0.22, 0.22, 1)) -> void:
	_create_cylinder("%sBody" % bin_name, pos + Vector3(0, 0.55, 0), 0.42, 0.95, body_color, Vector3(0, rotation_y, 0), "metal", true)
	_create_cylinder("%sLid" % bin_name, pos + Vector3(0, 1.08, 0), 0.48, 0.12, accent_color, Vector3(0, rotation_y, 0), "metal", false)
	_create_cylinder("%sRim" % bin_name, pos + Vector3(0, 1.17, 0), 0.50, 0.055, accent_color.lightened(0.08), Vector3(0, rotation_y, 0), "metal", false)
	_create_box("%sFrontLabel" % bin_name, pos + Vector3(0, 0.72, -0.43), Vector3(0.36, 0.20, 0.035), Color(0.72, 0.80, 0.72, 1), Vector3(0, rotation_y, 0), "paint", false)
	_create_box("%sSideHandleL" % bin_name, pos + Vector3(-0.48, 0.82, 0), Vector3(0.08, 0.30, 0.30), accent_color, Vector3(0, rotation_y, 0), "metal", false)
	_create_box("%sSideHandleR" % bin_name, pos + Vector3(0.48, 0.82, 0), Vector3(0.08, 0.30, 0.30), accent_color, Vector3(0, rotation_y, 0), "metal", false)
	_create_rock("%sTrashBag" % bin_name, pos + Vector3(0.62, 0.28, 0.22), Vector3(0.36, 0.30, 0.32), Color(0.025, 0.026, 0.028, 1), "matte", false)

func _create_lamp_post(lamp_name: String, pos: Vector3, light_color: Color = Color(1.0, 0.78, 0.45, 1), pole_color: Color = Color(0.06, 0.065, 0.07, 1), height: float = 4.4, energy: float = 0.55, radius: float = 8.0) -> void:
	_create_cylinder("%sPole" % lamp_name, pos + Vector3(0, height * 0.5, 0), 0.09, height, pole_color, Vector3.ZERO, "metal", false)
	_create_cylinder("%sBase" % lamp_name, pos + Vector3(0, 0.16, 0), 0.28, 0.32, pole_color.lightened(0.06), Vector3.ZERO, "metal", false)
	_create_cylinder("%sArm" % lamp_name, pos + Vector3(0.48, height - 0.28, 0), 0.045, 0.96, pole_color.lightened(0.08), Vector3(0, 0, 90), "metal", false)
	_create_box("%sLampHead" % lamp_name, pos + Vector3(1.03, height - 0.28, 0), Vector3(0.44, 0.22, 0.32), pole_color.lightened(0.12), Vector3.ZERO, "metal", false)
	_create_sphere("%sGlassGlow" % lamp_name, pos + Vector3(1.03, height - 0.44, 0), Vector3(0.18, 0.10, 0.18), light_color, "screen", false, Color(light_color.r, light_color.g, light_color.b, 0.72))
	_create_light("%sOmni" % lamp_name, pos + Vector3(1.03, height - 0.45, 0), light_color, energy, radius)

func _make_material(color: Color, material_kind: String = "", emission: Color = Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var kind := material_kind if material_kind != "" else _infer_material_kind(color)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = _make_procedural_texture(color, kind)
	mat.roughness = 0.72
	mat.metallic = 0.0
	match kind:
		"asphalt":
			mat.roughness = 0.9
		"concrete":
			mat.roughness = 0.82
		"paint":
			mat.roughness = 0.56
		"metal", "container", "sci_fi":
			mat.metallic = 0.35
			mat.roughness = 0.45
		"glass":
			mat.metallic = 0.12
			mat.roughness = 0.18
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var glass_color := mat.albedo_color
			glass_color.a = minf(glass_color.a, 0.82)
			mat.albedo_color = glass_color
		"ice", "snow":
			mat.roughness = 0.34
		"water":
			mat.roughness = 0.18
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var water_color := mat.albedo_color
			water_color.a = 0.72
			mat.albedo_color = water_color
		"neon", "lava", "screen", "energy":
			mat.roughness = 0.28
		"hologram":
			mat.roughness = 0.18
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var holo_color := mat.albedo_color
			holo_color.a = minf(holo_color.a, 0.64)
			mat.albedo_color = holo_color
	if emission.a > 0.0 or kind in ["neon", "lava", "screen", "energy", "hologram"]:
		var emit := Color(emission.r, emission.g, emission.b, 1.0) if emission.a > 0.0 else color
		mat.emission_enabled = true
		mat.emission = emit
		mat.emission_energy_multiplier = 1.6 + maxf(emission.a, 0.7) * 2.4
	return mat

func _infer_material_kind(color: Color) -> String:
	var max_c := maxf(color.r, maxf(color.g, color.b))
	var min_c := minf(color.r, minf(color.g, color.b))
	if max_c > 0.78 and max_c - min_c > 0.42:
		return "neon"
	if color.r > 0.62 and color.g > 0.22 and color.b < 0.18:
		return "lava"
	if max_c - min_c < 0.12 and max_c < 0.58:
		return "metal"
	return "matte"

func _make_procedural_texture(color: Color, material_kind: String) -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var seed_value: float = sin(float(x) * 12.9898 + float(y) * 78.233 + color.r * 37.7 + color.g * 19.1 + color.b * 73.3) * 43758.5453
			var n: float = seed_value - floor(seed_value)
			var grain: float = (n - 0.5) * 0.16
			match material_kind:
				"ground":
					grain += (0.10 if ((x + y) % 9) < 2 else -0.02)
				"asphalt":
					grain += (0.18 if (x * 3 + y * 5) % 17 < 3 else -0.05)
					grain += (0.10 if abs(x - y) % 19 == 0 else 0.0)
				"concrete":
					grain += (0.10 if x % 8 == 0 or y % 8 == 0 else -0.015)
				"paint":
					grain += (0.06 if (x + y) % 6 < 2 else -0.04)
				"stone":
					grain += (0.14 if abs(x - y) % 11 < 2 else -0.03)
				"wood", "bark":
					grain += (0.16 if x % 7 < 2 else -0.04)
				"metal", "container", "sci_fi":
					grain += (0.12 if x % 10 == 0 or y % 10 == 0 else -0.02)
				"glass":
					grain += (0.08 if x % 12 == 0 or y % 12 == 0 else -0.03)
				"snow", "ice":
					grain += (0.08 if (x + y * 2) % 13 < 3 else 0.0)
				"neon", "lava", "screen", "energy", "hologram":
					grain += (0.18 if x % 6 < 2 else 0.04)
					grain += (0.09 if y % 9 == 0 else 0.0)
			var factor := clampf(1.0 + grain, 0.58, 1.36)
			var pixel := Color(clampf(color.r * factor, 0.0, 1.0), clampf(color.g * factor, 0.0, 1.0), clampf(color.b * factor, 0.0, 1.0), color.a)
			image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)

func _add_theme_props(theme: String) -> void:
	match theme:
		"city":
			_create_box("CityRoadAsphalt", Vector3(0, 0.03, 0), Vector3(7.5, 0.08, 74), Color(0.07, 0.07, 0.075, 1), Vector3.ZERO, "asphalt", false)
			for i in range(8):
				var z := -28.0 + i * 8.0
				_create_box("CityLaneDash%d" % i, Vector3(0, 0.12, z), Vector3(0.28, 0.06, 3.8), Color(0.94, 0.78, 0.28, 1), Vector3.ZERO, "paint", false)
			for i in range(6):
				var y := 3.0 + float(i % 3) * 1.2
				_create_box("CityWindowL%d" % i, Vector3(-28.05, y, -18 + i * 6), Vector3(0.08, 0.65, 1.6), Color(0.95, 0.72, 0.28, 1), Vector3.ZERO, "screen", false, Color(0.95, 0.55, 0.16, 0.55))
			for i in range(3):
				var z := -22.0 + float(i) * 22.0
				_create_lamp_post("CityLampPost%d" % i, Vector3(-9.5, 0.12, z), Color(1.0, 0.74, 0.42, 1), Color(0.07, 0.075, 0.08, 1), 4.2, 0.42, 7.0)
				_create_trash_bin("CityTrashBin%d" % i, Vector3(9.8, 0.12, z + 4.0), 0.0, Color(0.06, 0.18, 0.14, 1), Color(0.16, 0.30, 0.24, 1))
		"desert":
			for i in range(10):
				var angle := float(i) * TAU / 10.0
				_create_box("WindSandRidge%d" % i, Vector3(cos(angle) * 30.0, 0.08, sin(angle) * 30.0), Vector3(11, 0.14, 1.4), Color(0.88, 0.70, 0.34, 1), Vector3(0, rad_to_deg(-angle), 0), "ground", false)
			for x in [-24.0, 24.0]:
				_create_cylinder("DesertPalmTrunk%s" % x, Vector3(x, 2.4, -22), 0.45, 4.8, Color(0.42, 0.25, 0.11, 1), Vector3.ZERO, "bark", false)
				_create_box("DesertPalmCrown%s" % x, Vector3(x, 5.0, -22), Vector3(4.8, 0.45, 1.2), Color(0.16, 0.38, 0.13, 1), Vector3(0, 32, 0), "matte", false)
		"snow":
			for i in range(9):
				_create_rock("SnowDrift%d" % i, Vector3(-32 + i * 8, 0.55, 31.5 * (1 if i % 2 == 0 else -1)), Vector3(2.6, 0.55, 1.0), Color(0.95, 0.98, 1.0, 1), "snow", false)
			for x in [-18.0, 18.0]:
				_create_box("BlueIcePane%s" % x, Vector3(x, 0.08, 0), Vector3(7.0, 0.12, 5.0), Color(0.62, 0.86, 1.0, 0.72), Vector3.ZERO, "ice", false)
		"factory":
			for x in [-28.0, 28.0]:
				_create_cylinder("FactoryTank%s" % x, Vector3(x, 2.2, 0), 2.2, 4.4, Color(0.25, 0.27, 0.27, 1), Vector3(90, 0, 0), "metal", false)
			for i in range(5):
				_create_cylinder("PipeRun%d" % i, Vector3(-18 + i * 9, 4.6, -30), 0.26, 8.0, Color(0.54, 0.32, 0.14, 1), Vector3(0, 0, 90), "metal", false)
			for i in range(3):
				var x := -22.0 + float(i) * 22.0
				_create_lamp_post("FactoryWorkLamp%d" % i, Vector3(x, 0.10, 25.5), Color(1.0, 0.78, 0.45, 1), Color(0.12, 0.12, 0.11, 1), 4.8, 0.50, 8.5)
				_create_trash_bin("FactoryWasteBin%d" % i, Vector3(x + 4.2, 0.10, -25.5), 0.0, Color(0.16, 0.15, 0.13, 1), Color(0.42, 0.28, 0.12, 1))
		"jungle":
			for i in range(12):
				var angle := float(i) * TAU / 12.0
				var pos := Vector3(cos(angle) * 34.0, 2.6, sin(angle) * 34.0)
				_create_cylinder("RoundTree%d" % i, pos, 0.55, 5.2, Color(0.28, 0.16, 0.08, 1), Vector3.ZERO, "bark", false)
				_create_rock("Canopy%d" % i, pos + Vector3(0, 3.2, 0), Vector3(2.2, 1.0, 2.2), Color(0.10, 0.32, 0.08, 1), "matte", false)
		"ruins":
			for i in range(10):
				var angle := float(i) * TAU / 10.0
				_create_cylinder("BrokenColumn%d" % i, Vector3(cos(angle) * 24, 1.6, sin(angle) * 24), 0.7, randf_range(2.2, 4.2), Color(0.48, 0.41, 0.30, 1), Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), "stone", false)
		"harbor":
			_create_box("HarborWaterPlane", Vector3(0, -0.05, 0), Vector3(82, 0.08, 82), Color(0.06, 0.22, 0.34, 0.72), Vector3.ZERO, "water", false)
			for z in [-28.0, 28.0]:
				for x in [-34.0, 34.0]:
					_create_cylinder("DockBollard%d_%d" % [int(x), int(z)], Vector3(x, 0.85, z), 0.45, 1.7, Color(0.08, 0.09, 0.10, 1), Vector3.ZERO, "metal", false)
			for i in range(3):
				var x := -24.0 + float(i) * 24.0
				_create_lamp_post("HarborLampPost%d" % i, Vector3(x, 0.12, -31.0), Color(0.78, 0.92, 1.0, 1), Color(0.08, 0.10, 0.11, 1), 4.6, 0.48, 8.0)
				_create_trash_bin("HarborTrashBin%d" % i, Vector3(x + 5.0, 0.12, 31.0), 0.0, Color(0.05, 0.14, 0.18, 1), Color(0.16, 0.26, 0.30, 1))
		"night_city":
			for i in range(8):
				var x := -32.0 + i * 9.0
				var color := Color(0.10, 0.78, 0.95, 1) if i % 2 == 0 else Color(0.95, 0.12, 0.58, 1)
				_create_box("NeonStreetLine%d" % i, Vector3(x, 0.15, 32), Vector3(5.0, 0.12, 0.3), color, Vector3.ZERO, "neon", false, Color(color.r, color.g, color.b, 0.8))
				_create_light("NeonStreetLight%d" % i, Vector3(x, 3.2, 30), color, 0.55, 7.0)
			for i in range(4):
				var z := -27.0 + float(i) * 18.0
				var lamp_color := Color(0.12, 0.85, 1.0, 1) if i % 2 == 0 else Color(1.0, 0.18, 0.62, 1)
				_create_lamp_post("NightThemeLampPost%d" % i, Vector3(-14.5 if i % 2 == 0 else 14.5, 0.13, z), lamp_color, Color(0.025, 0.028, 0.035, 1), 4.7, 0.45, 8.0)
				_create_trash_bin("NightThemeTrashBin%d" % i, Vector3(14.0 if i % 2 == 0 else -14.0, 0.13, z + 6.0), 0.0, Color(0.035, 0.045, 0.055, 1), lamp_color.darkened(0.45))
		"cave":
			for i in range(12):
				var angle := float(i) * TAU / 12.0
				_create_rock("CaveJaggedRock%d" % i, Vector3(cos(angle) * 28, 1.0, sin(angle) * 28), Vector3(1.4, randf_range(0.8, 1.8), 1.2), Color(0.30, 0.23, 0.16, 1), "stone", false)
			for pos in [Vector3(-16, 3.5, -18), Vector3(16, 3.5, 18), Vector3(0, 3.2, 26)]:
				_create_light("CaveWarmLamp%d" % get_child_count(), pos, Color(1.0, 0.58, 0.22, 1), 0.75, 8.0)
		"space":
			for i in range(6):
				var z := -30.0 + i * 12.0
				_create_box("SpaceFloorPanel%d" % i, Vector3(0, 0.08, z), Vector3(28, 0.08, 0.35), Color(0.22, 0.55, 1.0, 1), Vector3.ZERO, "energy", false, Color(0.2, 0.55, 1.0, 0.7))
			_create_light("CoreBlueGlow", Vector3(0, 5.2, 0), Color(0.25, 0.55, 1.0, 1), 1.1, 12.0)
		"volcano":
			for i in range(8):
				var angle := float(i) * TAU / 8.0
				var pos := Vector3(cos(angle) * 19.0, 0.18, sin(angle) * 19.0)
				_create_box("LavaCrack%d" % i, pos, Vector3(7.5, 0.12, 0.45), Color(1.0, 0.32, 0.04, 1), Vector3(0, rad_to_deg(-angle), 0), "lava", false, Color(1.0, 0.24, 0.02, 0.85))
			_create_light("CraterGlow", Vector3(0, 6.5, 0), Color(1.0, 0.28, 0.05, 1), 1.35, 16.0)
