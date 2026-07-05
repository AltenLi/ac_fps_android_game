extends Node

signal settings_changed

const MAP_REGISTRY := preload("res://scripts/map_registry.gd")
const SAVE_PATH := "user://settings.cfg"
const VALID_QUALITY_MODES: Array[String] = ["performance", "balanced", "quality", "ultra"]
const VALID_BOT_DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const VALID_CHARACTER_IDS: Array[String] = ["assault", "sniper", "engineer", "medic"]

var save_path := SAVE_PATH
var master_volume := 0.8
var mouse_sensitivity := 0.18
var quality_mode := "balanced"
var selected_map_id := "city"
var selected_character_id := "assault"
var tutorial_mode := false
## bot 难度："easy" / "normal" / "hard"，默认简单
var bot_difficulty := "easy"

func _ready() -> void:
	load_settings()
	apply_settings()

func set_save_path_for_tests(path: String) -> void:
	save_path = path

func set_selected_map(map_id: String) -> void:
	selected_map_id = map_id if MAP_REGISTRY.is_valid_map_id(map_id) else MAP_REGISTRY.DEFAULT_MAP_ID
	save_settings()

func set_bot_difficulty(value: String) -> void:
	bot_difficulty = value if value in VALID_BOT_DIFFICULTIES else "easy"
	save_settings()

func set_selected_character(value: String) -> void:
	selected_character_id = value if value in VALID_CHARACTER_IDS else "assault"
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
	quality_mode = value if value in VALID_QUALITY_MODES else "balanced"
	apply_settings()
	save_settings()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(max(master_volume, 0.001)))
	var scaling := 1.0
	if quality_mode == "performance":
		scaling = 0.82
	elif quality_mode == "quality":
		scaling = 1.0
	elif quality_mode == "ultra":
		scaling = 1.12
	var viewport := get_viewport()
	if viewport != null:
		viewport.scaling_3d_scale = scaling
		if quality_mode == "ultra":
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			viewport.use_taa = _supports_taa()
		elif quality_mode == "quality":
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			viewport.use_taa = false
		else:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.use_taa = false
	settings_changed.emit()

func _supports_taa() -> bool:
	var renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	return renderer == "forward_plus"

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("video", "quality_mode", quality_mode)
	config.set_value("game", "selected_map_id", selected_map_id)
	config.set_value("game", "bot_difficulty", bot_difficulty)
	config.set_value("game", "selected_character_id", selected_character_id)
	config.save(save_path)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	mouse_sensitivity = clampf(float(config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)), 0.05, 0.6)
	var loaded_quality := str(config.get_value("video", "quality_mode", quality_mode))
	quality_mode = loaded_quality if loaded_quality in VALID_QUALITY_MODES else "balanced"
	var loaded_map := str(config.get_value("game", "selected_map_id", selected_map_id))
	selected_map_id = loaded_map if MAP_REGISTRY.is_valid_map_id(loaded_map) else MAP_REGISTRY.DEFAULT_MAP_ID
	var loaded_difficulty := str(config.get_value("game", "bot_difficulty", bot_difficulty))
	bot_difficulty = loaded_difficulty if loaded_difficulty in VALID_BOT_DIFFICULTIES else "easy"
	var loaded_character := str(config.get_value("game", "selected_character_id", selected_character_id))
	selected_character_id = loaded_character if loaded_character in VALID_CHARACTER_IDS else "assault"
