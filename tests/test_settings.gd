extends RefCounted

const TEST_SAVE_PATH := "user://settings_test.cfg"

func run(t) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", 2.0)
	cfg.set_value("controls", "mouse_sensitivity", 99.0)
	cfg.set_value("video", "quality_mode", "ultra")
	cfg.set_value("game", "selected_map_id", "missing")
	cfg.set_value("game", "bot_difficulty", "nightmare")
	cfg.save(TEST_SAVE_PATH)

	var script := load("res://scripts/settings.gd")
	var settings = script.new()
	settings.set_save_path_for_tests(TEST_SAVE_PATH)
	settings.load_settings()

	t.equal(settings.master_volume, 1.0, "音量应被 clamp 到 1.0")
	t.equal(settings.mouse_sensitivity, 0.6, "灵敏度应被 clamp 到 0.6")
	t.equal(settings.quality_mode, "balanced", "非法画质应回退 balanced")
	t.equal(settings.selected_map_id, MapRegistry.DEFAULT_MAP_ID, "非法地图应回退默认地图")
	t.equal(settings.bot_difficulty, "easy", "非法难度应回退 easy")
	settings.set_selected_map("volcano")
	t.equal(settings.selected_map_id, "volcano", "合法地图应可设置")
	settings.set_bot_difficulty("hard")
	t.equal(settings.bot_difficulty, "hard", "合法难度应可设置")
