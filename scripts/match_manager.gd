class_name MatchManager
extends Node3D

const ROUND_TIME := 300.0
const CITY_MAP_SCENE := preload("res://scenes/city_map.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const AI_SCENE := preload("res://scenes/ai_bot.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const MOBILE_CONTROLS_SCENE := preload("res://scenes/mobile_controls.tscn")

var remaining_time := ROUND_TIME
var match_over := false
var combatants: Array[Node3D] = []
var kills := {"blue": 0, "orange": 0}
var player: PlayerController
var hud: CanvasLayer
var city_map: Node3D
var patrol_points: Array[Vector3] = []

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
	city_map = CITY_MAP_SCENE.instantiate()
	add_child(city_map)
	patrol_points = city_map.get_patrol_points()

	var blue_spawns: Array[Vector3] = city_map.get_spawn_points("blue")
	var orange_spawns: Array[Vector3] = city_map.get_spawn_points("orange")

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
		_register_combatant(bot, "blue")

	for i in range(5):
		var enemy := AI_SCENE.instantiate() as AIController
		add_child(enemy)
		enemy.global_position = orange_spawns[i]
		enemy.setup(self, "orange", i + 5)
		_register_combatant(enemy, "orange")

	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	if hud.has_method("bind_manager"):
		hud.bind_manager(self)

	var mobile := MOBILE_CONTROLS_SCENE.instantiate() as CanvasLayer
	add_child(mobile)
	if mobile.has_method("bind_player"):
		mobile.bind_player(player)

func _register_combatant(unit: Node3D, unit_team: String) -> void:
	unit.set_meta("team", unit_team)
	combatants.append(unit)
	var health := _get_health(unit)
	if health != null:
		health.died.connect(_on_unit_died.bind(unit, unit_team))

func _on_unit_died(killer: Node, _weapon_id: String, unit: Node3D, unit_team: String) -> void:
	if killer != null and killer.has_meta("team"):
		var killer_team := str(killer.get_meta("team"))
		if killer_team != unit_team and kills.has(killer_team):
			kills[killer_team] += 1
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var blue_left := get_living_count("blue")
	var orange_left := get_living_count("orange")
	var title := "平局"
	if blue_left > orange_left:
		title = "胜利"
	elif orange_left > blue_left:
		title = "失败"
	if hud != null and hud.has_method("show_result"):
		hud.show_result(title, reason, blue_left, orange_left, int(kills["blue"]))

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

func get_patrol_point(index: int) -> Vector3:
	if patrol_points.is_empty():
		return Vector3.ZERO
	return patrol_points[index % patrol_points.size()]

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

func _get_health(unit: Node) -> Health:
	if unit == null:
		return null
	if unit.has_method("get_health"):
		return unit.get_health() as Health
	if unit.has_node("Health"):
		return unit.get_node("Health") as Health
	return null
