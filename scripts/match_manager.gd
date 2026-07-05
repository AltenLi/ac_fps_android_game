class_name MatchManager
extends Node3D

const ROUND_TIME := 300.0
const AMMO_DROP_COUNT := 8
const AMMO_RESPAWN_SECONDS := 28.0
const SPAWN_RESUPPLY_SECONDS := 5.0
const SPAWN_RESUPPLY_RADIUS := 5.2
const NAV_CONNECT_DISTANCE := 34.0
const NAV_MAX_CONNECTIONS := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const AI_SCENE := preload("res://scenes/ai_bot.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const MOBILE_CONTROLS_SCENE := preload("res://scenes/mobile_controls.tscn")
const LASER_TOWER_SCRIPT := preload("res://scripts/laser_tower.gd")
const TACTICAL_CHIP_SCRIPT := preload("res://scripts/tactical_chip.gd")

signal player_kill_effect(kill_position: Vector3, victim_name: String)

var remaining_time := ROUND_TIME
var match_over := false
var combatants: Array[Node3D] = []
var kills := {"blue": 0, "orange": 0}
var player: PlayerController
var hud: CanvasLayer
var city_map: Node3D
var current_map_id := MapRegistry.DEFAULT_MAP_ID
var patrol_points: Array[Vector3] = []
var ammo_drop_positions: Array[Vector3] = []
var ammo_drop_root: Node3D
var spawn_resupply_centers := {}
var _resupply_progress := {}
var defense_structures: Array[Node3D] = []
var tactical_chip_root: Node3D
var _map_low_gravity := false
var navigation_graph := AStar3D.new()
var navigation_points: Array[Vector3] = []
var tutorial_mode := false
var _tutorial_step_index := 0
var _loading_overlay: CanvasLayer
var _match_loaded := false
const TUTORIAL_ACTION_STEPS := [
	{"action": "move", "text": "教学 1/8：拖动左摇杆移动"},
	{"action": "look", "text": "教学 2/8：在空白区域滑动，转动视角"},
	{"action": "fire", "text": "教学 3/8：按开火键射击"},
	{"action": "switch", "text": "教学 4/8：按换枪键切换武器"},
	{"action": "jump", "text": "教学 5/8：按跳跃键，再在空中按一次二段跳"},
	{"action": "grenade", "text": "教学 6/8：按手雷键投掷手雷"},
	{"action": "tower", "text": "教学 7/8：在地面按塔键搭建激光塔；每局只能搭一次，30 秒后发射"},
	{"action": "fire", "text": "教学 8/8：首页右侧可打开成就列表；雪原基地全歼敌人可解锁西蒙海耶"},
]
## 独立追踪玩家击杀数（用于MVP判断）
var player_kills: int = 0
## 追踪所有 bot 中的最高击杀数（用于MVP判断）
var _bot_kill_counts: Dictionary = {}
## 追踪每个单位本局死亡次数（键为 instance_id）
var _unit_deaths: Dictionary = {}

func _ready() -> void:
	randomize()
	_show_loading_overlay()
	_build_match_after_loading_screen()

func _physics_process(delta: float) -> void:
	if not _match_loaded or match_over:
		return
	remaining_time = maxf(0.0, remaining_time - delta)
	_update_spawn_resupply(delta)
	_update_map_hazards(delta)
	if remaining_time <= 0.0:
		finish_match("时间到")

func _show_loading_overlay() -> void:
	_loading_overlay = CanvasLayer.new()
	_loading_overlay.name = "LoadingMapOverlay"
	_loading_overlay.layer = 100
	add_child(_loading_overlay)

	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.02, 0.025, 0.035, 1.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_overlay.add_child(blocker)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(560, 150)
	center.offset_left = -280
	center.offset_top = -75
	center.offset_right = 280
	center.offset_bottom = 75
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 14)
	blocker.add_child(center)

	var label := Label.new()
	label.text = "正在加载地图"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1.0))
	center.add_child(label)

	var hint := Label.new()
	hint.text = "准备战场资源"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(0.58, 0.78, 1.0, 1.0))
	center.add_child(hint)

