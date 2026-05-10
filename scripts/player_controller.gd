class_name PlayerController
extends CharacterBody3D

signal player_health_changed(current_health: float, max_health: float)
signal player_shield_changed(current_shield: float, max_shield: float)
signal player_weapon_changed(display_name: String)
signal player_ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal player_died

const SPEED := 7.2
const JUMP_VELOCITY := 6.5
const MOBILE_JUMP_HEIGHT := 0.9  ## 约半个人高度
const WEAPON_SWITCH_DEBOUNCE_MSEC := 180
const WEAPON_SWITCH_ANIM_TIME := 0.24

var team := "blue"
var enemy_team := "orange"
var match_manager: MatchManager = null
var camera: Camera3D
var health: Health
var weapon_system: WeaponSystem
var mobile_move := Vector2.ZERO
var mobile_fire_down := false
var touch_controls_active := false
var weapon_holder: Node3D
var current_weapon_model: Node3D
var _weapon_switch_tween: Tween
var _last_weapon_switch_msec := -1000000
var _pitch := 0.0
var _dead := false
## 后坐力：剩余待施加的 pitch 偏移（弧度），每帧消耗
var _recoil_pending := 0.0
## 后坐力恢复：额外的 pitch 偏移（弧度），每帧向 0 平滑
var _recoil_offset := 0.0
## 武器摇摆：步行周期累计时间（秒）
var _bob_time := 0.0
## 脚步声：上一帧 sin 符号，用于检测过零点（每步触发一次）
var _bob_prev_sin := 0.0
## 观战系统
var _spectating := false
var _spectate_index := 0
var _spectate_target: Node3D = null
var _spectate_hidden_target: Node3D = null

func _ready() -> void:
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup(manager: MatchManager, new_team: String) -> void:
	match_manager = manager
	team = new_team
	enemy_team = "orange" if team == "blue" else "blue"
	if health != null:
		health.reset(team, 100.0, 30.0)
	## 连接击杀特效信号
	if match_manager != null and match_manager.has_signal("player_kill_effect"):
		match_manager.player_kill_effect.connect(_on_player_kill_effect)

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value.limit_length(1.0)

func set_mobile_look(delta: Vector2) -> void:
	_apply_look(delta.x, delta.y)

func set_mobile_fire(pressed: bool) -> void:
	mobile_fire_down = pressed

func set_touch_controls_active(active: bool) -> void:
	touch_controls_active = active
	if active:
		mobile_fire_down = false

func can_accept_mobile_input() -> bool:
	return not _dead and not (match_manager != null and match_manager.match_over)

func _request_next_weapon(use_debounce: bool) -> void:
	if weapon_system == null:
		return
	if use_debounce:
		var now := Time.get_ticks_msec()
		if now - _last_weapon_switch_msec < WEAPON_SWITCH_DEBOUNCE_MSEC:
			return
		_last_weapon_switch_msec = now
	weapon_system.next_weapon()

func mobile_next_weapon() -> void:
	_request_next_weapon(true)

func mobile_reload() -> void:
	if weapon_system != null:
		weapon_system.start_reload()

func mobile_jump() -> void:
	if can_accept_mobile_input() and is_on_floor():
		var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
		velocity.y = sqrt(2.0 * gravity * MOBILE_JUMP_HEIGHT)

func get_health() -> Health:
	return health

func _input(event: InputEvent) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative.x, event.relative.y)

func _unhandled_input(event: InputEvent) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("weapon_next"):
		weapon_system.next_weapon()
	if event.is_action_pressed("weapon_1"):
		weapon_system.select_weapon(0)
	if event.is_action_pressed("weapon_2"):
		weapon_system.select_weapon(1)
	if event.is_action_pressed("weapon_3"):
		weapon_system.select_weapon(2)
	if event.is_action_pressed("reload"):
		weapon_system.start_reload()

func _physics_process(delta: float) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		velocity = Vector3.ZERO
		if _spectating and _spectate_target != null:
			_follow_spectate_target(delta)
		return
	_apply_movement(delta)
	_apply_recoil(delta)
	_apply_weapon_bob(delta)
	## 触摸控件激活时忽略鼠标左键 fire，避免触屏 tap 误触发射击
	var fire_pressed := mobile_fire_down if touch_controls_active else Input.is_action_pressed("fire")
	if fire_pressed:
		var muzzle := weapon_holder.global_position if weapon_holder != null else camera.global_position
		weapon_system.try_fire(camera.global_position, -camera.global_transform.basis.z, self, enemy_team, muzzle)

## 每帧平滑施加后坐力并自动回正
func _apply_recoil(delta: float) -> void:
	## 施加待处理的后坐力冲量（每帧最多 0.012 rad，分多帧施加感觉更真实）
	var apply_now := minf(_recoil_pending, 0.012)
	_recoil_pending -= apply_now
	_recoil_offset += apply_now
	_pitch -= apply_now
	_pitch = clampf(_pitch, deg_to_rad(-82), deg_to_rad(82))
	## 回正：recoil_offset 向 0 平滑，同步恢复 pitch
	var recover := _recoil_offset * clampf(7.0 * delta, 0.0, 1.0)
	_recoil_offset -= recover
	_pitch += recover
	_pitch = clampf(_pitch, deg_to_rad(-82), deg_to_rad(82))
	camera.rotation.x = _pitch

