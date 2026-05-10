class_name AIController
extends CharacterBody3D

enum AIState { PATROL, CHASE, ATTACK, SEEK_AMMO, DEAD }

const SPEED := 4.6
const DEFAULT_ATTACK_RANGE := 32.0
const ATTACK_RANGES_BY_WEAPON := {
	"m416": 45.0,
	"barrett": 85.0,
	"rpg": 50.0,
}
const KEEP_DISTANCE := 10.0
const ROUTE_POINT_REACHED := 2.2
const STUCK_RECOVERY_SECONDS := 0.65
const OBSTACLE_LOOKAHEAD := 3.2
const OBSTACLE_SIDE_LOOKAHEAD := 2.4
const AVOIDANCE_STEER_SECONDS := 0.55
const STUCK_ESCAPE_SECONDS := 0.75
const NAV_DIRECTION_COMMIT_SECONDS := 1.15
const NAV_NO_PROGRESS_SECONDS := 1.10
const NAV_PROGRESS_EPS := 0.35
const NAV_PROBE_DISTANCE := 4.4
const NAV_MIN_CLEARANCE := 0.85
const NAV_FAN_ANGLES_DEG := [0.0, -18.0, 18.0, -36.0, 36.0, -58.0, 58.0, -82.0, 82.0, -125.0, 125.0, 165.0, -165.0]
const PREFERRED_ATTACK_DISTANCE_BY_WEAPON := {
	"m416": 24.0,
	"barrett": 42.0,
	"rpg": 28.0,
}
const THINK_INTERVAL := 0.35
## AI 瞄准散布半角（弧度）；模拟人类不精准
const AI_SPREAD_ANGLE := 0.045

## 难度参数（由 _apply_difficulty() 在 setup() 时设置）
var _speed := SPEED
var _spread_angle := AI_SPREAD_ANGLE
var _think_interval := THINK_INTERVAL
var _reaction_delay := 0.0   ## 看到目标后额外延迟开枪（秒）
var _reaction_timer := 0.0
var _preferred_distance_multiplier := 1.0

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
var ammo_target: AmmoPickup = null
var battle_route: Array[Vector3] = []
var route_index := 0
var patrol_target := Vector3.ZERO
var think_timer := 0.0
var collision_shape: CollisionShape3D
var body_model: Node3D
var weapon_mount: Node3D
var held_weapon_model: Node3D
var _spectate_hidden := false
var _last_position := Vector3.ZERO
var _stuck_timer := 0.0
var _stuck_count := 0
var _has_move_goal := false
var _avoid_dir := Vector3.ZERO
var _avoid_timer := 0.0
var _stuck_escape_dir := Vector3.ZERO
var _stuck_escape_timer := 0.0
var _nav_commit_dir := Vector3.ZERO
var _nav_commit_timer := 0.0
var _current_move_goal := Vector3.INF
var _last_move_goal := Vector3.INF
var _best_goal_distance := INF
var _no_progress_timer := 0.0

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
	_last_position = global_position

func set_battle_plan(route: Array[Vector3]) -> void:
	battle_route.clear()
	for point in route:
		battle_route.append(point)
	route_index = 0
	if not battle_route.is_empty():
		patrol_target = battle_route[0]
	else:
		pick_new_patrol_target()
	state = AIState.PATROL

## 根据 GameSettings.bot_difficulty 设置 AI 参数
func _apply_difficulty() -> void:
	var d := "normal"
	var settings := get_node_or_null("/root/GameSettings")
	if settings != null:
		d = str(settings.bot_difficulty)
	match d:
		"easy":
			_speed = 3.4
			_spread_angle = 0.13   ## 散布大，但不至于完全打不死人
			_think_interval = 0.55 ## 反应慢，但能持续推进
			_reaction_delay = 0.42 ## 额外开枪延迟 0.42 秒
			_preferred_distance_multiplier = 0.68 ## 简单难度必须贴近有效距离，否则远距离低命中会拖死局
		"normal":
			_speed = 4.2
			_spread_angle = 0.07
			_think_interval = 0.38
			_reaction_delay = 0.22
			_preferred_distance_multiplier = 0.9
		"hard":
			_speed = 5.2
			_spread_angle = 0.025  ## 几乎精准
			_think_interval = 0.20
			_reaction_delay = 0.05
			_preferred_distance_multiplier = 1.0