func _build_match_after_loading_screen() -> void:
	await get_tree().process_frame
	_build_match()
	_match_loaded = true
	await get_tree().process_frame
	if _loading_overlay != null:
		_loading_overlay.queue_free()
		_loading_overlay = null

func _build_match() -> void:
	tutorial_mode = GameSettings.tutorial_mode
	## 根据 GameSettings 中的选择动态加载地图场景，坏配置回退默认地图。
	current_map_id = GameSettings.selected_map_id if MapRegistry.is_valid_map_id(GameSettings.selected_map_id) else MapRegistry.DEFAULT_MAP_ID
	var map_scene_path := MapRegistry.get_scene_path(current_map_id)
	var map_scene := load(map_scene_path) as PackedScene
	if map_scene == null:
		current_map_id = MapRegistry.DEFAULT_MAP_ID
		map_scene_path = MapRegistry.get_scene_path(MapRegistry.DEFAULT_MAP_ID)
		map_scene = load(map_scene_path) as PackedScene
	city_map = map_scene.instantiate()
	add_child(city_map)
	patrol_points = city_map.get_patrol_points()
	_prepare_ammo_drop_positions()

	var blue_spawns: Array[Vector3] = city_map.get_spawn_points("blue")
	var orange_spawns: Array[Vector3] = city_map.get_spawn_points("orange")
	spawn_resupply_centers["blue"] = _average_spawn_center(blue_spawns)
	spawn_resupply_centers["orange"] = _average_spawn_center(orange_spawns)
	_build_spawn_resupply_circle("blue", spawn_resupply_centers["blue"])
	_build_spawn_resupply_circle("orange", spawn_resupply_centers["orange"])
	_build_navigation_graph(blue_spawns, orange_spawns)

	player = PLAYER_SCENE.instantiate() as PlayerController
	add_child(player)
	player.global_position = blue_spawns[0]
	player.setup(self, "blue")
	player.apply_character_profile(GameSettings.selected_character_id)
	player.apply_map_weapon_rules(_get_map_allowed_weapons(current_map_id))
	_register_combatant(player, "blue")

	for i in range(4):
		var bot := AI_SCENE.instantiate() as AIController
		add_child(bot)
		bot.global_position = blue_spawns[i + 1]
		bot.setup(self, "blue", i + 1)
		bot.set_battle_plan(get_battle_plan_route("blue", i + 1, bot.global_position))
		_register_combatant(bot, "blue")

	for i in range(5):
		var enemy := AI_SCENE.instantiate() as AIController
		add_child(enemy)
		enemy.global_position = orange_spawns[i]
		enemy.setup(self, "orange", i + 5)
		enemy.set_battle_plan(get_battle_plan_route("orange", i + 5, enemy.global_position))
		_register_combatant(enemy, "orange")

	_spawn_initial_ammo_drops()
	_apply_map_rules()
	_spawn_tactical_chips()

	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	if hud.has_method("bind_manager"):
		hud.bind_manager(self)
	if tutorial_mode:
		_start_playable_tutorial()

	var mobile := MOBILE_CONTROLS_SCENE.instantiate() as CanvasLayer
	add_child(mobile)
	if mobile.has_method("bind_player"):
		mobile.bind_player(player)

	SoundManager.play_combat_music()

func _start_playable_tutorial() -> void:
	if player != null:
		player.tutorial_action.connect(_on_tutorial_action)
	_show_tutorial_step()

func _on_tutorial_action(action: String) -> void:
	if not tutorial_mode or match_over:
		return
	var step: Dictionary = TUTORIAL_ACTION_STEPS[_tutorial_step_index]
	if action != str(step["action"]):
		return
	_tutorial_step_index += 1
	if _tutorial_step_index >= TUTORIAL_ACTION_STEPS.size():
		_complete_playable_tutorial()
	else:
		_show_tutorial_step()

