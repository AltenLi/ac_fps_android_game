extends Node

## 玩家进度数据（跨场景持久化）
## 注册为 Autoload，名称 PlayerData

const SAVE_PATH := "user://player_data.cfg"
const DAILY_REWARD_STARS := 2
const DAILY_TASK_DEFS := [
	{
		"id": "daily_kills",
		"title": "今日击杀 3 人",
		"target": 3,
		"reward": 1,
	},
	{
		"id": "daily_win",
		"title": "赢得 1 局比赛",
		"target": 1,
		"reward": 2,
	},
	{
		"id": "daily_battle_stars",
		"title": "战斗获得 2 星",
		"target": 2,
		"reward": 1,
	},
]

var save_path := SAVE_PATH
var total_stars: int = 0
var total_kills: int = 0
var total_deaths: int = 0
var purchased_maps: Array[String] = []
var last_daily_reward_date := ""
var daily_task_date := ""
var daily_task_progress: Dictionary = {}
var claimed_daily_tasks: Array[String] = []
var tutorial_completed := false
var ads_removed := false

func _ready() -> void:
	_load()

func set_save_path_for_tests(path: String) -> void:
	save_path = path

func reset_progress() -> void:
	total_stars = 0
	total_kills = 0
	total_deaths = 0
	purchased_maps.clear()
	last_daily_reward_date = ""
	daily_task_date = ""
	daily_task_progress.clear()
	claimed_daily_tasks.clear()
	tutorial_completed = false
	ads_removed = false
	_save()

## 增加星星并立即保存。
func add_stars(count: int) -> void:
	if count <= 0:
		return
	total_stars = maxi(0, total_stars + count)
	_save()

## 添加本局战绩到累计数据。
func add_match_stats(kills: int, deaths: int) -> void:
	total_kills = maxi(0, total_kills + maxi(0, kills))
	total_deaths = maxi(0, total_deaths + maxi(0, deaths))
	_save()

func has_map(map_id: String) -> bool:
	if not MapRegistry.is_valid_map_id(map_id):
		return false
	if MapRegistry.is_free_map(map_id):
		return true
	return map_id in purchased_maps

## 星星解锁地图。保留 purchase_map 兼容旧调用，但 UI 文案应使用“解锁”。
func unlock_map(map_id: String) -> bool:
	if not MapRegistry.is_valid_map_id(map_id):
		return false
	if has_map(map_id):
		return true
	var cost := MapRegistry.get_cost(map_id)
	if total_stars < cost:
		return false
	total_stars -= cost
	if not (map_id in purchased_maps):
		purchased_maps.append(map_id)
	_save()
	return true

func purchase_map(map_id: String) -> bool:
	return unlock_map(map_id)

func can_claim_daily_reward() -> bool:
	return last_daily_reward_date != _today_string()

func claim_daily_reward() -> int:
	if not can_claim_daily_reward():
		return 0
	last_daily_reward_date = _today_string()
	add_stars(DAILY_REWARD_STARS)
	return DAILY_REWARD_STARS

func get_daily_tasks() -> Array[Dictionary]:
	_ensure_daily_tasks()
	var tasks: Array[Dictionary] = []
	for task_def: Dictionary in DAILY_TASK_DEFS:
		var task_id := str(task_def.get("id", ""))
		var target := int(task_def.get("target", 0))
		var progress := mini(target, maxi(0, int(daily_task_progress.get(task_id, 0))))
		tasks.append({
			"id": task_id,
			"title": str(task_def.get("title", task_id)),
			"target": target,
			"progress": progress,
			"reward": int(task_def.get("reward", 0)),
			"completed": progress >= target,
			"claimed": task_id in claimed_daily_tasks,
		})
	return tasks

func record_match_for_daily_tasks(kills: int, won: bool, stars_earned: int) -> void:
	_ensure_daily_tasks()
	_add_daily_task_progress("daily_kills", kills)
	if won:
		_add_daily_task_progress("daily_win", 1)
	_add_daily_task_progress("daily_battle_stars", stars_earned)
	_save()

func can_claim_daily_task(task_id: String) -> bool:
	_ensure_daily_tasks()
	var task_def := _get_daily_task_def(task_id)
	if task_def.is_empty() or task_id in claimed_daily_tasks:
		return false
	return int(daily_task_progress.get(task_id, 0)) >= int(task_def.get("target", 0))

func claim_daily_task(task_id: String) -> int:
	if not can_claim_daily_task(task_id):
		return 0
	var task_def := _get_daily_task_def(task_id)
	var reward := int(task_def.get("reward", 0))
	claimed_daily_tasks.append(task_id)
	add_stars(reward)
	return reward

func mark_tutorial_completed(value: bool = true) -> void:
	tutorial_completed = value
	_save()

func has_removed_ads() -> bool:
	return ads_removed