func get_health() -> Health:
	return health

func set_spectate_hidden(hidden: bool) -> void:
	_spectate_hidden = hidden
	if body_model != null:
		body_model.visible = not hidden
	if weapon_mount != null:
		weapon_mount.visible = not hidden

func get_attack_range_for_weapon_id(weapon_id: String) -> float:
	return float(ATTACK_RANGES_BY_WEAPON.get(weapon_id, DEFAULT_ATTACK_RANGE))

func _get_current_attack_range() -> float:
	if weapon_system == null:
		return DEFAULT_ATTACK_RANGE
	return get_attack_range_for_weapon_id(weapon_system.get_current_weapon_id())

func _get_current_preferred_attack_distance() -> float:
	if weapon_system == null:
		return DEFAULT_ATTACK_RANGE * 0.65
	var base := float(PREFERRED_ATTACK_DISTANCE_BY_WEAPON.get(weapon_system.get_current_weapon_id(), DEFAULT_ATTACK_RANGE * 0.65))
	return maxf(KEEP_DISTANCE + 3.0, base * _preferred_distance_multiplier)

func _needs_ammo() -> bool:
	if weapon_system == null or weapon_system.is_reloading:
		return false
	return weapon_system.get_current_ammo() <= 0 and weapon_system.get_current_reserve() <= 0

func _try_reload_if_needed() -> void:
	if weapon_system == null or weapon_system.is_reloading:
		return
	if weapon_system.get_current_ammo() <= 0 and weapon_system.get_current_reserve() > 0:
		weapon_system.start_reload()

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
	_tick_navigation_timers(delta)
	_tick_random_behaviors(delta)
	_apply_behavior(delta)
	_update_stuck_recovery(delta)

func _tick_navigation_timers(delta: float) -> void:
	_avoid_timer = maxf(0.0, _avoid_timer - delta)
	_stuck_escape_timer = maxf(0.0, _stuck_escape_timer - delta)
	_nav_commit_timer = maxf(0.0, _nav_commit_timer - delta)
	_current_move_goal = Vector3.INF
	if _avoid_timer <= 0.0:
		_avoid_dir = Vector3.ZERO
	if _stuck_escape_timer <= 0.0:
		_stuck_escape_dir = Vector3.ZERO
	if _nav_commit_timer <= 0.0:
		_nav_commit_dir = Vector3.ZERO