func _show_tutorial_step() -> void:
	if hud == null or not hud.has_method("show_tutorial_objective"):
		return
	var step: Dictionary = TUTORIAL_ACTION_STEPS[_tutorial_step_index]
	hud.show_tutorial_objective(str(step["text"]))

func _complete_playable_tutorial() -> void:
	tutorial_mode = false
	GameSettings.tutorial_mode = false
	PlayerData.mark_tutorial_completed(true)
	if hud != null and hud.has_method("show_tutorial_objective"):
		hud.show_tutorial_objective("教学完成：准备进入正式作战")
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		return_to_main_menu()
	)

func _register_combatant(unit: Node3D, unit_team: String) -> void:
	unit.set_meta("team", unit_team)
	combatants.append(unit)
	_resupply_progress[unit.get_instance_id()] = 0.0
	var health := _get_health(unit)
	if health != null:
		health.died.connect(_on_unit_died.bind(unit, unit_team))

func _on_unit_died(killer: Node, _weapon_id: String, unit: Node3D, unit_team: String) -> void:
	## 记录死亡
	var unit_id := unit.get_instance_id()
	_unit_deaths[unit_id] = _unit_deaths.get(unit_id, 0) + 1
	if killer != null and killer.has_meta("team"):
		var killer_team := str(killer.get_meta("team"))
		if killer_team != unit_team and kills.has(killer_team):
			kills[killer_team] += 1
		## 分别追踪玩家击杀和 bot 击杀
		if killer == player:
			player_kills += 1
			## 发出击杀特效信号（带击杀位置和被击杀者名称）
			var kill_pos := unit.global_position if unit is Node3D else Vector3.ZERO
			var victim_name := _get_unit_display_name(unit, unit_team)
			player_kill_effect.emit(kill_pos, victim_name)
		elif killer != null:
			var bot_id := killer.get_instance_id()
			_bot_kill_counts[bot_id] = _bot_kill_counts.get(bot_id, 0) + 1
	_check_elimination()

func _check_elimination() -> void:
	if get_living_count("blue") <= 0:
		finish_match("蓝队全灭")
	elif get_living_count("orange") <= 0:
		finish_match("橙队全灭")

func finish_match(reason: String) -> void:
	if match_over:
		return
	GameSettings.tutorial_mode = false
	match_over = true
	SoundManager.stop_bgm()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var blue_left := get_living_count("blue")
	var orange_left := get_living_count("orange")
	var title := "平局"
	if blue_left > orange_left:
		title = "胜利"
		SoundManager.play_victory()
	elif orange_left > blue_left:
		title = "失败"
		SoundManager.play_defeat()
	## 计算星星：胜利+1，MVP额外+1
	var stars_earned := 0
	if title == "胜利":
		stars_earned = 1
		## MVP判断：玩家击杀数 >= 所有bot中的最高击杀数
		var bot_max := 0
		for count in _bot_kill_counts.values():
			bot_max = maxi(bot_max, int(count))
		if player_kills > 0 and player_kills >= bot_max:
			stars_earned = 2
		PlayerData.add_stars(stars_earned)
	## 记录玩家本局战绩与每日任务进度
	var player_deaths: int = _unit_deaths.get(player.get_instance_id(), 0) if player != null else 0
	PlayerData.add_match_stats(player_kills, player_deaths)
	PlayerData.record_match_for_daily_tasks(player_kills, title == "胜利", stars_earned)
	## 构建参战者战绩列表（供结算界面使用）
	var combatant_stats: Array[Dictionary] = []
	for unit: Node3D in combatants:
		var unit_team: String = str(unit.get_meta("team", "blue"))
		var uid := unit.get_instance_id()
		var kills_this: int = player_kills if unit == player else _bot_kill_counts.get(uid, 0)
		var deaths_this: int = _unit_deaths.get(uid, 0)
		combatant_stats.append({
			"name": _get_unit_display_name(unit, unit_team),
			"team": unit_team,
			"is_player": unit == player,
			"kills": kills_this,
			"deaths": deaths_this,
		})
	if hud != null and hud.has_method("show_result"):
		hud.show_result(title, reason, blue_left, orange_left, player_kills, stars_earned, combatant_stats)
	_check_snow_ace_achievement(orange_left)

