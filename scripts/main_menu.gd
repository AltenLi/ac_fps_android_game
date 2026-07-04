extends Control

const COLOR_BG := Color(0.055, 0.06, 0.08, 1.0)
const COLOR_PANEL := Color(0.12, 0.105, 0.08, 0.72)
const COLOR_ACCENT := Color(0.85, 0.54, 0.14, 1.0)
const COLOR_TEXT := Color(0.96, 0.93, 0.87, 1.0)
const TUTORIAL_STEPS := [
	{
		"title": "1. 任务目标",
		"body": "你加入蓝队，和 4 名队友 AI 对战 5 名橙队 AI。5 分钟内尽量消灭敌人；任意一方全灭会提前结算。",
	},
	{
		"title": "2. 移动与瞄准",
		"body": "桌面端使用 WASD 移动、鼠标瞄准。手机端使用左侧浮动摇杆移动，在非按键区域滑动即可转动视角。",
	},
	{
		"title": "3. 射击、装弹与切枪",
		"body": "桌面端左键射击、R 装弹、1/2/3 或 Q 切枪。手机端右下角依次是跳跃、换枪、开火；左上偏下也有开火键，方便边开火边调视角。",
	},
	{
		"title": "4. 武器定位",
		"body": "M416 适合连续压制；巴雷特适合远距离高伤点杀；战术匕首适合近身快速收割。",
	},
	{
		"title": "5. 星星与地图",
		"body": "胜利获得星星，MVP 奖励更多星星，每日也可领取奖励。星星用于解锁更多地图，前三张地图可直接游玩。",
	},
]

var _tutorial_overlay: Control
var _tutorial_title_label: Label
var _tutorial_body_label: Label
var _tutorial_back_button: Button
var _tutorial_next_button: Button
var _tutorial_step_index := 0
var _daily_overlay: Control

func _ready() -> void:
	SoundManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	## macOS needs one deferred pass after the window gains focus.
	call_deferred("_ensure_mouse_visible")
	_build_ui()
	if not PlayerData.tutorial_completed:
		call_deferred("_show_tutorial", true)

func _notification(what: int) -> void:
	## Keep the cursor visible when the menu regains focus.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ensure_mouse_visible() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_ui() -> void:
	var is_mobile := _is_mobile_layout()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG
	add_child(bg)

	var skyline := Control.new()
	skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(skyline)
	_draw_skyline(skyline)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 28 if is_mobile else 90)
	shell.add_theme_constant_override("margin_right", 82 if is_mobile else 90)
	shell.add_theme_constant_override("margin_top", 32 if is_mobile else 54)
	shell.add_theme_constant_override("margin_bottom", 26 if is_mobile else 42)
	add_child(shell)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14 if is_mobile else 18)
	shell.add_child(root)

	var hero_panel := PanelContainer.new()
	hero_panel.custom_minimum_size = Vector2(0 if is_mobile else 560, 0)
	hero_panel.add_theme_stylebox_override("panel", _button_style(Color(0.08, 0.075, 0.065, 0.58), Color(0.62, 0.42, 0.18, 0.7)))
	root.add_child(hero_panel)

	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 20 if is_mobile else 34)
	hero_margin.add_theme_constant_override("margin_right", 20 if is_mobile else 34)
	hero_margin.add_theme_constant_override("margin_top", 20 if is_mobile else 30)
	hero_margin.add_theme_constant_override("margin_bottom", 20 if is_mobile else 30)
	hero_panel.add_child(hero_margin)

	var hero := VBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 12 if is_mobile else 16)
	hero_margin.add_child(hero)

	var title := Label.new()
	title.text = "CS 5v5"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 50 if is_mobile else 62)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	hero.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "5v5 真实枪战 · 星星解锁地图"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20 if is_mobile else 23)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.8, 0.68, 1.0))
	hero.add_child(subtitle)

	var star_label := Label.new()
	star_label.text = "星星 %d" % PlayerData.total_stars
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 24)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
	hero.add_child(star_label)

	var start_button := _make_button("开始游戏", true)
	start_button.custom_minimum_size = Vector2(300 if is_mobile else 360, 60 if is_mobile else 64)
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/map_select.tscn")
	)
	hero.add_child(start_button)

	var quick_row := HBoxContainer.new()
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	quick_row.add_theme_constant_override("separation", 10)
	hero.add_child(quick_row)

	var tutorial_button := _make_small_button("教程")
	tutorial_button.custom_minimum_size = Vector2(112, 46)
	tutorial_button.pressed.connect(_show_tutorial)
	quick_row.add_child(tutorial_button)

	var settings_button := _make_small_button("设置")
	settings_button.custom_minimum_size = Vector2(112, 46)
	settings_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
	)
	quick_row.add_child(settings_button)

	var daily_hint := Label.new()
	daily_hint.text = "每日奖励 / 每日任务已收纳到右侧按钮"
	daily_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_hint.add_theme_font_size_override("font_size", 17 if is_mobile else 19)
	daily_hint.add_theme_color_override("font_color", Color(0.74, 0.70, 0.62, 1.0))
	hero.add_child(daily_hint)

	var hint := Label.new()
	hint.text = "手机：左摇杆移动 · 滑动瞄准 · 右下/左上开火 · 跳跃/换枪" if is_mobile else "桌面：WASD 移动 · 鼠标瞄准 · 左键射击 · R 装弹 · Q 切枪"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17 if is_mobile else 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62, 1.0))
	root.add_child(hint)

	_build_side_actions(star_label)