func set_ads_removed(value: bool) -> void:
	ads_removed = value
	_save()

func _ensure_daily_tasks() -> void:
	var today := _today_string()
	if daily_task_date != today:
		daily_task_date = today
		daily_task_progress.clear()
		claimed_daily_tasks.clear()
		for task_def: Dictionary in DAILY_TASK_DEFS:
			daily_task_progress[str(task_def.get("id", ""))] = 0
		_save()
		return

	var changed := false
	for task_def: Dictionary in DAILY_TASK_DEFS:
		var task_id := str(task_def.get("id", ""))
		var target := int(task_def.get("target", 0))
		var progress := mini(target, maxi(0, int(daily_task_progress.get(task_id, 0))))
		if not daily_task_progress.has(task_id) or int(daily_task_progress.get(task_id, 0)) != progress:
			daily_task_progress[task_id] = progress
			changed = true
	for key: Variant in daily_task_progress.keys():
		var task_id := str(key)
		if not _is_valid_daily_task_id(task_id):
			daily_task_progress.erase(key)
			changed = true
	var valid_claimed: Array[String] = []
	for task_id: String in claimed_daily_tasks:
		if _is_valid_daily_task_id(task_id) and not (task_id in valid_claimed):
			valid_claimed.append(task_id)
	if valid_claimed.size() != claimed_daily_tasks.size():
		claimed_daily_tasks = valid_claimed
		changed = true
	if changed:
		_save()

func _add_daily_task_progress(task_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var task_def := _get_daily_task_def(task_id)
	if task_def.is_empty():
		return
	var target := int(task_def.get("target", 0))
	var current := int(daily_task_progress.get(task_id, 0))
	daily_task_progress[task_id] = mini(target, current + amount)

func _get_daily_task_def(task_id: String) -> Dictionary:
	for task_def: Dictionary in DAILY_TASK_DEFS:
		if str(task_def.get("id", "")) == task_id:
			return task_def
	return {}

func _is_valid_daily_task_id(task_id: String) -> bool:
	return not _get_daily_task_def(task_id).is_empty()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_stars", maxi(0, total_stars))
	cfg.set_value("progress", "total_kills", maxi(0, total_kills))
	cfg.set_value("progress", "total_deaths", maxi(0, total_deaths))
	cfg.set_value("progress", "purchased_maps", purchased_maps)
	cfg.set_value("retention", "last_daily_reward_date", last_daily_reward_date)
	cfg.set_value("retention", "daily_task_date", daily_task_date)
	cfg.set_value("retention", "daily_task_progress", daily_task_progress)
	cfg.set_value("retention", "claimed_daily_tasks", claimed_daily_tasks)
	cfg.set_value("retention", "tutorial_completed", tutorial_completed)
	cfg.set_value("commercial", "ads_removed", ads_removed)
	cfg.save(save_path)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	total_stars = maxi(0, int(cfg.get_value("progress", "total_stars", 0)))
	total_kills = maxi(0, int(cfg.get_value("progress", "total_kills", 0)))
	total_deaths = maxi(0, int(cfg.get_value("progress", "total_deaths", 0)))
	last_daily_reward_date = str(cfg.get_value("retention", "last_daily_reward_date", ""))
	daily_task_date = str(cfg.get_value("retention", "daily_task_date", ""))
	daily_task_progress.clear()
	var loaded_progress: Variant = cfg.get_value("retention", "daily_task_progress", {})
	if loaded_progress is Dictionary:
		var progress_dict: Dictionary = loaded_progress
		for task_def: Dictionary in DAILY_TASK_DEFS:
			var task_id := str(task_def.get("id", ""))
			var target := int(task_def.get("target", 0))
			daily_task_progress[task_id] = mini(target, maxi(0, int(progress_dict.get(task_id, 0))))
	claimed_daily_tasks.clear()
	var loaded_claimed: Variant = cfg.get_value("retention", "claimed_daily_tasks", [])
	if loaded_claimed is Array:
		for task_id_value: Variant in loaded_claimed:
			var task_id := str(task_id_value)
			if _is_valid_daily_task_id(task_id) and not (task_id in claimed_daily_tasks):
				claimed_daily_tasks.append(task_id)
	tutorial_completed = bool(cfg.get_value("retention", "tutorial_completed", false))
	ads_removed = bool(cfg.get_value("commercial", "ads_removed", false))
	var loaded_maps: Variant = cfg.get_value("progress", "purchased_maps", [])
	purchased_maps.clear()
	for m: Variant in loaded_maps:
		var map_id := str(m)
		if MapRegistry.is_valid_map_id(map_id) and not MapRegistry.is_free_map(map_id) and not (map_id in purchased_maps):
			purchased_maps.append(map_id)

func _today_string() -> String:
	return Time.get_date_string_from_system(false)
