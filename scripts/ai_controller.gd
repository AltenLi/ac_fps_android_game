class_name AIController
extends CharacterBody3D

enum AIState { PATROL, CHASE, ATTACK, DEAD }

const SPEED := 4.6
const ATTACK_RANGE := 48.0
const KEEP_DISTANCE := 10.0
const THINK_INTERVAL := 0.35

var team := "orange"
var enemy_team := "blue"
var bot_index := 0
var match_manager: Node = null
var health: Health
var weapon_system: WeaponSystem
var state := AIState.PATROL
var target: Node3D = null
var patrol_target := Vector3.ZERO
var think_timer := 0.0
var collision_shape: CollisionShape3D
var body_model: Node3D
var weapon_mount: Node3D
var held_weapon_model: Node3D

func _ready() -> void:
	_build_body()
	pick_new_patrol_target()

func setup(manager: Node, new_team: String, index: int) -> void:
	match_manager = manager
	team = new_team
	enemy_team = "orange" if team == "blue" else "blue"
	bot_index = index
	if health != null:
		health.reset(team, 100.0)
	_refresh_soldier_model()
	if weapon_system != null:
		weapon_system.select_weapon(index % 3)
		_refresh_weapon_model()

func get_health() -> Health:
	return health

func _physics_process(delta: float) -> void:
	if state == AIState.DEAD or health == null or not health.is_alive:
		return
	if match_manager != null and match_manager.match_over:
		velocity = Vector3.ZERO
		return
	think_timer -= delta
	if think_timer <= 0.0:
		think_timer = THINK_INTERVAL
		_think()
	_apply_behavior(delta)

func _think() -> void:
	if match_manager == null:
		state = AIState.PATROL
		return
	target = match_manager.get_closest_enemy(team, self)
	if target != null:
		var dist := global_position.distance_to(target.global_position)
		state = AIState.ATTACK if dist <= ATTACK_RANGE else AIState.CHASE
	else:
		state = AIState.PATROL

func _apply_behavior(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	match state:
		AIState.PATROL:
			_move_towards(patrol_target)
			if global_position.distance_to(patrol_target) < 2.5:
				pick_new_patrol_target()
		AIState.CHASE:
			if target != null:
				_move_towards(target.global_position)
		AIState.ATTACK:
			if target != null:
				_attack_target()
				var dist := global_position.distance_to(target.global_position)
				if dist > ATTACK_RANGE * 0.8:
					_move_towards(target.global_position)
				elif dist < KEEP_DISTANCE:
					_move_towards(global_position - (target.global_position - global_position))
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED * 0.5)
					velocity.z = move_toward(velocity.z, 0, SPEED * 0.5)
	move_and_slide()

func _attack_target() -> void:
	if target == null or weapon_system == null:
		return
	var aim_origin := global_position + Vector3(0, 1.35, 0)
	var aim_target := target.global_position + Vector3(0, 1.15, 0)
	var dir := (aim_target - aim_origin).normalized()
	look_at(Vector3(aim_target.x, global_position.y, aim_target.z), Vector3.UP)
	weapon_system.try_fire(aim_origin, dir, self, enemy_team)

func _move_towards(pos: Vector3) -> void:
	var flat := Vector3(pos.x, global_position.y, pos.z)
	var dir := (flat - global_position)
	if dir.length() < 0.1:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		return
	dir = dir.normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func pick_new_patrol_target() -> void:
	if match_manager != null and match_manager.has_method("get_patrol_point"):
		patrol_target = match_manager.get_patrol_point(bot_index)
	else:
		patrol_target = global_position + Vector3(randf_range(-12, 12), 0, randf_range(-12, 12))

func _build_body() -> void:
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision_shape.shape = capsule
	collision_shape.position.y = 0.9
	add_child(collision_shape)

	body_model = Node3D.new()
	body_model.name = "BodyModel"
	add_child(body_model)

	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_mount.position = Vector3(0.34, 1.26, -0.34)
	weapon_mount.rotation_degrees = Vector3(-6, -8, 0)
	add_child(weapon_mount)

	health = Health.new()
	health.name = "Health"
	health.reset(team, 100.0)
	health.died.connect(_on_died)
	add_child(health)

	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	weapon_system.weapon_changed.connect(func(_display_name: String) -> void:
		_refresh_weapon_model()
	)
	add_child(weapon_system)
	_refresh_soldier_model()
	call_deferred("_refresh_weapon_model")

func _refresh_soldier_model() -> void:
	if body_model == null:
		return
	for child in body_model.get_children():
		child.queue_free()
	body_model.add_child(ModelFactory.create_soldier_model(team))

func _refresh_weapon_model() -> void:
	if weapon_mount == null or weapon_system == null:
		return
	if held_weapon_model != null:
		held_weapon_model.queue_free()
	held_weapon_model = ModelFactory.create_weapon_model(weapon_system.get_current_weapon_id(), false)
	weapon_mount.add_child(held_weapon_model)

func _on_died(_killer: Node, _weapon_id: String) -> void:
	state = AIState.DEAD
	velocity = Vector3.ZERO
	if collision_shape != null:
		collision_shape.disabled = true
	if body_model != null:
		body_model.rotation_degrees.z = 90
	if weapon_mount != null:
		weapon_mount.visible = false