## 每帧更新随机行为计时器
func _tick_random_behaviors(delta: float) -> void:
	## ── 战斗随机跳跃 ───────────────────────────────────────
	## 巡逻/执行作战路线时不跳，避免撞低矮掩体或墙角后转圈。
	_jump_timer -= delta
	if _jump_timer <= 0.0:
		_jump_timer = randf_range(1.5, 4.0) if (state == AIState.ATTACK or state == AIState.CHASE) else randf_range(5.0, 12.0)
		if (state == AIState.ATTACK or state == AIState.CHASE) and is_on_floor() and randf() < 0.45:
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

	## ── 作战路线不随机偏航 ────────────────────────────────
	## AI 开局已有地图路线，巡逻阶段不再随机改方向，避免看起来乱跑或原地绕圈。
	_wander_angle = 0.0

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
	if _needs_ammo():
		target = null
		ammo_target = null
		if match_manager.has_method("get_closest_ammo_drop"):
			ammo_target = match_manager.get_closest_ammo_drop(self) as AmmoPickup
		state = AIState.SEEK_AMMO if ammo_target != null else AIState.PATROL
		return
	ammo_target = null
	_try_reload_if_needed()
	var prev_target := target
	var candidate: Node3D = match_manager.get_closest_enemy(team, self)
	target = candidate if _can_engage_candidate(candidate) else null
	if target != null:
		var dist := global_position.distance_to(target.global_position)
		var attack_range := _get_current_attack_range()
		state = AIState.ATTACK if dist <= attack_range else AIState.CHASE
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
			## 执行开局作战路线：只按航点推进，不随机蛇形乱跑。
			_move_towards(patrol_target, _speed * 0.82)
			if global_position.distance_to(patrol_target) < ROUTE_POINT_REACHED:
				_advance_route_waypoint()
		AIState.CHASE:
			if target != null:
				_move_towards(target.global_position, _speed)
		AIState.SEEK_AMMO:
			if ammo_target != null and is_instance_valid(ammo_target) and not ammo_target.is_queued_for_deletion():
				_move_towards(ammo_target.global_position, _speed)
				if global_position.distance_to(ammo_target.global_position) <= 1.5 and match_manager != null and match_manager.has_method("collect_ammo_drop"):
					match_manager.collect_ammo_drop(ammo_target, self)
					_try_reload_if_needed()
			else:
				ammo_target = null
				state = AIState.PATROL
		AIState.ATTACK:
			if target != null:
				var has_firing_lane := _has_firing_lane_to_target()
				if _reaction_timer <= 0.0 and has_firing_lane:
					_attack_target()
				var dist := global_position.distance_to(target.global_position)
				var preferred_dist := _get_current_preferred_attack_distance()
				if dist < KEEP_DISTANCE:
					## 太近：后退，不叠加 strafe
					_move_towards(global_position - (target.global_position - global_position), _speed * 0.5)
				elif dist > preferred_dist or (not has_firing_lane and dist > KEEP_DISTANCE):
					## 只把最大射程当作“可开枪范围”，移动上继续压到有效距离；遮挡时继续前压找角度
					_move_towards(target.global_position, _speed)
				else:
					## 到有效距离后才保持距离，并用横向走位制造交火
					velocity.x = move_toward(velocity.x, 0, _speed)
					velocity.z = move_toward(velocity.z, 0, _speed)
					if _strafe_dir != 0.0:
						var side_dir := (global_transform.basis.x * _strafe_dir).normalized()
						var steered_side := _get_obstacle_steered_direction(side_dir) * _speed * 0.75
						velocity.x += steered_side.x
						velocity.z += steered_side.z
						_has_move_goal = true
				## 装弹规避：叠加后用速度上限钳制，防止超速
				if _dodge_dir != 0.0 or _dodge_fwd != 0.0:
					var raw_dodge := global_transform.basis.x * _dodge_dir
					var fwd_mul  := 1.0 if _dodge_fwd > 0.0 else 0.5
					raw_dodge += -global_transform.basis.z * _dodge_fwd * fwd_mul
					var dodge_dir := _get_obstacle_steered_direction(raw_dodge.normalized()) if raw_dodge.length() > 0.1 else Vector3.ZERO
					var dodge_vec := dodge_dir * _speed
					velocity.x += dodge_vec.x
					velocity.z += dodge_vec.z
					_has_move_goal = true
					## 水平速度不超过 _speed
					var flat_spd := Vector2(velocity.x, velocity.z).length()
					if flat_spd > _speed:
						var scale := _speed / flat_spd
						velocity.x *= scale
						velocity.z *= scale
	move_and_slide()

func _can_engage_candidate(candidate: Node3D) -> bool:
	if candidate == null:
		return false
	var dist := global_position.distance_to(candidate.global_position)
	if dist <= KEEP_DISTANCE * 1.8:
		return true
	return dist <= _get_current_attack_range() * 1.15 and _has_line_to_unit(candidate)

func _has_firing_lane_to_target() -> bool:
	return _has_line_to_unit(target)

func _has_line_to_unit(unit: Node3D) -> bool:
	if unit == null:
		return false
	var aim_origin := global_position + Vector3(0, 1.35, 0)
	var aim_target := unit.global_position + Vector3(0, 1.15, 0)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(aim_origin, aim_target)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if self is CollisionObject3D:
		query.exclude = [(self as CollisionObject3D).get_rid()]
	var los_hit := space.intersect_ray(query)
	if los_hit.is_empty():
		return true
	var hit_body := los_hit.get("collider") as Node
	var check := hit_body
	while check != null:
		if check == unit:
			return true
		check = check.get_parent()
	return false

