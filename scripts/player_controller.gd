class_name PlayerController
extends CharacterBody3D

signal player_health_changed(current_health: float, max_health: float)
signal player_shield_changed(current_shield: float, max_shield: float)
signal player_weapon_changed(display_name: String)
signal player_ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal player_scope_changed(active: bool, weapon_id: String)
signal player_died
signal tutorial_action(action: String)

const GRENADE_PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const SPEED := 7.2
const JUMP_HEIGHT := 5.4
const JUMP_VELOCITY := 10.5
const SECOND_JUMP_HEIGHT := 2.7
const MOBILE_JUMP_HEIGHT := JUMP_HEIGHT
const WEAPON_SWITCH_DEBOUNCE_MSEC := 180
const SCOPE_TOGGLE_DEBOUNCE_MSEC := 140
const WEAPON_SWITCH_ANIM_TIME := 0.24
const BASE_CAMERA_FOV := 78.0
const SCOPE_ZOOM_LEVELS := [1.0, 2.5, 5.0]
const STANDING_BODY_HEIGHT := 1.8
const PRONE_BODY_HEIGHT := STANDING_BODY_HEIGHT / 5.0
const STANDING_CAMERA_Y := 1.62
const PRONE_CAMERA_Y := PRONE_BODY_HEIGHT * 0.82
const PRONE_SPEED_MULTIPLIER := 0.38
const GRENADE_COOLDOWN := 2.0
const GRENADE_MAX_PER_ROUND := 10
const GRENADE_DAMAGE := 95.0
const GRENADE_RADIUS := 5.0
const GRENADE_SPEED := 18.0
const GRENADE_RANGE := 42.0
const GRENADE_ARC_LIFT := 7.5
const LASER_TOWER_BUILD_SECONDS := 4.0
const LASER_TOWER_GROUND_RAY_HEIGHT := 3.0
const LASER_TOWER_GROUND_RAY_DEPTH := 8.0

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
var _weapon_fire_tween: Tween
var _weapon_reload_tween: Tween
var _jump_motion_tween: Tween
var _jump_kick := 0.0
var _last_weapon_switch_msec := -1000000
var _last_scope_toggle_msec := -1000000
var _pitch := 0.0
var _dead := false
var _recoil_pending := 0.0
var _recoil_offset := 0.0
var _bob_time := 0.0
var _bob_prev_sin := 0.0
var _spectating := false
var _spectate_index := 0
var _spectate_target: Node3D = null
var _spectate_hidden_target: Node3D = null
var _scope_index := 0
var _target_fov := BASE_CAMERA_FOV
var _air_jumps_used := 0
var _jump_started := false
var _grenade_timer := 0.0
var _grenades_remaining := GRENADE_MAX_PER_ROUND
var _is_prone := false
var _resupply_locked := false
var _laser_build_locked := false
var _speed_multiplier := 1.0
var _grenade_radius_multiplier := 1.0
var _laser_build_seconds := LASER_TOWER_BUILD_SECONDS
var _laser_bonus_targets := 0
var _laser_tower_built_this_round := false
var _collision_shape: CollisionShape3D
var _body_capsule: CapsuleShape3D

func _ready() -> void:
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	if _weapon_switch_tween != null and _weapon_switch_tween.is_valid():
		_weapon_switch_tween.kill()
	_weapon_switch_tween = null
	if _weapon_fire_tween != null and _weapon_fire_tween.is_valid():
		_weapon_fire_tween.kill()
	_weapon_fire_tween = null
	if _weapon_reload_tween != null and _weapon_reload_tween.is_valid():
		_weapon_reload_tween.kill()
	_weapon_reload_tween = null
	if _jump_motion_tween != null and _jump_motion_tween.is_valid():
		_jump_motion_tween.kill()
	_jump_motion_tween = null

func setup(manager: MatchManager, new_team: String) -> void:
	match_manager = manager
	team = new_team
	enemy_team = "orange" if team == "blue" else "blue"
	if health != null:
		health.reset(team, 100.0, 30.0)
	## 杩炴帴鍑绘潃鐗规晥淇″彿
	if match_manager != null and match_manager.has_signal("player_kill_effect"):
		match_manager.player_kill_effect.connect(_on_player_kill_effect)

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value.limit_length(1.0)
	if mobile_move.length() > 0.25:
		tutorial_action.emit("move")

