class_name MatchManager
extends Node3D

const ROUND_TIME := 300.0
const AMMO_DROP_COUNT := 8
const AMMO_RESPAWN_SECONDS := 28.0
const NAV_CONNECT_DISTANCE := 34.0
const NAV_MAX_CONNECTIONS := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const AI_SCENE := preload("res://scenes/ai_bot.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const MOBILE_CONTROLS_SCENE := preload("res://scenes/mobile_controls.tscn")

signal player_kill_effect(kill_position: Vector3, victim_name: String)

var remaining_time := ROUND_TIME
var match_over := false
var combatants: Array[Node3D] = []
var kills := {"blue": 0, "orange": 0}
var player: PlayerController
var hud: CanvasLayer
var city_map: Node3D
var patrol_points: Array[Vector3] = []
var ammo_drop_positions: Array[Vector3] = []
var ammo_drop_root: Node3D
var navigation_graph := AStar3D.new()
var navigation_points: Array[Vector3] = []
## 独立追踪玩家击杀数（用于MVP判断）
var player_kills: int = 0
## 追踪所有 bot 中的最高击杀数（用于MVP判断）
var _bot_kill_counts: Dictionary = {}
## 追踪每个单位本局死亡次数（键为 instance_id）
var _unit_deaths: Dictionary = {}

func _ready() -> void:
	randomize()
	_build_match()

func _physics_process(delta: float) -> void:
	if match_over:
		return
	remaining_time = maxf(0.0, remaining_time - delta)
	if remaining_time <= 0.0:
		finish_match("时间到")

func _build_match() -> void:
	## 根据 GameSettings 中的选择动态加载地图场景，坏配置回退默认地图。
	var selected_map := GameSettings.selected_map_id if MapRegistry.is_valid_map_id(GameSettings.selected_map_id) else MapRegistry.DEFAULT_MAP_ID
	var map_scene_path := MapRegistry.get_scene_path(selected_map)
	var map_scene := load(map_scene_path) as PackedScene
	if map_scene == null:
		map_scene_path = MapRegistry.get_scene_path(MapRegistry.DEFAULT_MAP_ID)
		map_scene = load(map_scene_path) as PackedScene
	city_map = map_scene.instantiate()
	add_child(city_map)
	patrol_points = city_map.get_patrol_points()
	_prepare_ammo_drop_positions()

	var blue_spawns: Array[Vector3] = city_map.get_spawn_points("blue")
	var orange_spawns: Array[Vector3] = city_map.get_spawn_points("orange")
	_build_navigation_graph(blue_spawns, orange_spawns)

	player = PLAYER_SCENE.instantiate() as PlayerController
	add_child(player)
	player.global_position = blue_spawns[0]
	player.setup(self, "blue")
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

	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	if hud.has_method("bind_manager"):
		hud.bind_manager(self)

	var mobile := MOBILE_CONTROLS_SCENE.instantiate() as CanvasLayer
	add_child(mobile)
	if mobile.has_method("bind_player"):
		mobile.bind_player(player)

	SoundManager.play_combat_music()

func _register_combatant(unit: Node3D, unit_team: String) -> void:
	unit.set_meta("team", unit_team)
	combatants.append(unit)
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
	return best

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
	for stage in [10.0, 24.0, 38.0]:
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
	drop.global_position = pos
	drop.picked_up.connect(_on_ammo_drop_picked)
	ammo_drop_root.add_child(drop)

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