func _attack_target() -> void:
	if target == null or weapon_system == null:
		return
	var aim_origin := global_position + Vector3(0, 1.35, 0)
	var aim_target := target.global_position + Vector3(0, 1.15, 0)
	var dir := (aim_target - aim_origin).normalized()
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
	_has_move_goal = true
	var flat := Vector3(pos.x, global_position.y, pos.z)
	_current_move_goal = flat
	var desired := flat - global_position
	if desired.length() < 0.1:
		velocity.x = move_toward(velocity.x, 0, spd)
		velocity.z = move_toward(velocity.z, 0, spd)
		return
	var dir := _get_obstacle_steered_direction(desired.normalized())
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if Vector2(dir.x, dir.z).length() > 0.05:
		look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _get_obstacle_steered_direction(desired_dir: Vector3) -> Vector3:
	if desired_dir.length() < 0.1:
		return Vector3.ZERO
	var desired := Vector3(desired_dir.x, 0.0, desired_dir.z).normalized()
	if _stuck_escape_timer > 0.0 and _stuck_escape_dir.length() > 0.1:
		return _stuck_escape_dir.normalized()
	if _nav_commit_timer > 0.0 and _nav_commit_dir.length() > 0.1 and _probe_clearance(_nav_commit_dir.normalized(), OBSTACLE_SIDE_LOOKAHEAD) > NAV_MIN_CLEARANCE:
		return _nav_commit_dir.normalized()
	if not _is_direction_blocked(desired, OBSTACLE_LOOKAHEAD):
		_avoid_dir = Vector3.ZERO
		_avoid_timer = 0.0
		_nav_commit_dir = desired
		_nav_commit_timer = maxf(_nav_commit_timer, 0.25)
		return desired
	var steered := _choose_context_steering_direction(desired)
	_avoid_dir = steered
	_avoid_timer = AVOIDANCE_STEER_SECONDS
	_nav_commit_dir = steered
	_nav_commit_timer = NAV_DIRECTION_COMMIT_SECONDS
	return steered

func _choose_context_steering_direction(desired_dir: Vector3) -> Vector3:
	## 借鉴常见 Context Steering / Detour 思路：多方向采样，按“朝向目标 + 清障距离 + 不反复换边”打分。
	var best_dir := desired_dir
	var best_score := -INF
	for angle_deg in NAV_FAN_ANGLES_DEG:
		var candidate := desired_dir.rotated(Vector3.UP, deg_to_rad(float(angle_deg))).normalized()
		var clearance := _probe_clearance(candidate, NAV_PROBE_DISTANCE)
		var goal_score := candidate.dot(desired_dir) * 2.0
		var clearance_score := clampf(clearance / NAV_PROBE_DISTANCE, 0.0, 1.0) * 1.55
		var commitment_score := 0.0
		if _avoid_dir.length() > 0.1:
			commitment_score += candidate.dot(_avoid_dir.normalized()) * 0.45
		if _nav_commit_dir.length() > 0.1:
			commitment_score += candidate.dot(_nav_commit_dir.normalized()) * 0.55
		var reverse_penalty := 1.35 if candidate.dot(desired_dir) < -0.25 else 0.0
		var blocked_penalty := 3.0 if clearance <= NAV_MIN_CLEARANCE else 0.0
		var score := goal_score + clearance_score + commitment_score - reverse_penalty - blocked_penalty
		if score > best_score:
			best_score = score
			best_dir = candidate
	if best_score < -0.5:
		return _choose_escape_direction()
	return best_dir.normalized()

func _choose_clear_side(forward_dir: Vector3) -> float:
	var right := Vector3(-forward_dir.z, 0.0, forward_dir.x).normalized()
	var left_clearance := _probe_clearance(-right, OBSTACLE_SIDE_LOOKAHEAD)
	var right_clearance := _probe_clearance(right, OBSTACLE_SIDE_LOOKAHEAD)
	if absf(right_clearance - left_clearance) > 0.25:
		return 1.0 if right_clearance > left_clearance else -1.0
	if _nav_commit_dir.length() > 0.1:
		return 1.0 if _nav_commit_dir.dot(right) >= 0.0 else -1.0
	return 1.0 if bot_index % 2 == 0 else -1.0

func _choose_escape_direction() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.1:
		forward = Vector3(0, 0, -1 if team == "blue" else 1)
	forward = forward.normalized()
	var side := _choose_clear_side(forward)
	var side_dir := Vector3(-forward.z, 0.0, forward.x) * side
	var escape := (side_dir * 1.15 - forward * 0.35).normalized()
	if _is_direction_blocked(escape, OBSTACLE_SIDE_LOOKAHEAD):
		escape = (-side_dir - forward * 0.25).normalized()
	return escape