## 开枪信号回调：积累后坐力冲量
func _on_weapon_fired_recoil(_weapon_id: String) -> void:
	_recoil_pending += 0.028  ## 每发子弹向上偏转约 1.6°

## 武器摇摆：移动时 weapon_holder 做正弦上下 + 左右小幅摆动
func _apply_weapon_bob(delta: float) -> void:
	if weapon_holder == null:
		return
	var speed_xz := Vector2(velocity.x, velocity.z).length()
	var moving := speed_xz > 0.5 and is_on_floor()
	if moving:
		_bob_time += delta * 9.0  ## 步频（9 rad/s ≈ 1.4 步/秒）
	else:
		## 停下后平滑归零
		_bob_time = move_toward(_bob_time, round(_bob_time / PI) * PI, delta * 6.0)
	var bob_sin := sin(_bob_time)
	## 脚步音效：sin 从负 → 正过零点时触发（每完整步伐一次）
	if moving and _bob_prev_sin < 0.0 and bob_sin >= 0.0:
		SoundManager.play_footstep()
	_bob_prev_sin = bob_sin
	var bob_y := bob_sin * 0.018
	var bob_x := cos(_bob_time * 0.5) * 0.009
	weapon_holder.position = Vector3(0.38 + bob_x, -0.24 + bob_y, -0.72)

func _apply_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if mobile_move.length() > 0.05:
		input_dir = mobile_move
	if input_dir.length() > 0.01:
		## 前进×1.0 / 左右×0.75 / 后退×0.5
		var fwd_mul  := 1.0 if input_dir.y < 0.0 else 0.5
		var side_mul := 0.75
		## 分离纵横分量，各自乘以对应倍率后再合并
		var fwd_component  := global_transform.basis.z * input_dir.y * SPEED * fwd_mul
		var side_component := global_transform.basis.x * input_dir.x * SPEED * side_mul
		var move_vec := fwd_component + side_component
		velocity.x = move_vec.x
		velocity.z = move_vec.z
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _apply_look(relative_x: float, relative_y: float) -> void:
	var sensitivity: float = GameSettings.mouse_sensitivity
	rotate_y(deg_to_rad(-relative_x * sensitivity))
	_pitch = clampf(_pitch - deg_to_rad(relative_y * sensitivity), deg_to_rad(-82), deg_to_rad(82))
	## camera.rotation.x 由 _apply_recoil 每帧统一写入，这里只更新目标 pitch

func _build_body() -> void:
	if has_node("CollisionShape3D"):
		return
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	var body_model := ModelFactory.create_soldier_model(team)
	body_model.name = "BodyModel"
	body_model.visible = false
	add_child(body_model)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = 78
	camera.current = true
	add_child(camera)

	weapon_holder = Node3D.new()
	weapon_holder.name = "WeaponHolder"
	weapon_holder.position = Vector3(0.38, -0.24, -0.72)
	camera.add_child(weapon_holder)

	health = Health.new()
	health.name = "Health"
	health.reset(team, 100.0, 30.0)
	health.health_changed.connect(func(current: float, max_value: float) -> void:
		SoundManager.play_hurt()
		player_health_changed.emit(current, max_value)
	)
	health.shield_changed.connect(func(current: float, max_value: float) -> void:
		player_shield_changed.emit(current, max_value)
	)
	health.died.connect(_on_died)
	add_child(health)

	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	weapon_system.weapon_changed.connect(func(display_name: String) -> void:
		player_weapon_changed.emit(display_name)
		_refresh_weapon_model()
	)
	weapon_system.ammo_changed.connect(func(current: int, reserve: int, reloading: bool) -> void:
		player_ammo_changed.emit(current, reserve, reloading)
	)
	weapon_system.weapon_fired.connect(_on_weapon_fired_recoil)
	weapon_system.damage_dealt.connect(_on_damage_dealt)
	add_child(weapon_system)
	call_deferred("_refresh_weapon_model")

func _refresh_weapon_model() -> void:
	if weapon_holder == null or weapon_system == null:
		return
	var weapon_id := weapon_system.get_current_weapon_id()
	if current_weapon_model != null and current_weapon_model.name == "WeaponModel_%s" % weapon_id:
		return
	var old_model := current_weapon_model
	current_weapon_model = ModelFactory.create_weapon_model(weapon_id, true)
	var base_rotation := current_weapon_model.rotation_degrees
	var base_scale := current_weapon_model.scale
	current_weapon_model.position = Vector3(0.22, -0.34, 0.18)
	current_weapon_model.rotation_degrees = base_rotation + Vector3(18.0, -32.0, 10.0)
	current_weapon_model.scale = base_scale * 0.92
	weapon_holder.add_child(current_weapon_model)
	_play_weapon_switch_animation(old_model, current_weapon_model, base_rotation, base_scale)