func set_mobile_look(delta: Vector2) -> void:
	_apply_look(delta.x, delta.y)
	if delta.length() > 1.0:
		tutorial_action.emit("look")

func set_mobile_fire(pressed: bool) -> void:
	mobile_fire_down = pressed
	if pressed:
		tutorial_action.emit("fire")

func set_touch_controls_active(active: bool) -> void:
	touch_controls_active = active
	if active:
		mobile_fire_down = false

func can_accept_mobile_input() -> bool:
	return not _dead and not _resupply_locked and not _laser_build_locked and not (match_manager != null and match_manager.match_over)

func apply_character_profile(character_id: String) -> void:
	_speed_multiplier = 1.0
	_laser_build_seconds = LASER_TOWER_BUILD_SECONDS
	_laser_bonus_targets = 0
	if weapon_system != null:
		match character_id:
			"assault":
				_speed_multiplier = 1.10
				weapon_system.configure_match_rules([], {"m416": 1.10}, {})
			"sniper":
				weapon_system.configure_match_rules([], {}, {"barrett": 0.78})
			"engineer":
				_laser_build_seconds = 3.0
				_laser_bonus_targets = 1
				weapon_system.configure_match_rules([], {}, {})
			"medic":
				weapon_system.configure_match_rules([], {}, {})
			_:
				weapon_system.configure_match_rules([], {}, {})

func apply_map_weapon_rules(allowed_ids: Array[String]) -> void:
	if weapon_system != null and not allowed_ids.is_empty():
		weapon_system.configure_match_rules(allowed_ids, weapon_system.damage_multipliers, weapon_system.cooldown_multipliers)

func apply_tactical_chip(chip_id: String) -> void:
	match chip_id:
		"grenade_boost":
			_grenade_radius_multiplier = 1.45
		"speed_boost":
			_speed_multiplier = maxf(_speed_multiplier, 1.24)
			get_tree().create_timer(10.0).timeout.connect(func() -> void:
				_speed_multiplier = 1.10 if GameSettings.selected_character_id == "assault" else 1.0
			)
		"tower_boost":
			_laser_bonus_targets += 1

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
	tutorial_action.emit("switch")

func mobile_reload() -> void:
	if weapon_system != null:
		weapon_system.start_reload()

func mobile_jump() -> void:
	if not can_accept_mobile_input():
		return
	_try_jump()
	tutorial_action.emit("jump")

func mobile_toggle_scope() -> void:
	if can_accept_mobile_input():
		_cycle_scope_zoom()

func mobile_throw_grenade() -> void:
	if can_accept_mobile_input():
		_throw_grenade()
		tutorial_action.emit("grenade")

func mobile_toggle_prone() -> void:
	if can_accept_mobile_input():
		_set_prone(not _is_prone)

func mobile_build_laser_tower() -> void:
	if can_accept_mobile_input():
		if _start_laser_tower_build():
			tutorial_action.emit("tower")

func get_health() -> Health:
	return health

func is_prone() -> bool:
	return _is_prone

func get_auto_rpg_remaining() -> float:
	return maxf(0.0, _grenade_timer)

func get_grenades_remaining() -> int:
	return _grenades_remaining

func set_resupply_locked(locked: bool) -> void:
	_resupply_locked = locked
	if locked:
		mobile_move = Vector2.ZERO
		mobile_fire_down = false
		velocity = Vector3.ZERO

func has_full_round_supplies() -> bool:
	var weapons_full := weapon_system == null or weapon_system.has_full_round_supplies()
	return weapons_full and _grenades_remaining >= GRENADE_MAX_PER_ROUND

func reset_supplies_to_round_start() -> void:
	if weapon_system != null:
		weapon_system.reset_supplies_to_round_start()
	_grenades_remaining = GRENADE_MAX_PER_ROUND
	_grenade_timer = 0.0