func _is_direction_blocked(dir: Vector3, distance: float) -> bool:
	return _probe_clearance(dir, distance) < distance

func _probe_clearance(dir: Vector3, distance: float) -> float:
	if dir.length() < 0.1 or get_world_3d() == null:
		return distance
	var flat_dir := Vector3(dir.x, 0.0, dir.z).normalized()
	var origin := global_position + Vector3(0, 0.9, 0)
	var end := origin + flat_dir * distance
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if self is CollisionObject3D:
		query.exclude = [(self as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return distance
	var hit_pos := hit.get("position") as Vector3
	return clampf(origin.distance_to(hit_pos), 0.0, distance)

func _advance_route_waypoint() -> void:
	if battle_route.is_empty():
		pick_new_patrol_target()
		return
	route_index = (route_index + 1) % battle_route.size()
	patrol_target = battle_route[route_index]

func _update_stuck_recovery(delta: float) -> void:
	if not _has_move_goal or state == AIState.DEAD:
		_last_position = global_position
		_stuck_timer = 0.0
		_stuck_count = 0
		_no_progress_timer = 0.0
		return
	var moved := global_position.distance_to(_last_position)
	var wants_move := Vector2(velocity.x, velocity.z).length() > 0.2
	_update_goal_progress(delta)
	if moved < 0.035 and wants_move:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
		if moved > 0.22:
			_stuck_count = 0
	if _stuck_timer >= STUCK_RECOVERY_SECONDS or _no_progress_timer >= NAV_NO_PROGRESS_SECONDS:
		_stuck_timer = 0.0
		_no_progress_timer = 0.0
		_stuck_count += 1
		_stuck_escape_dir = _choose_escape_direction()
		_stuck_escape_timer = STUCK_ESCAPE_SECONDS
		_avoid_dir = _stuck_escape_dir
		_avoid_timer = STUCK_ESCAPE_SECONDS
		_nav_commit_dir = _stuck_escape_dir
		_nav_commit_timer = NAV_DIRECTION_COMMIT_SECONDS
		if _stuck_count >= 2:
			_stuck_count = 0
			if state == AIState.PATROL:
				_advance_route_waypoint()
			elif target != null:
				state = AIState.PATROL
				target = null
				_advance_route_waypoint()
	_last_position = global_position
	_has_move_goal = false

func _update_goal_progress(delta: float) -> void:
	if _current_move_goal == Vector3.INF:
		return
	if _last_move_goal == Vector3.INF or _current_move_goal.distance_squared_to(_last_move_goal) > 4.0:
		_last_move_goal = _current_move_goal
		_best_goal_distance = global_position.distance_to(_current_move_goal)
		_no_progress_timer = 0.0
		return
	var dist := global_position.distance_to(_current_move_goal)
	if dist < _best_goal_distance - NAV_PROGRESS_EPS:
		_best_goal_distance = dist
		_no_progress_timer = 0.0
	else:
		_no_progress_timer += delta

func pick_new_patrol_target() -> void:
	if not battle_route.is_empty():
		patrol_target = battle_route[route_index % battle_route.size()]
	elif match_manager != null and match_manager.has_method("get_patrol_point"):
		patrol_target = match_manager.get_patrol_point(bot_index)
	else:
		patrol_target = global_position + Vector3(0, 0, -8 if team == "blue" else 8)

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
	body_model.visible = not _spectate_hidden

func _refresh_weapon_model() -> void:
	if weapon_mount == null or weapon_system == null:
		return
	if held_weapon_model != null:
		held_weapon_model.queue_free()
	held_weapon_model = ModelFactory.create_weapon_model(weapon_system.get_current_weapon_id(), false)
	weapon_mount.add_child(held_weapon_model)
	weapon_mount.visible = not _spectate_hidden

func _on_died(_killer: Node, _weapon_id: String) -> void:
	state = AIState.DEAD
	velocity = Vector3.ZERO
	if collision_shape != null:
		collision_shape.disabled = true
	if body_model != null:
		body_model.rotation_degrees.z = 90
	if weapon_mount != null:
		weapon_mount.visible = false
