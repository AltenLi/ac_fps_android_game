class_name LaserTower
extends StaticBody3D

const LASER_TARGET_COUNT := 3
const LASER_DAMAGE := 9999.0
const LASER_VISUAL_SECONDS := 0.34
const TRIGGER_RADIUS := 24.0

var team := "blue"
var match_manager: MatchManager
var health: Health
var fired := false

func _physics_process(_delta: float) -> void:
	if fired or match_manager == null or health == null or not health.is_alive:
		return
	for enemy in _collect_living_enemies():
		if global_position.distance_to(enemy.global_position) <= TRIGGER_RADIUS:
			fire_once()
			return

func setup(manager: MatchManager, owner_team: String) -> void:
	match_manager = manager
	team = owner_team
	set_meta("team", team)
	_build_body()

func get_health() -> Health:
	return health

func fire_once() -> void:
	if match_manager == null or fired:
		return
	fired = true
	var enemies := _collect_living_enemies()
	enemies.shuffle()
	var count := mini(LASER_TARGET_COUNT, enemies.size())
	for i in range(count):
		var target := enemies[i]
		_fire_laser_at(target)

func _collect_living_enemies() -> Array[Node3D]:
	var enemies: Array[Node3D] = []
	for unit in match_manager.combatants:
		if unit == null or not is_instance_valid(unit) or unit == self:
			continue
		if str(unit.get_meta("team", "")) == team:
			continue
		var unit_health := match_manager._get_health(unit)
		if unit_health != null and unit_health.is_alive:
			enemies.append(unit)
	return enemies

func _fire_laser_at(target: Node3D) -> void:
	var unit_health := match_manager._get_health(target)
	if unit_health == null or not unit_health.is_alive:
		return
	var start := global_position + Vector3(0, 2.8, 0)
	var end := target.global_position + Vector3(0, 1.2, 0)
	_spawn_laser_visual(start, end)
	unit_health.apply_damage(LASER_DAMAGE, self, "laser_tower")

func _build_body() -> void:
	name = "LaserTower"
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.62
	shape.height = 3.2
	collision.shape = shape
	collision.position.y = 1.6
	add_child(collision)

	var base := _mesh_cylinder("Base", 0.82, 0.35, Vector3(0, 0.18, 0), Color(0.06, 0.07, 0.08, 1))
	add_child(base)
	var mast := _mesh_cylinder("Mast", 0.22, 2.35, Vector3(0, 1.35, 0), Color(0.10, 0.12, 0.14, 1))
	add_child(mast)
	var core := _mesh_box("LaserCore", Vector3(0.9, 0.48, 0.9), Vector3(0, 2.62, 0), Color(0.14, 0.72, 1.0, 1), true)
	add_child(core)

	health = Health.new()
	health.name = "Health"
	health.reset(team, 180.0)
	health.died.connect(func(_killer: Node, _weapon_id: String) -> void:
		queue_free()
	)
	add_child(health)

func _mesh_cylinder(mesh_name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var inst := MeshInstance3D.new()
	inst.name = mesh_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _material(color, false)
	return inst

func _mesh_box(mesh_name: String, size: Vector3, pos: Vector3, color: Color, glow: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.name = mesh_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _material(color, glow)
	return inst

func _material(color: Color, glow: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.28
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.2
	return mat

func _spawn_laser_visual(start: Vector3, end: Vector3) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.72, 1.0, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.18, 0.8, 1.0, 1)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var line := MeshInstance3D.new()
	line.mesh = mesh
	line.material_override = mat
	get_tree().current_scene.add_child(line)
	get_tree().create_timer(LASER_VISUAL_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)