func _is_mobile_layout() -> bool:
	var viewport_size := get_viewport_rect().size
	return OS.has_feature("android") or OS.has_feature("ios") or viewport_size.x < 900.0 or viewport_size.y < 620.0

func _build_side_actions(star_label: Label) -> void:
	var rail := VBoxContainer.new()
	rail.name = "SideDailyActions"
	rail.anchor_left = 1.0
	rail.anchor_right = 1.0
	rail.anchor_top = 0.5
	rail.anchor_bottom = 0.5
	rail.offset_left = -72
	rail.offset_right = -10
	rail.offset_top = -72
	rail.offset_bottom = 72
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 10)
	add_child(rail)

	var daily_button := _make_edge_button("每日")
	daily_button.tooltip_text = "每日奖励 / 每日任务"
	daily_button.pressed.connect(func() -> void:
		_show_daily_hub(star_label)
	)
	rail.add_child(daily_button)

func _show_daily_hub(star_label: Label) -> void:
	if is_instance_valid(_daily_overlay):
		_daily_overlay.queue_free()
	_daily_overlay = Control.new()
	_daily_overlay.name = "DailyHubOverlay"
	_daily_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_daily_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_daily_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.56)
	_daily_overlay.add_child(dim)

	var is_mobile := _is_mobile_layout()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18 if is_mobile else 240)
	margin.add_theme_constant_override("margin_right", 18 if is_mobile else 240)
	margin.add_theme_constant_override("margin_top", 58 if is_mobile else 86)
	margin.add_theme_constant_override("margin_bottom", 58 if is_mobile else 86)
	_daily_overlay.add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.10, 0.09, 0.075, 0.97), COLOR_ACCENT))
	margin.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title := Label.new()
	title.text = "每日补给"
	title.custom_minimum_size = Vector2(210, 34)
	title.add_theme_font_size_override("font_size", 28 if is_mobile else 32)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	header.add_child(title)

	var close_button := _make_small_button("关闭")
	close_button.custom_minimum_size = Vector2(96, 44)
	close_button.pressed.connect(_close_daily_hub)
	header.add_child(close_button)

	var reward_button := _make_button("领取每日奖励 +%d 星星" % PlayerData.DAILY_REWARD_STARS, true)
	reward_button.custom_minimum_size = Vector2(320 if is_mobile else 380, 56)
	reward_button.disabled = not PlayerData.can_claim_daily_reward()
	if reward_button.disabled:
		reward_button.text = "今日奖励已领取"
	reward_button.pressed.connect(func() -> void:
		var gained := PlayerData.claim_daily_reward()
		if gained > 0:
			star_label.text = "星星 %d" % PlayerData.total_stars
		_show_daily_hub(star_label)
	)
	content.add_child(reward_button)

	content.add_child(_build_daily_tasks_panel(star_label))

