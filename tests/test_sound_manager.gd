extends RefCounted

func run(t) -> void:
	var text := FileAccess.get_file_as_string("res://scripts/sound_manager.gd")
	t.is_true(text.contains("const ENABLE_ANDROID_BGM := false"), "Android 应默认关闭程序化循环 BGM，优先避免 AudioTrack 原生崩溃")
	t.is_true(text.contains("var _stream_cache: Dictionary = {}"), "固定音效应缓存复用，避免频繁创建/释放音频流")
	t.is_true(text.contains("func _get_cached_stream(key: String)"), "应存在统一音效缓存入口")
	t.is_true(text.contains("if player.playing:"), "复用音效播放器前应检查播放状态")
	t.is_true(text.contains("player.stop()"), "复用音效播放器前应停止旧流，避免替换播放中的 AudioStream")
	t.is_true(text.contains("OS.has_feature(\"android\") and not ENABLE_ANDROID_BGM"), "Android BGM 开关应在 play_bgm 中生效")
	t.is_true(text.contains("const ENABLE_FOOTSTEP_SFX := false"), "脚步音默认应关闭，避免移动时叠加蜂鸣")
	t.is_true(text.contains("EMPTY_CLICK_MIN_INTERVAL_MSEC"), "空仓音效应限频，避免长按没子弹时蜂鸣")
	t.is_true(text.contains("if now - _last_empty_click_msec < EMPTY_CLICK_MIN_INTERVAL_MSEC"), "空仓音效限频逻辑应生效")
	t.is_true(text.contains("去掉高频纯音避免蜂鸣"), "空仓音效应移除高频纯音")
	t.is_true(text.contains("去掉叮叮纯音"), "拾取音效应移除蜂鸣式纯音")
	t.is_true(text.contains("wav.loop_mode = AudioStreamWAV.LOOP_DISABLED"), "短音效默认不应循环")
