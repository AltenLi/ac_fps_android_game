extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

var master_volume := 0.8
var mouse_sensitivity := 0.18
var quality_mode := "balanced"
var selected_map_id := "city"
## bot 难度："easy" / "normal" / "hard"，默认简单
var bot_difficulty := "easy"

func _ready() -> void:
	load_settings()
	apply_settings()

func set_selected_map(map_id: String) -> void:
	selected_map_id = map_id
	save_settings()

func set_bot_difficulty(value: String) -> void:
	bot_difficulty = value
	save_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_settings()

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.05, 0.6)
	save_settings()
	settings_changed.emit()

func set_quality_mode(value: String) -> void:
	quality_mode = value
	apply_settings()
	save_settings()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(max(master_volume, 0.001)))
	var scaling := 1.0
	if quality_mode == "performance":
		scaling = 0.82
	elif quality_mode == "quality":
		scaling = 1.0
	get_viewport().scaling_3d_scale = scaling
	settings_changed.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("video", "quality_mode", quality_mode)
	config.set_value("game", "selected_map_id", selected_map_id)
	config.set_value("game", "bot_difficulty", bot_difficulty)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	master_volume = float(config.get_value("audio", "master_volume", master_volume))
	mouse_sensitivity = float(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity))
	quality_mode = str(config.get_value("video", "quality_mode", quality_mode))
	selected_map_id = str(config.get_value("game", "selected_map_id", selected_map_id))
	bot_difficulty = str(config.get_value("game", "bot_difficulty", bot_difficulty))