func _check_snow_ace_achievement(orange_left: int) -> void:
	if current_map_id != "snow" or orange_left > 0 or player_kills < 5:
		return
	var message := "解锁成就：西蒙海耶"
	print(message)
	PlayerData.unlock_achievement("simo_hayha")
	if hud != null and hud.has_method("show_achievement"):
		hud.show_achievement(message)

## 返回当前存活的蓝队队友列表（排除已死亡玩家），供观战系统使用
func get_spectate_targets() -> Array[Node3D]:
	var targets: Array[Node3D] = []
	for unit in combatants:
		if unit == player:
			continue
		if str(unit.get_meta("team", "")) != "blue":
			continue
		var health := _get_health(unit)
		if health != null and health.is_alive:
			targets.append(unit)
	return targets

func get_living_count(team: String) -> int:
	var count := 0
	for unit in combatants:
		if str(unit.get_meta("team", "")) != team:
			continue
		var health := _get_health(unit)
		if health != null and health.is_alive:
			count += 1
	return count

func get_closest_enemy(team: String, requester: Node3D) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for unit in combatants:
		if unit == requester or str(unit.get_meta("team", "")) == team:
			continue
		var health := _get_health(unit)
		if health == null or not health.is_alive:
			continue
		var dist := requester.global_position.distance_squared_to(unit.global_position)
		if dist < best_dist:
			best_dist = dist
			best = unit
	if team == "orange":
		for structure in defense_structures:
			if structure == null or not is_instance_valid(structure):
				continue
			var structure_health := _get_health(structure)
			if structure_health == null or not structure_health.is_alive:
				continue
			var structure_dist := requester.global_position.distance_squared_to(structure.global_position)
			if structure_dist < best_dist:
				best_dist = structure_dist
				best = structure
	return best

func build_laser_tower(pos: Vector3, owner_team: String, bonus_targets: int = 0) -> void:
	if match_over:
		return
	var tower := LaserTower.new()
	add_child(tower)
	tower.global_position = Vector3(pos.x, pos.y, pos.z)
	tower.setup(self, owner_team)
	tower.extra_targets = bonus_targets
	defense_structures.append(tower)

func get_closest_ammo_drop(requester: Node3D) -> AmmoPickup:
	if requester == null or ammo_drop_root == null:
		return null
	var best: AmmoPickup = null
	var best_dist := INF
	for child in ammo_drop_root.get_children():
		var drop := child as AmmoPickup
		if drop == null or not is_instance_valid(drop) or drop.is_queued_for_deletion():
			continue
		var dist := requester.global_position.distance_squared_to(drop.global_position)
		if dist < best_dist:
			best_dist = dist
			best = drop
	return best

func get_battle_plan_route(team: String, bot_index: int, spawn_pos: Vector3) -> Array[Vector3]:
	var route: Array[Vector3] = []
	if patrol_points.is_empty():
		return route
	var forward := -1.0 if team == "blue" else 1.0
	var lane_index := (bot_index % 3) - 1
	var lane_x := float(lane_index) * 18.0
	var frontline_stages := [18.0, 34.0, 50.0] if team == "blue" else [10.0, 24.0, 38.0]
	for stage in frontline_stages:
		var point := _select_plan_point(spawn_pos, lane_x, forward, stage, route)
		if point != Vector3.INF:
			route.append(point)
	if route.is_empty():
		route.append(get_patrol_point(bot_index))
	return route

func _select_plan_point(spawn_pos: Vector3, lane_x: float, forward: float, stage: float, existing: Array[Vector3]) -> Vector3:
	var best := Vector3.INF
	var best_score := INF
	for point in patrol_points:
		var progress := (point.z - spawn_pos.z) * forward
		if progress < -2.0:
			continue
		var duplicate_penalty := 0.0
		for used in existing:
			if point.distance_squared_to(used) < 9.0:
				duplicate_penalty = 999.0
		var score: float = absf(progress - stage) + absf(point.x - lane_x) * 0.55 + duplicate_penalty
		if score < best_score:
			best_score = score
			best = point
	return best