func _close_daily_hub() -> void:
	if is_instance_valid(_daily_overlay):
		_daily_overlay.queue_free()
	_daily_overlay = null

func _build_daily_tasks_panel(star_label: Label) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320 if _is_mobile_layout() else 560, 0)
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.08, 0.075, 0.065, 0.76), Color(0.42, 0.31, 0.16, 0.9)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	_refresh_daily_tasks_panel(content, star_label)
	return panel

func _refresh_daily_tasks_panel(content: VBoxContainer, star_label: Label) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var title := Label.new()
	title.text = "每日任务"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1.0))
	content.add_child(title)

	for task: Dictionary in PlayerData.get_daily_tasks():
		content.add_child(_make_daily_task_row(task, content, star_label))

func _make_daily_task_row(task: Dictionary, content: VBoxContainer, star_label: Label) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)

	var is_mobile := _is_mobile_layout()
	var task_title := Label.new()
	task_title.text = str(task.get("title", "每日任务"))
	task_title.custom_minimum_size = Vector2(170 if is_mobile else 260, 32)
	task_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	task_title.add_theme_font_size_override("font_size", 17 if is_mobile else 19)
	task_title.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(task_title)

	var progress := int(task.get("progress", 0))
	var target := int(task.get("target", 1))
	var reward := int(task.get("reward", 0))
	var progress_label := Label.new()
	progress_label.text = "%d/%d +%d 星星" % [progress, target, reward]
	progress_label.custom_minimum_size = Vector2(104 if is_mobile else 132, 32)
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 17 if is_mobile else 19)
	progress_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72, 1.0))
	row.add_child(progress_label)

	var claim_button := _make_small_button("领取")
	claim_button.custom_minimum_size = Vector2(92 if is_mobile else 108, 40)
	var task_id := str(task.get("id", ""))
	var claimed := bool(task.get("claimed", false))
	var completed := bool(task.get("completed", false))
	claim_button.disabled = claimed or not completed
	if claimed:
		claim_button.text = "已领取"
	elif not completed:
		claim_button.text = "进行中"
	claim_button.pressed.connect(func() -> void:
		var gained := PlayerData.claim_daily_task(task_id)
		if gained > 0:
			star_label.text = "星星 %d" % PlayerData.total_stars
			_refresh_daily_tasks_panel(content, star_label)
	)
	row.add_child(claim_button)
	return row

