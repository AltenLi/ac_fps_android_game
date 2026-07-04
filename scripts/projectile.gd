extends Node3D

var direction := Vector3.FORWARD
var shooter: Node3D = null
var enemy_team := "orange"
var damage := 80.0
var splash_radius := 5.0
var speed := 30.0
var max_range := 100.0
var traveled := 0.0
var exploded := false
var use_arc := false
var velocity := Vector3.ZERO
const SELF_GRENADE_LAUNCH_HEIGHT := 10.8

func setup(new_direction: Vector3, new_shooter: Node3D, new_enemy_team: String, new_damage: float, new_radius: float, new_speed: float, new_range: float) -> void:
	direction = new_direction.normalized()
	shooter = new_shooter
	enemy_team = new_enemy_team
	damage = new_damage
	splash_radius = new_radius
	speed = new_speed
	max_range = new_range
	look_at(global_position + direction, Vector3.UP)

func setup_arc(new_direction: Vector3, new_shooter: Node3D, new_enemy_team: String, new_damage: float, new_radius: float, new_speed: float, new_range: float, arc_lift: float = 8.0) -> void:
	setup(new_direction, new_shooter, new_enemy_team, new_damage, new_radius, new_speed, new_range)
	use_arc = true
	velocity = direction * speed + Vector3.UP * arc_lift

func _ready() -> void:
	_build_visual()

func _physics_process(delta: float) -> void:
	if exploded:
		return
	if use_arc:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
		_move_with_step(velocity * delta)
		return
	var step := speed * delta
	_move_with_step(direction * step)

func _move_with_step(step_vec: Vector3) -> void:
	var from := global_position
	var to := from + step_vec
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	if shooter is CollisionObject3D:
		query.exclude = [(shooter as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.get("position")
		_explode()
		return
	global_position = to
	traveled += step_vec.length()
	if traveled >= max_range:
		_explode()

func _explode() -> void:
	if exploded:
		return
	exploded = true
	var space := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = splash_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = Transform3D(Basis(), global_position)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	if shooter is CollisionObject3D:
		params.exclude = [(shooter as CollisionObject3D).get_rid()]
	var results := space.intersect_shape(params, 32)
	_apply_self_grenade_knockback()
	for result in results:
		var health := _find_health(result.get("collider"))
		if health != null and health.team == enemy_team:
			var dist := global_position.distance_to((health.get_parent() as Node3D).global_position)
			var falloff := clampf(1.0 - dist / maxf(splash_radius, 0.1), 0.25, 1.0)
			health.apply_damage(damage * falloff, shooter, "rpg")
	SoundManager.play_explosion()
	_spawn_blast_visual()
	queue_free()

func _apply_self_grenade_knockback() -> void:
	if shooter == null or not shooter.has_method("apply_grenade_knockback"):
		return
	var shooter_pos := (shooter as Node3D).global_position
	var dist := global_position.distance_to(shooter_pos)
	if dist > splash_radius:
		return
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var up_velocity := sqrt(2.0 * gravity * SELF_GRENADE_LAUNCH_HEIGHT)
	shooter.apply_grenade_knockback(up_velocity)

func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.34
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.18, 0.09, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.48, 0.14, 1)
	mat.emission_energy_multiplier = 0.35
	mesh.material_override = mat
	add_child(mesh)

	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.34, 0.12, 1)
	light.light_energy = 1.2
	light.omni_range = 4.0
	add_child(light)

func _spawn_blast_visual() -> void:
	var blast := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = splash_radius * 0.28
	sphere.height = splash_radius * 0.56
	blast.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.44, 0.08, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 0.25, 0.05, 1)
	blast.material_override = mat
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position
	var tween := blast.create_tween()
	tween.tween_property(blast, "scale", Vector3(2.4, 2.4, 2.4), 0.18)
	tween.finished.connect(blast.queue_free)

func _find_health(target: Variant) -> Health:
	if target == null or not (target is Node):
		return null
	var node := target as Node
	while node != null:
		if node is Health:
			return node as Health
		if node.has_node("Health"):
			return node.get_node("Health") as Health
		node = node.get_parent()
	return null