func _play_weapon_switch_animation(old_model: Node3D, new_model: Node3D, base_rotation: Vector3, base_scale: Vector3) -> void:
	if _weapon_switch_tween != null and _weapon_switch_tween.is_valid():
		_weapon_switch_tween.kill()
	_weapon_switch_tween = create_tween()
	_weapon_switch_tween.set_parallel(true)
	if old_model != null and is_instance_valid(old_model):
		_weapon_switch_tween.tween_property(old_model, "position", old_model.position + Vector3(-0.08, -0.32, 0.16), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_property(old_model, "rotation_degrees", old_model.rotation_degrees + Vector3(12.0, 18.0, -8.0), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_property(old_model, "scale", old_model.scale * 0.88, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_callback(_queue_free_if_valid.bind(old_model)).set_delay(0.12)
	_weapon_switch_tween.tween_property(new_model, "position", Vector3.ZERO, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(new_model, "rotation_degrees", base_rotation, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(new_model, "scale", base_scale, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _queue_free_if_valid(node: Node) -> void:
	if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
		node.queue_free()

func _on_died(_killer: Node, _weapon_id: String) -> void:
	_dead = true
	SoundManager.play_death()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit()
	_enter_spectate_mode()

func _enter_spectate_mode() -> void:
	if match_manager == null:
		return
	var targets := match_manager.get_spectate_targets()
	if targets.is_empty():
		return
	_spectating = true
	_spectate_index = 0
	_set_spectate_target(targets[0])
	## 通知 HUD 进入观战模式
	if match_manager.hud != null and match_manager.hud.has_method("enter_spectate_mode"):
		match_manager.hud.enter_spectate_mode(self)

func spectate_next() -> void:
	if match_manager == null:
		return
	var targets := match_manager.get_spectate_targets()
	if targets.is_empty():
		_set_spectate_target(null)
		return
	_spectate_index = (_spectate_index + 1) % targets.size()
	_set_spectate_target(targets[_spectate_index])
	if match_manager.hud != null and match_manager.hud.has_method("update_spectate_target_name"):
		match_manager.hud.update_spectate_target_name(_get_spectate_name())

func spectate_prev() -> void:
	if match_manager == null:
		return
	var targets := match_manager.get_spectate_targets()
	if targets.is_empty():
		_set_spectate_target(null)
		return
	_spectate_index = (_spectate_index - 1 + targets.size()) % targets.size()
	_set_spectate_target(targets[_spectate_index])
	if match_manager.hud != null and match_manager.hud.has_method("update_spectate_target_name"):
		match_manager.hud.update_spectate_target_name(_get_spectate_name())

func _set_spectate_target(new_target: Node3D) -> void:
	if _spectate_hidden_target != null and is_instance_valid(_spectate_hidden_target) and _spectate_hidden_target.has_method("set_spectate_hidden"):
		_spectate_hidden_target.set_spectate_hidden(false)
	_spectate_target = new_target
	_spectate_hidden_target = null
	if _spectate_target != null and is_instance_valid(_spectate_target) and _spectate_target.has_method("set_spectate_hidden"):
		_spectate_target.set_spectate_hidden(true)
		_spectate_hidden_target = _spectate_target

func _get_spectate_name() -> String:
	if match_manager == null or _spectate_target == null:
		return ""
	var team_str := str(_spectate_target.get_meta("team", "blue"))
	if _spectate_target is AIController:
		return "蓝队#%d" % _spectate_target.bot_index
	return "蓝队玩家"

func _follow_spectate_target(delta: float) -> void:
	if _spectate_target == null or not is_instance_valid(_spectate_target):
		## 目标已死亡，尝试切换到下一个
		spectate_next()
		return
	## 检查目标是否仍然存活
	var target_health: Health = null
	if _spectate_target.has_method("get_health"):
		target_health = _spectate_target.get_health()
	elif _spectate_target.has_node("Health"):
		target_health = _spectate_target.get_node("Health")
	if target_health != null and not target_health.is_alive:
		spectate_next()
		return
	## 摄像机跟随目标头部位置
	var head_offset := Vector3(0, 1.62, 0)
	var target_pos := _spectate_target.global_position + head_offset
	camera.global_position = camera.global_position.lerp(target_pos, clampf(8.0 * delta, 0.0, 1.0))
	## 朝向与目标一致
	camera.global_rotation = camera.global_rotation.lerp(_spectate_target.global_rotation, clampf(6.0 * delta, 0.0, 1.0))

func _on_player_kill_effect(kill_pos: Vector3, victim_name: String) -> void:
	## 显示右上角旗型击杀条幅
	if match_manager != null and match_manager.hud != null and match_manager.hud.has_method("show_kill_banner"):
		match_manager.hud.show_kill_banner("你", victim_name)
	## 在击杀位置生成 3D 灵魂出窍 + 爆炸效果
	var ke := KillEffect.new()
	get_tree().current_scene.add_child(ke)
	ke.setup(kill_pos)

func _on_damage_dealt(amount: float, hit_position: Vector3) -> void:
	var dn := DamageNumber.new()
	get_tree().current_scene.add_child(dn)
	dn.setup(amount, hit_position)
