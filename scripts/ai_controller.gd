class_name AIController
extends CharacterBody3D

enum AIState { PATROL, CHASE, ATTACK, DEAD }

const SPEED := 4.6
const ATTACK_RANGE := 32.0
const KEEP_DISTANCE := 10.0
const THINK_INTERVAL := 0.35
## AI 瞄准散布半角（弧度）；模拟人类不精准
const AI_SPREAD_ANGLE := 0.045

## 难度参数（由 _apply_difficulty() 在 setup() 时设置）
var _speed := SPEED
var _spread_angle := AI_SPREAD_ANGLE
var _think_interval := THINK_INTERVAL
var _reaction_delay := 0.0   ## 看到目标后额外延迟开枪（秒）
var _reaction_timer := 0.0

## 随机行为计时器
var _strafe_timer := 0.0     ## 战斗横向走位换向计时
var _strafe_dir := 0.0       ## 当前横向分量：-1 左 / 0 无 / 1 右
var _jump_timer := 0.0       ## 随机跳跃计时
var _wander_timer := 0.0     ## 巡逻随机偏转计时
var _wander_angle := 0.0     ## 巡逻方向随机偏转（弧度）
## 装弹规避走位
var _dodge_timer := 0.0      ## 装弹时换向计时
var _dodge_dir := 0.0        ## 横向规避：-1 左 / 0 无 / 1 右
var _dodge_fwd := 0.0        ## 纵向规避：-1 后退 / 0 无 / 1 前进

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
	## 错开各 bot 的随机计时器，避免同步行为
	_strafe_timer = randf_range(0.4, 1.2)
	_jump_timer   = randf_range(2.0, 6.0)
	_wander_timer = randf_range(0.5, 2.0)
	_dodge_timer  = randf_range(0.3, 0.9)

func setup(manager: Node, new_team: String, index: int) -> void:
	match_manager = manager
	team = new_team
	enemy_team = "orange" if team == "blue" else "blue"
	bot_index = index
	if health != null:
		health.reset(team, 100.0)
	_apply_difficulty()
	_refresh_soldier_model()
	if weapon_system != null:
		weapon_system.select_weapon(index % 3)
		_refresh_weapon_model()

## 根据 GameSettings.bot_difficulty 设置 AI 参数
func _apply_difficulty() -> void:
	var d: String = GameSettings.bot_difficulty
	match d:
		"easy":
			_speed = 3.2
			_spread_angle = 0.16   ## 散布大，很不准
			_think_interval = 0.65 ## 反应慢
			_reaction_delay = 0.55 ## 额外开枪延迟 0.55 秒
		"normal":
			_speed = 4.2
			_spread_angle = 0.07
			_think_interval = 0.38
			_reaction_delay = 0.22
		"hard":
			_speed = 5.2
			_spread_angle = 0.025  ## 几乎精准
			_think_interval = 0.20
			_reaction_delay = 0.05

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
		think_timer = _think_interval
		_think()
	if _reaction_timer > 0.0:
		_reaction_timer -= delta
	_tick_random_behaviors(delta)
	_apply_behavior(delta)

## 每帧更新随机行为计时器
func _tick_random_behaviors(delta: float) -> void:
	## ── 随机跳跃 ──────────────────────────────────────────
	_jump_timer -= delta
	if _jump_timer <= 0.0:
		## 跳跃间隔：巡逻时更少（5-12s），战斗时更频繁（1.5-4s）
		if state == AIState.ATTACK or state == AIState.CHASE:
			_jump_timer = randf_range(1.5, 4.0)
		else:
			_jump_timer = randf_range(5.0, 12.0)
		if is_on_floor():
			var jump_chance := 0.55 if (state == AIState.ATTACK or state == AIState.CHASE) else 0.25
			if randf() < jump_chance:
				velocity.y = 6.5

	## ── 战斗横向走位（strafing） ──────────────────────────
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		if state == AIState.ATTACK:
			## 攻击状态：0.5-1.6s 换一次方向，70% 概率有横向分量
			_strafe_timer = randf_range(0.5, 1.6)
			var r := randf()
			if r < 0.35:
				_strafe_dir = 0.0   ## 停止走位
			elif r < 0.675:
				_strafe_dir = 1.0   ## 向右
			else:
				_strafe_dir = -1.0  ## 向左
		else:
			_strafe_dir = 0.0
			_strafe_timer = randf_range(0.8, 2.0)

	## ── 巡逻随机偏转 ──────────────────────────────────────
	_wander_timer -= delta
	if _wander_timer <= 0.0 and state == AIState.PATROL:
		_wander_timer = randf_range(1.2, 3.5)
		## 30% 概率小幅偏转，让路径不那么直
		if randf() < 0.30:
			_wander_angle = randf_range(-0.6, 0.6)

	## ── 装弹期间规避走位 ─────────────────────────────────
	## 只在 ATTACK 状态且正在装弹时激活，0.4-1.0s 换一次方向
	if state == AIState.ATTACK and weapon_system != null and weapon_system.is_reloading:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			_dodge_timer = randf_range(0.4, 1.0)
			var r := randf()
			if r < 0.20:
				## 20% 概率停止横向规避（短暂站定）
				_dodge_dir = 0.0
				_dodge_fwd = 0.0
			else:
				## 横向：随机左右
				_dodge_dir = 1.0 if randf() < 0.5 else -1.0
				## 纵向：60% 概率后退，40% 前进（受伤时本能后退）
				_dodge_fwd = -1.0 if randf() < 0.60 else 1.0
	else:
		## 不在装弹时清零规避分量，计时器保持
		_dodge_dir = 0.0
		_dodge_fwd = 0.0