func _input(event: InputEvent) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		return
	if _resupply_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative.x, event.relative.y)
		if event.relative.length() > 1.0:
			tutorial_action.emit("look")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_request_scope_zoom(true)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		return
	if _resupply_locked or _laser_build_locked:
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameSettings.save_settings()
		get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("weapon_next"):
		_request_next_weapon(true)
		tutorial_action.emit("switch")
	if event.is_action_pressed("weapon_1"):
		weapon_system.select_weapon(0)
	if event.is_action_pressed("weapon_2"):
		weapon_system.select_weapon(1)
	if event.is_action_pressed("weapon_3"):
		weapon_system.select_weapon(2)
	if event.is_action_pressed("reload"):
		weapon_system.start_reload()
	if event.is_action_pressed("scope_zoom"):
		_request_scope_zoom(true)
	if event.is_action_pressed("throw_grenade"):
		_throw_grenade()
		tutorial_action.emit("grenade")
	if event.is_action_pressed("prone"):
		_set_prone(not _is_prone)
	if event.is_action_pressed("build_laser_tower"):
		if _start_laser_tower_build():
			tutorial_action.emit("tower")

func _physics_process(delta: float) -> void:
	if _dead or (match_manager != null and match_manager.match_over):
		velocity = Vector3.ZERO
		if _spectating and _spectate_target != null:
			_follow_spectate_target(delta)
		return
	if _resupply_locked:
		velocity = Vector3.ZERO
		_update_grenade_cooldown(delta)
		_update_scope_zoom(delta)
		return
	if _laser_build_locked:
		velocity = Vector3.ZERO
		_update_grenade_cooldown(delta)
		_update_scope_zoom(delta)
		return
	_apply_movement(delta)
	_update_grenade_cooldown(delta)
	_update_scope_zoom(delta)
	_apply_recoil(delta)
	_apply_weapon_bob(delta)
	var fire_pressed := mobile_fire_down if touch_controls_active else Input.is_action_pressed("fire")
	if fire_pressed:
		tutorial_action.emit("fire")
		var muzzle := weapon_holder.global_position if weapon_holder != null else camera.global_position
		weapon_system.try_fire(camera.global_position, -camera.global_transform.basis.z, self, enemy_team, muzzle)

func _apply_recoil(delta: float) -> void:
	var apply_now := minf(_recoil_pending, 0.012)
	_recoil_pending -= apply_now
	_recoil_offset += apply_now
	_pitch -= apply_now
	_pitch = clampf(_pitch, deg_to_rad(-82), deg_to_rad(82))
	var recover := _recoil_offset * clampf(7.0 * delta, 0.0, 1.0)
	_recoil_offset -= recover
	_pitch += recover
	_pitch = clampf(_pitch, deg_to_rad(-82), deg_to_rad(82))
	camera.rotation.x = _pitch

func _on_weapon_fired(weapon_id: String) -> void:
	if weapon_id == "knife":
		_play_knife_swing_animation()
		return
	_recoil_pending += 0.028
	_play_gun_fire_animation(weapon_id)

func _on_reload_started(weapon_id: String) -> void:
	_play_reload_animation(weapon_id)