func _show_tutorial(first_run: bool = false) -> void:
	_close_daily_hub()
	if is_instance_valid(_tutorial_overlay):
		_tutorial_overlay.queue_free()
	_tutorial_step_index = 0

	_tutorial_overlay = Control.new()
	_tutorial_overlay.name = "FirstRunTutorial" if first_run else "TutorialOverlay"
	_tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_tutorial_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	_tutorial_overlay.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 240)
	margin.add_theme_constant_override("margin_right", 240)
	margin.add_theme_constant_override("margin_top", 92)
	margin.add_theme_constant_override("margin_bottom", 92)
	_tutorial_overlay.add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _button_style(Color(0.10, 0.09, 0.075, 0.96), COLOR_ACCENT))
	margin.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 22)
	panel.add_child(content)

	var header := Label.new()
	header.text = "首次作战简报" if first_run else "新手教程"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 38)
	header.add_theme_color_override("font_color", COLOR_TEXT)
	content.add_child(header)

	_tutorial_title_label = Label.new()
	_tutorial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_title_label.add_theme_font_size_override("font_size", 30)
	_tutorial_title_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.32, 1.0))
	content.add_child(_tutorial_title_label)

	_tutorial_body_label = Label.new()
	_tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_body_label.add_theme_font_size_override("font_size", 24)
	_tutorial_body_label.add_theme_color_override("font_color", Color(0.91, 0.87, 0.78, 1.0))
	content.add_child(_tutorial_body_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	var skip_button := _make_button("璺宠繃", false)
	skip_button.custom_minimum_size = Vector2(176, 58)
	skip_button.pressed.connect(_finish_tutorial)
	buttons.add_child(skip_button)

	_tutorial_back_button = _make_button("上一步", false)
	_tutorial_back_button.custom_minimum_size = Vector2(176, 58)
	_tutorial_back_button.pressed.connect(func() -> void:
		_set_tutorial_step(_tutorial_step_index - 1)
	)
	buttons.add_child(_tutorial_back_button)

	_tutorial_next_button = _make_button("下一步", true)
	_tutorial_next_button.custom_minimum_size = Vector2(196, 58)
	_tutorial_next_button.pressed.connect(func() -> void:
		if _tutorial_step_index >= TUTORIAL_STEPS.size() - 1:
			_finish_tutorial()
		else:
			_set_tutorial_step(_tutorial_step_index + 1)
	)
	buttons.add_child(_tutorial_next_button)

	_set_tutorial_step(0)

func _set_tutorial_step(index: int) -> void:
	_tutorial_step_index = maxi(0, mini(index, TUTORIAL_STEPS.size() - 1))
	var step := TUTORIAL_STEPS[_tutorial_step_index] as Dictionary
	_tutorial_title_label.text = "%s  (%d/%d)" % [str(step["title"]), _tutorial_step_index + 1, TUTORIAL_STEPS.size()]
	_tutorial_body_label.text = str(step["body"])
	_tutorial_back_button.disabled = _tutorial_step_index == 0
	_tutorial_next_button.text = "开始作战" if _tutorial_step_index >= TUTORIAL_STEPS.size() - 1 else "下一步"

func _finish_tutorial() -> void:
	PlayerData.mark_tutorial_completed(true)
	if is_instance_valid(_tutorial_overlay):
		_tutorial_overlay.queue_free()

func _draw_skyline(parent: Control) -> void:
	for i in range(18):
		var block := ColorRect.new()
		block.color = Color(0.22, 0.17, 0.11, 0.38)
		block.anchor_left = float(i) / 18.0
		block.anchor_right = float(i + 1) / 18.0
		block.anchor_top = 0.55 + 0.08 * sin(float(i) * 1.7)
		block.anchor_bottom = 1.0
		block.offset_left = 4
		block.offset_right = -4
		parent.add_child(block)

func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 64)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(COLOR_ACCENT if primary else COLOR_PANEL, COLOR_ACCENT))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.66, 0.2, 1.0), Color(1.0, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.52, 0.31, 0.09, 1.0), COLOR_ACCENT))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.10, 0.10, 0.11, 0.75), Color(0.35, 0.32, 0.28, 0.8)))
	return button

func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(108, 42)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.18, 0.14, 0.08, 0.9), COLOR_ACCENT))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.72, 0.43, 0.12, 1.0), Color(1.0, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.42, 0.25, 0.08, 1.0), COLOR_ACCENT))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.10, 0.10, 0.11, 0.65), Color(0.35, 0.32, 0.28, 0.7)))
	return button

func _make_edge_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(72, 72)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.18, 0.13, 0.07, 0.94), COLOR_ACCENT))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.78, 0.46, 0.13, 1.0), Color(1.0, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.42, 0.25, 0.08, 1.0), COLOR_ACCENT))
	return button

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	return style
