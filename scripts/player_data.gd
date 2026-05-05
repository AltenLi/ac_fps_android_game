extends Node

## 玩家进度数据（跨场景持久化）
## 注册为 Autoload，名称 PlayerData

const SAVE_PATH := "user://player_data.cfg"

## 前三张地图永久免费，无需购买
const FREE_MAPS: Array[String] = ["city", "desert", "snow"]

var total_stars: int = 0
var total_kills: int = 0
var total_deaths: int = 0
var purchased_maps: Array[String] = []

func _ready() -> void:
	_load()

## 增加星星并立即保存
func add_stars(count: int) -> void:
	if count <= 0:
		return
	total_stars += count
	_save()

## 添加本局战绩到累计数据
func add_match_stats(kills: int, deaths: int) -> void:
	total_kills += kills
	total_deaths += deaths
	_save()

## 是否拥有某张地图（免费地图或已购买）
func has_map(map_id: String) -> bool:
	if map_id in FREE_MAPS:
		return true
	return map_id in purchased_maps

## 购买地图（消耗10颗星，返回是否购买成功）
func purchase_map(map_id: String) -> bool:
	if has_map(map_id):
		return true
	if total_stars < 10:
		return false
	total_stars -= 10
	purchased_maps.append(map_id)
	_save()
	return true

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_stars", total_stars)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "total_deaths", total_deaths)
	cfg.set_value("progress", "purchased_maps", purchased_maps)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	total_stars = int(cfg.get_value("progress", "total_stars", 0))
	total_kills = int(cfg.get_value("progress", "total_kills", 0))
	total_deaths = int(cfg.get_value("progress", "total_deaths", 0))
	var loaded_maps: Variant = cfg.get_value("progress", "purchased_maps", [])
	purchased_maps.clear()
	for m: Variant in loaded_maps:
		purchased_maps.append(str(m))