func get_patrol_point(index: int) -> Vector3:
	if patrol_points.is_empty():
		return Vector3.ZERO
	return patrol_points[index % patrol_points.size()]

func get_navigation_path(from_pos: Vector3, to_pos: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = []
	if navigation_graph.get_point_count() <= 0:
		path.append(to_pos)
		return path
	if _has_navigation_line(from_pos, to_pos):
		path.append(to_pos)
		return path
	var start_id := _get_reachable_nav_point_id(from_pos)
	var end_id := _get_reachable_nav_point_id(to_pos)
	if start_id < 0 or end_id < 0:
		path.append(to_pos)
		return path
	var raw_path := navigation_graph.get_point_path(start_id, end_id)
	for point in raw_path:
		path.append(point)
	path.append(to_pos)
	return path

func has_navigation_line(from_pos: Vector3, to_pos: Vector3) -> bool:
	return _has_navigation_line(from_pos, to_pos)

func _build_navigation_graph(blue_spawns: Array[Vector3], orange_spawns: Array[Vector3]) -> void:
	navigation_graph.clear()
	navigation_points.clear()
	var candidates: Array[Vector3] = []
	candidates.append_array(patrol_points)
	candidates.append_array(blue_spawns)
	candidates.append_array(orange_spawns)
	candidates.append_array(ammo_drop_positions)
	for point in candidates:
		_add_navigation_point(point)
	_connect_navigation_points()


func _add_navigation_point(point: Vector3) -> void:
	for existing in navigation_points:
		if existing.distance_squared_to(point) < 2.25:
			return
	var id := navigation_points.size()
	navigation_points.append(point)
	navigation_graph.add_point(id, point)

func _connect_navigation_points() -> void:
	for i in range(navigation_points.size()):
		var links: Array[Dictionary] = []
		for j in range(navigation_points.size()):
			if i == j:
				continue
			var dist := navigation_points[i].distance_to(navigation_points[j])
			if dist > NAV_CONNECT_DISTANCE:
				continue
			if not _has_navigation_line(navigation_points[i], navigation_points[j]):
				continue
			links.append({"id": j, "dist": dist})
		links.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["dist"]) < float(b["dist"])
		)
		for k in range(mini(NAV_MAX_CONNECTIONS, links.size())):
			var target_id := int(links[k]["id"])
			if not navigation_graph.are_points_connected(i, target_id):
				navigation_graph.connect_points(i, target_id, false)

func _get_reachable_nav_point_id(pos: Vector3) -> int:
	var best_id := -1
	var best_dist := INF
	for i in range(navigation_points.size()):
		var dist := pos.distance_squared_to(navigation_points[i])
		if dist >= best_dist:
			continue
		if not _has_navigation_line(pos, navigation_points[i]):
			continue
		best_dist = dist
		best_id = i
	if best_id >= 0:
		return best_id
	return navigation_graph.get_closest_point(pos)

func _has_navigation_line(from_pos: Vector3, to_pos: Vector3) -> bool:
	if city_map == null or get_world_3d() == null:
		return true
	var a := Vector3(from_pos.x, 1.25, from_pos.z)
	var b := Vector3(to_pos.x, 1.25, to_pos.z)
	var query := PhysicsRayQueryParameters3D.create(a, b)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == null or collider == city_map or city_map.is_ancestor_of(collider) == false

func get_player_health() -> Health:
	return _get_health(player)

func get_current_weapon_name() -> String:
	if player == null or player.weapon_system == null:
		return "无武器"
	return player.weapon_system.get_current_weapon_name()

func restart_match() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func return_to_map_select() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _prepare_ammo_drop_positions() -> void:
	ammo_drop_positions = [
		Vector3(-18, 1.0, 13), Vector3(-7, 1.0, 18), Vector3(9, 1.0, 16), Vector3(20, 1.0, 6),
		Vector3(18, 1.0, -13), Vector3(7, 1.0, -18), Vector3(-9, 1.0, -16), Vector3(-20, 1.0, -6),
		Vector3(0, 1.0, 28), Vector3(0, 1.0, -28), Vector3(-31, 1.0, 0), Vector3(31, 1.0, 0)
	]
	ammo_drop_positions.shuffle()