func _think() -> void:
	if match_manager == null:
		state = AIState.PATROL
		return
	var prev_target := target
	target = match_manager.get_closest_enemy(team, self)
	if target != null:
		var dist := global_position.distance_to(target.global_position)
		state = AIState.ATTACK if dist <= ATTACK_RANGE else AIState.CHASE
		## 新发现目标时重置反应延迟计时器
		if target != prev_target:
			_reaction_timer = _reaction_delay
	else:
		state = AIState.PATROL

func _apply_behavior(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	match state:
		AIState.PATROL:
			## 加入随机偏转角，让巡逻路径有蛇形感
			var wander_target := patrol_target
			if _wander_angle != 0.0:
				var offset_dir := Vector3(sin(_wander_angle), 0.0, cos(_wander_angle))
				wander_target = global_position + offset_dir * 4.0
			_move_towards(wander_target, _speed * 0.75)
			if global_position.distance_to(patrol_target) < 2.5:
				_wander_angle = 0.0
				pick_new_patrol_target()
		AIState.CHASE:
			if target != null:
				_move_towards(target.global_position, _speed)
		AIState.ATTACK:
			if target != null:
				if _reaction_timer <= 0.0:
					_attack_target()
				var dist := global_position.distance_to(target.global_position)
				if dist > ATTACK_RANGE * 0.8:
					## 追击：全速前进，不叠加 strafe（避免超速）
					_move_towards(target.global_position, _speed)
				elif dist < KEEP_DISTANCE:
					## 太近：后退，不叠加 strafe
					_move_towards(global_position - (target.global_position - global_position), _speed * 0.5)
				else:
					## 保持距离：速度归零后再叠加横向走位
					velocity.x = move_toward(velocity.x, 0, _speed)
					velocity.z = move_toward(velocity.z, 0, _speed)
					if _strafe_dir != 0.0:
						var side := global_transform.basis.x * _strafe_dir * _speed * 0.75
						velocity.x += side.x
						velocity.z += side.z
				## 装弹规避：叠加后用速度上限钳制，防止超速
				if _dodge_dir != 0.0 or _dodge_fwd != 0.0:
					var side_vec := global_transform.basis.x * _dodge_dir * (_speed * 0.75)
					var fwd_mul  := 1.0 if _dodge_fwd > 0.0 else 0.5
					var fwd_vec  := -global_transform.basis.z * _dodge_fwd * (_speed * fwd_mul)
					velocity.x += side_vec.x + fwd_vec.x
					velocity.z += side_vec.z + fwd_vec.z
					## 水平速度不超过 _speed
					var flat_spd := Vector2(velocity.x, velocity.z).length()
					if flat_spd > _speed:
						var scale := _speed / flat_spd
						velocity.x *= scale
						velocity.z *= scale
	move_and_slide()

func _attack_target() -> void:
	if target == null or weapon_system == null:
		return
	var aim_origin := global_position + Vector3(0, 1.35, 0)
	var aim_target := target.global_position + Vector3(0, 1.15, 0)
	var dir := (aim_target - aim_origin).normalized()
	## 视线检测：如果中间有障碍物则不开枪
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(aim_origin, aim_target)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if self is CollisionObject3D:
		query.exclude = [(self as CollisionObject3D).get_rid()]
	var los_hit := space.intersect_ray(query)
	if not los_hit.is_empty():
		## 检查命中的是否是目标（或目标的子节点）
		var hit_body := los_hit.get("collider") as Node
		var is_target := false
		var check := hit_body
		while check != null:
			if check == target:
				is_target = true
				break
			check = check.get_parent()
		if not is_target:
			return  ## 被障碍物遮挡，停止射击
	look_at(Vector3(aim_target.x, global_position.y, aim_target.z), Vector3.UP)
	## 应用 AI 瞄准散布
	var scattered_dir := _scatter_direction(dir, _spread_angle)
	weapon_system.try_fire(aim_origin, scattered_dir, self, enemy_team)

## 在 direction 附近随机散布，模拟 AI 不精准
func _scatter_direction(direction: Vector3, half_angle: float) -> Vector3:
	if half_angle <= 0.0:
		return direction
	var up := Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right_vec := direction.cross(up).normalized()
	var up_vec := direction.cross(right_vec).normalized()
	var angle := randf() * half_angle
	var azimuth := randf() * TAU
	var offset := (right_vec * cos(azimuth) + up_vec * sin(azimuth)) * sin(angle)
	return (direction * cos(angle) + offset).normalized()

func _move_towards(pos: Vector3, spd: float = _speed) -> void:
	var flat := Vector3(pos.x, global_position.y, pos.z)
	var dir := (flat - global_position)
	if dir.length() < 0.1:
		velocity.x = move_toward(velocity.x, 0, spd)
		velocity.z = move_toward(velocity.z, 0, spd)
		return
	dir = dir.normalized()
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
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