func _play_gun_fire_animation(weapon_id: String) -> void:
	if current_weapon_model == null:
		return
	if _weapon_fire_tween != null and _weapon_fire_tween.is_valid():
		_weapon_fire_tween.kill()
	var rest_pos := current_weapon_model.position
	var rest_rot := current_weapon_model.rotation_degrees
	var kick := 0.16 if weapon_id == "barrett" else 0.09
	var lift := 8.0 if weapon_id == "barrett" else 4.5
	_weapon_fire_tween = create_tween()
	_weapon_fire_tween.set_parallel(true)
	_weapon_fire_tween.tween_property(current_weapon_model, "position", rest_pos + Vector3(0.0, 0.018, kick), 0.045).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(-lift, 1.8, -1.4), 0.045).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.chain().tween_property(current_weapon_model, "position", rest_pos + Vector3(0.0, -0.012, -0.025), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weapon_fire_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(1.5, -0.6, 0.4), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weapon_fire_tween.chain().tween_property(current_weapon_model, "position", rest_pos, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _play_reload_animation(weapon_id: String) -> void:
	if current_weapon_model == null or weapon_id == "knife":
		return
	if _weapon_reload_tween != null and _weapon_reload_tween.is_valid():
		_weapon_reload_tween.kill()
	if _weapon_fire_tween != null and _weapon_fire_tween.is_valid():
		_weapon_fire_tween.kill()
	var rest_pos := current_weapon_model.position
	var rest_rot := current_weapon_model.rotation_degrees
	var rest_scale := current_weapon_model.scale
	var reload_time := 0.95
	if weapon_system != null and not weapon_system.weapons.is_empty():
		reload_time = clampf(weapon_system.weapons[weapon_system.current_index].reload_time, 0.75, 1.8)
	var magazine := current_weapon_model.find_child("Magazine", true, false) as Node3D
	var mag_rest_pos := magazine.position if magazine != null else Vector3.ZERO
	_weapon_reload_tween = create_tween()
	_weapon_reload_tween.tween_property(current_weapon_model, "position", rest_pos + Vector3(0.10, -0.22, 0.15), reload_time * 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_weapon_reload_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(18.0, -24.0, 28.0), reload_time * 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if magazine != null:
		_weapon_reload_tween.chain().tween_property(magazine, "position", mag_rest_pos + Vector3(0, -0.26, 0.06), reload_time * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_weapon_reload_tween.parallel().tween_property(magazine, "rotation_degrees", magazine.rotation_degrees + Vector3(-10.0, 0.0, 8.0), reload_time * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_weapon_reload_tween.chain().tween_property(magazine, "position", mag_rest_pos + Vector3(0, -0.08, 0.02), reload_time * 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_weapon_reload_tween.chain().tween_property(magazine, "position", mag_rest_pos, reload_time * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_weapon_reload_tween.parallel().tween_property(magazine, "rotation_degrees", Vector3(-10, 0, 0) if weapon_id == "m416" else Vector3(-4, 0, 0), reload_time * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_reload_tween.chain().tween_property(current_weapon_model, "position", rest_pos + Vector3(-0.04, 0.04, -0.08), reload_time * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_reload_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(-6.0, 8.0, -8.0), reload_time * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_reload_tween.chain().tween_property(current_weapon_model, "position", rest_pos, reload_time * 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weapon_reload_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot, reload_time * 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weapon_reload_tween.parallel().tween_property(current_weapon_model, "scale", rest_scale, reload_time * 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _play_knife_swing_animation() -> void:
	if current_weapon_model == null:
		return
	if _weapon_fire_tween != null and _weapon_fire_tween.is_valid():
		_weapon_fire_tween.kill()
	var rest_pos := current_weapon_model.position
	var rest_rot := current_weapon_model.rotation_degrees
	var rest_scale := current_weapon_model.scale
	_weapon_fire_tween = create_tween()
	_weapon_fire_tween.set_parallel(true)
	_weapon_fire_tween.tween_property(current_weapon_model, "position", rest_pos + Vector3(0.18, -0.04, -0.34), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(-28.0, 58.0, -42.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.tween_property(current_weapon_model, "scale", rest_scale * 1.08, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.chain().tween_property(current_weapon_model, "position", rest_pos + Vector3(-0.08, 0.02, -0.08), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weapon_fire_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot + Vector3(18.0, -18.0, 18.0), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weapon_fire_tween.chain().tween_property(current_weapon_model, "position", rest_pos, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.parallel().tween_property(current_weapon_model, "rotation_degrees", rest_rot, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weapon_fire_tween.parallel().tween_property(current_weapon_model, "scale", rest_scale, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _request_scope_zoom(use_debounce: bool) -> void:
	if use_debounce:
		var now := Time.get_ticks_msec()
		if now - _last_scope_toggle_msec < SCOPE_TOGGLE_DEBOUNCE_MSEC:
			return
		_last_scope_toggle_msec = now
	_cycle_scope_zoom()

func _cycle_scope_zoom() -> void:
	if weapon_system == null or weapon_system.get_current_weapon_id() == "knife":
		_reset_scope_zoom()
		return
	_scope_index = (_scope_index + 1) % SCOPE_ZOOM_LEVELS.size()
	_target_fov = BASE_CAMERA_FOV / float(SCOPE_ZOOM_LEVELS[_scope_index])
	player_scope_changed.emit(_scope_index > 0, weapon_system.get_current_weapon_id())

func _reset_scope_zoom() -> void:
	_scope_index = 0
	_target_fov = BASE_CAMERA_FOV
	player_scope_changed.emit(false, weapon_system.get_current_weapon_id() if weapon_system != null else "")

func _update_scope_zoom(delta: float) -> void:
	if camera == null:
		return
	if weapon_system != null and weapon_system.get_current_weapon_id() == "knife":
		_reset_scope_zoom()
	camera.fov = lerpf(camera.fov, _target_fov, clampf(delta * 12.0, 0.0, 1.0))

func _throw_grenade() -> void:
	if camera == null:
		return
	if _grenades_remaining <= 0:
		return
	if _grenade_timer > 0.0:
		return
	var grenade := GRENADE_PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(grenade)
	var direction := -camera.global_transform.basis.z
	var launch_pos := camera.global_position + direction * 0.85 + Vector3(0, -0.16, 0)
	grenade.global_position = launch_pos
	grenade.setup_arc(direction, self, enemy_team, GRENADE_DAMAGE, GRENADE_RADIUS * _grenade_radius_multiplier, GRENADE_SPEED, GRENADE_RANGE, GRENADE_ARC_LIFT)
	_grenade_radius_multiplier = 1.0
	SoundManager.play_shot("rpg", launch_pos, true)
	_grenades_remaining -= 1
	_grenade_timer = GRENADE_COOLDOWN

func _update_grenade_cooldown(delta: float) -> void:
	_grenade_timer = maxf(0.0, _grenade_timer - delta)

func _apply_weapon_bob(delta: float) -> void:
	if weapon_holder == null:
		return
	var speed_xz := Vector2(velocity.x, velocity.z).length()
	var moving := speed_xz > 0.5 and is_on_floor()
	if moving:
		_bob_time += delta * 9.0
	else:
		_bob_time = move_toward(_bob_time, round(_bob_time / PI) * PI, delta * 6.0)
	var bob_sin := sin(_bob_time)
	if moving and _bob_prev_sin < 0.0 and bob_sin >= 0.0:
		SoundManager.play_footstep()
	_bob_prev_sin = bob_sin
	var bob_y := bob_sin * 0.018
	var bob_x := cos(_bob_time * 0.5) * 0.009
	weapon_holder.position = Vector3(0.38 + bob_x, -0.24 + bob_y - _jump_kick * 0.08, -0.72 - _jump_kick * 0.11)

func _apply_movement(delta: float) -> void:
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		_try_jump()
	else:
		if is_on_floor() and velocity.y <= 0.0:
			_air_jumps_used = 0
			if not _jump_started:
				_jump_started = false
	if not is_on_floor() and Input.is_action_just_pressed("jump"):
		_try_jump()
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if mobile_move.length() > 0.05:
		input_dir = mobile_move
	if input_dir.length() > 0.01:
		tutorial_action.emit("move")
		var move_speed := SPEED * _speed_multiplier * (PRONE_SPEED_MULTIPLIER if _is_prone else 1.0)
		var fwd_mul  := 1.0 if input_dir.y < 0.0 else 0.5
		var side_mul := 0.75
		var fwd_component  := global_transform.basis.z * input_dir.y * move_speed * fwd_mul
		var side_component := global_transform.basis.x * input_dir.x * move_speed * side_mul
		var move_vec := fwd_component + side_component
		velocity.x = move_vec.x
		velocity.z = move_vec.z
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	if is_on_floor() and velocity.y <= 0.0 and _jump_started:
		_jump_started = false
		_air_jumps_used = 0

func _try_jump() -> void:
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if is_on_floor() and not _jump_started:
		velocity.y = sqrt(2.0 * gravity * JUMP_HEIGHT)
		_air_jumps_used = 0
		_jump_started = true
		_play_jump_motion(false)
		tutorial_action.emit("jump")
	elif not is_on_floor() and _air_jumps_used < 1:
		velocity.y = sqrt(2.0 * gravity * SECOND_JUMP_HEIGHT)
		_air_jumps_used += 1
		_jump_started = true
		_play_jump_motion(true)
		tutorial_action.emit("jump")

func apply_grenade_knockback(up_velocity: float) -> void:
	velocity.y = maxf(velocity.y, up_velocity)
	_jump_started = true
	_air_jumps_used = 1
	_play_jump_motion(true)

func _start_laser_tower_build() -> bool:
	if match_manager == null or not is_on_floor() or _laser_build_locked or _laser_tower_built_this_round:
		return false
	var build_pos := global_position + (-global_transform.basis.z * 1.8)
	var ground_pos := _get_valid_laser_tower_ground_position(build_pos)
	if ground_pos == Vector3.INF:
		return false
	build_pos = ground_pos
	_laser_build_locked = true
	mobile_move = Vector2.ZERO
	mobile_fire_down = false
	velocity = Vector3.ZERO
	get_tree().create_timer(_laser_build_seconds).timeout.connect(func() -> void:
		_laser_build_locked = false
		if _dead or match_manager == null or match_manager.match_over:
			return
		if match_manager.has_method("build_laser_tower"):
			match_manager.build_laser_tower(build_pos, team, _laser_bonus_targets)
			_laser_tower_built_this_round = true
	)
	return true

func _get_valid_laser_tower_ground_position(build_pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		build_pos + Vector3.UP * LASER_TOWER_GROUND_RAY_HEIGHT,
		build_pos - Vector3.UP * LASER_TOWER_GROUND_RAY_DEPTH
	)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return Vector3.INF
	var collider := hit.get("collider") as Node
	if collider == null or collider.name != "Ground":
		return Vector3.INF
	return hit.get("position")

func _set_prone(active: bool) -> void:
	_is_prone = active
	if _body_capsule != null:
		_body_capsule.height = PRONE_BODY_HEIGHT if _is_prone else STANDING_BODY_HEIGHT
	if _collision_shape != null:
		_collision_shape.position.y = (PRONE_BODY_HEIGHT if _is_prone else STANDING_BODY_HEIGHT) * 0.5
	if camera != null:
		camera.position.y = PRONE_CAMERA_Y if _is_prone else STANDING_CAMERA_Y

func _apply_look(relative_x: float, relative_y: float) -> void:
	var sensitivity: float = GameSettings.mouse_sensitivity
	rotate_y(deg_to_rad(-relative_x * sensitivity))
	_pitch = clampf(_pitch - deg_to_rad(relative_y * sensitivity), deg_to_rad(-82), deg_to_rad(82))

func _build_body() -> void:
	if has_node("CollisionShape3D"):
		return
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = STANDING_BODY_HEIGHT
	collision.shape = capsule
	collision.position.y = STANDING_BODY_HEIGHT * 0.5
	add_child(collision)
	_collision_shape = collision
	_body_capsule = capsule

	var body_model := ModelFactory.create_soldier_model(team)
	body_model.name = "BodyModel"
	body_model.visible = false
	add_child(body_model)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, STANDING_CAMERA_Y, 0)
	camera.fov = BASE_CAMERA_FOV
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
	weapon_system.weapon_fired.connect(_on_weapon_fired)
	weapon_system.reload_started.connect(_on_reload_started)
	weapon_system.damage_dealt.connect(_on_damage_dealt)
	add_child(weapon_system)
	call_deferred("_refresh_weapon_model")

func _refresh_weapon_model() -> void:
	if weapon_holder == null or weapon_system == null:
		return
	var weapon_id := weapon_system.get_current_weapon_id()
	if current_weapon_model != null and current_weapon_model.name == "WeaponModel_%s" % weapon_id:
		return
	_reset_scope_zoom()
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
		_weapon_switch_tween.tween_property(old_model, "position", old_model.position + Vector3(-0.16, -0.42, 0.26), 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_property(old_model, "rotation_degrees", old_model.rotation_degrees + Vector3(18.0, 34.0, -14.0), 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_property(old_model, "scale", old_model.scale * 0.82, 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_weapon_switch_tween.tween_callback(_queue_free_if_valid.bind(old_model)).set_delay(0.12)
	new_model.position = Vector3(0.18, -0.38, 0.22)
	new_model.rotation_degrees = base_rotation + Vector3(22.0, -42.0, 18.0)
	new_model.scale = base_scale * 0.86
	_weapon_switch_tween.tween_property(new_model, "position", Vector3.ZERO, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(new_model, "rotation_degrees", base_rotation, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(new_model, "scale", base_scale, WEAPON_SWITCH_ANIM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_jump_motion(second_jump: bool) -> void:
	if _jump_motion_tween != null and _jump_motion_tween.is_valid():
		_jump_motion_tween.kill()
	_jump_kick = 1.0 if second_jump else 0.72
	if camera != null:
		camera.fov = minf(BASE_CAMERA_FOV + (5.0 if second_jump else 3.0), BASE_CAMERA_FOV + 5.0)
	_jump_motion_tween = create_tween()
	_jump_motion_tween.set_parallel(true)
	_jump_motion_tween.tween_property(self, "_jump_kick", 0.0, 0.34 if second_jump else 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if camera != null:
		_jump_motion_tween.tween_property(camera, "fov", _target_fov, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
	_reset_first_person_state_for_spectate()
	var targets := match_manager.get_spectate_targets()
	if targets.is_empty():
		return
	_spectating = true
	_spectate_index = 0
	_set_spectate_target(targets[0])
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
	_reset_first_person_state_for_spectate()
	if _spectate_hidden_target != null and is_instance_valid(_spectate_hidden_target) and _spectate_hidden_target.has_method("set_spectate_hidden"):
		_spectate_hidden_target.set_spectate_hidden(false)
	_spectate_target = new_target
	_spectate_hidden_target = null
	if _spectate_target != null and is_instance_valid(_spectate_target) and _spectate_target.has_method("set_spectate_hidden"):
		_spectate_target.set_spectate_hidden(false)
		_spectate_hidden_target = _spectate_target

func _get_spectate_name() -> String:
	if match_manager == null or _spectate_target == null:
		return ""
	var team_str := str(_spectate_target.get_meta("team", "blue"))
	if _spectate_target is AIController:
		return "%s BOT #%d" % [team_str.to_upper(), _spectate_target.bot_index]
	return "%s PLAYER" % team_str.to_upper()

func _follow_spectate_target(delta: float) -> void:
	if _spectate_target == null or not is_instance_valid(_spectate_target):
		spectate_next()
		return
	var target_health: Health = null
	if _spectate_target.has_method("get_health"):
		target_health = _spectate_target.get_health()
	elif _spectate_target.has_node("Health"):
		target_health = _spectate_target.get_node("Health")
	if target_health != null and not target_health.is_alive:
		spectate_next()
		return
	var head_offset := Vector3(0, 2.35, 2.8)
	var target_pos := _spectate_target.global_position + (_spectate_target.global_transform.basis.z * head_offset.z) + Vector3(0, head_offset.y, 0)
	camera.global_position = camera.global_position.lerp(target_pos, clampf(8.0 * delta, 0.0, 1.0))
	var look_target := _spectate_target.global_position + Vector3(0, 1.35, 0)
	camera.look_at(look_target, Vector3.UP)
	camera.fov = lerpf(camera.fov, BASE_CAMERA_FOV, clampf(10.0 * delta, 0.0, 1.0))

func _reset_first_person_state_for_spectate() -> void:
	_reset_scope_zoom()
	_set_prone(false)
	_jump_kick = 0.0
	if _jump_motion_tween != null and _jump_motion_tween.is_valid():
		_jump_motion_tween.kill()
	if camera != null:
		camera.fov = BASE_CAMERA_FOV
	if weapon_holder != null:
		weapon_holder.position = Vector3(0.38, -0.24, -0.72)

func _on_player_kill_effect(kill_pos: Vector3, victim_name: String) -> void:
	if match_manager != null and match_manager.hud != null and match_manager.hud.has_method("show_kill_banner"):
		match_manager.hud.show_kill_banner("你", victim_name)
	var ke := KillEffect.new()
	get_tree().current_scene.add_child(ke)
	ke.setup(kill_pos)

func _on_damage_dealt(amount: float, hit_position: Vector3) -> void:
	var dn := DamageNumber.new()
	get_tree().current_scene.add_child(dn)
	dn.setup(amount, hit_position)