func _spawn_initial_ammo_drops() -> void:
	ammo_drop_root = Node3D.new()
	ammo_drop_root.name = "AmmoDrops"
	add_child(ammo_drop_root)
	for i in range(mini(AMMO_DROP_COUNT, ammo_drop_positions.size())):
		_spawn_ammo_drop(ammo_drop_positions[i])

func _spawn_ammo_drop(pos: Vector3) -> void:
	if ammo_drop_root == null or match_over:
		return
	var drop := AmmoPickup.new()
	drop.picked_up.connect(_on_ammo_drop_picked)
	ammo_drop_root.add_child(drop)
	drop.global_position = pos

func _on_ammo_drop_picked(drop: AmmoPickup, pickup_unit: Node3D) -> void:
	collect_ammo_drop(drop, pickup_unit)

func collect_ammo_drop(drop: AmmoPickup, pickup_unit: Node3D) -> void:
	if match_over or drop == null or not is_instance_valid(drop) or drop.is_queued_for_deletion():
		return
	var unit_weapon_system := _get_weapon_system(pickup_unit)
	if unit_weapon_system == null:
		return
	if unit_weapon_system.add_two_magazines_to_all():
		SoundManager.play_pickup()
		var pos := drop.global_position
		drop.queue_free()
		_respawn_ammo_later(pos)

func _average_spawn_center(spawns: Array[Vector3]) -> Vector3:
	if spawns.is_empty():
		return Vector3.ZERO
	var total := Vector3.ZERO
	for pos in spawns:
		total += pos
	total /= float(spawns.size())
	total.y = 0.12
	return total

func _build_spawn_resupply_circle(team_id: String, center: Vector3) -> void:
	var root := Node3D.new()
	root.name = "ResupplyCircle_%s" % team_id
	root.position = center
	add_child(root)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = SPAWN_RESUPPLY_RADIUS - 0.16
	ring_mesh.outer_radius = SPAWN_RESUPPLY_RADIUS
	ring_mesh.rings = 48
	ring_mesh.ring_segments = 12
	var ring := MeshInstance3D.new()
	ring.name = "BlueResupplyRing"
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.58, 1.0, 0.78)
	mat.emission_enabled = true
	mat.emission = Color(0.12, 0.58, 1.0, 1)
	mat.emission_energy_multiplier = 1.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	root.add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = Color(0.18, 0.62, 1.0, 1)
	light.light_energy = 0.42
	light.omni_range = SPAWN_RESUPPLY_RADIUS * 1.9
	light.position.y = 1.2
	root.add_child(light)

func _update_spawn_resupply(delta: float) -> void:
	for unit in combatants:
		if unit == null or not is_instance_valid(unit):
			continue
		var health := _get_health(unit)
		if health == null or not health.is_alive:
			_set_unit_resupply_locked(unit, false)
			continue
		var team_id := str(unit.get_meta("team", ""))
		var center: Vector3 = spawn_resupply_centers.get(team_id, Vector3.INF)
		var unit_id := unit.get_instance_id()
		if center == Vector3.INF or not _needs_spawn_resupply(unit) or unit.global_position.distance_to(center) > SPAWN_RESUPPLY_RADIUS:
			_resupply_progress[unit_id] = 0.0
			_set_unit_resupply_locked(unit, false)
			continue
		_resupply_progress[unit_id] = float(_resupply_progress.get(unit_id, 0.0)) + delta
		_set_unit_resupply_locked(unit, true)
		if float(_resupply_progress[unit_id]) >= _get_resupply_seconds(unit):
			_restore_unit_round_start(unit)
			_resupply_progress[unit_id] = 0.0
			_set_unit_resupply_locked(unit, false)

func _needs_spawn_resupply(unit: Node3D) -> bool:
	if unit.has_method("has_full_round_supplies") and not unit.has_full_round_supplies():
		return true
	var health := _get_health(unit)
	return health != null and (health.current_health < health.max_health or health.shield < health.max_shield)

func _restore_unit_round_start(unit: Node3D) -> void:
	if unit.has_method("reset_supplies_to_round_start"):
		unit.reset_supplies_to_round_start()
	var health := _get_health(unit)
	if health != null:
		health.reset(str(unit.get_meta("team", "neutral")), health.max_health, health.max_shield)
	SoundManager.play_pickup()

func _apply_map_rules() -> void:
	_map_low_gravity = current_map_id == "space"
	if _map_low_gravity:
		ProjectSettings.set_setting("physics/3d/default_gravity", 6.2)
	else:
		ProjectSettings.set_setting("physics/3d/default_gravity", 9.8)

func _update_map_hazards(delta: float) -> void:
	if current_map_id != "volcano":
		return
	for unit in combatants:
		if unit == null or not is_instance_valid(unit):
			continue
		if int(absf(unit.global_position.x) + absf(unit.global_position.z)) % 17 > 3:
			continue
		var health := _get_health(unit)
		if health != null and health.is_alive:
			health.apply_damage(4.0 * delta, null, "lava")

func _get_map_allowed_weapons(map_id: String) -> Array[String]:
	match map_id:
		"cave", "ruins":
			return ["barrett", "knife"]
		"factory", "harbor":
			return ["m416", "knife"]
		"snow":
			return ["barrett", "m416", "knife"]
	return []

func _spawn_tactical_chips() -> void:
	tactical_chip_root = Node3D.new()
	tactical_chip_root.name = "TacticalChips"
	add_child(tactical_chip_root)
	var chip_ids := ["grenade_boost", "speed_boost", "tower_boost"]
	for i in range(mini(3, ammo_drop_positions.size())):
		var chip := TacticalChip.new()
		chip.setup(chip_ids[i % chip_ids.size()])
		chip.picked.connect(_on_tactical_chip_picked)
		tactical_chip_root.add_child(chip)
		chip.global_position = ammo_drop_positions[ammo_drop_positions.size() - 1 - i] + Vector3(0, 0.55, 0)

func _on_tactical_chip_picked(chip: TacticalChip, collector: Node3D) -> void:
	if chip == null or not is_instance_valid(chip) or chip.is_queued_for_deletion():
		return
	if collector != player:
		return
	player.apply_tactical_chip(chip.chip_id)
	SoundManager.play_pickup()
	chip.queue_free()

func _set_unit_resupply_locked(unit: Node3D, locked: bool) -> void:
	if unit.has_method("set_resupply_locked"):
		unit.set_resupply_locked(locked)

func _get_resupply_seconds(unit: Node3D) -> float:
	if unit == player and GameSettings.selected_character_id == "medic":
		return 3.0
	return SPAWN_RESUPPLY_SECONDS

func _respawn_ammo_later(old_pos: Vector3) -> void:
	var timer := get_tree().create_timer(AMMO_RESPAWN_SECONDS)
	timer.timeout.connect(func() -> void:
		if match_over:
			return
		var pos: Vector3 = ammo_drop_positions.pick_random() as Vector3 if not ammo_drop_positions.is_empty() else old_pos
		_spawn_ammo_drop(pos)
	)

func _get_health(unit: Node) -> Health:
	if unit == null:
		return null
	if unit.has_method("get_health"):
		return unit.get_health() as Health
	if unit.has_node("Health"):
		return unit.get_node("Health") as Health
	return null

func _get_weapon_system(unit: Node) -> WeaponSystem:
	if unit == null:
		return null
	if unit.has_node("WeaponSystem"):
		return unit.get_node("WeaponSystem") as WeaponSystem
	return null

func _get_unit_display_name(unit: Node3D, unit_team: String) -> String:
	var team_str := "蓝队" if unit_team == "blue" else "橙队"
	if unit is AIController:
		return "%s#%d" % [team_str, unit.bot_index]
	return team_str + "玩家"
