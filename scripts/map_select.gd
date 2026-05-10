extends Control

## 地图选择界面：11张地图卡片网格（每行4张）

const MAP_REGISTRY := preload("res://scripts/map_registry.gd")

var _selected_index := 0
var _selected_difficulty := "easy"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	call_deferred("_ensure_mouse_visible")
	for i in range(MAP_REGISTRY.MAPS.size()):
		if MAP_REGISTRY.MAPS[i]["id"] == GameSettings.selected_map_id:
			_selected_index = i
			break
	_selected_difficulty = GameSettings.bot_difficulty
	_build_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ensure_mouse_visible() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _refresh_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.075, 1)
	add_child(bg)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 60)
	shell.add_theme_constant_override("margin_right", 60)
	shell.add_theme_constant_override("margin_top", 50)
	shell.add_theme_constant_override("margin_bottom", 50)
	add_child(shell)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	shell.add_child(root)

	var title_row := HBoxContainer.new()
	root.add_child(title_row)

	var title := Label.new()
	title.text = "选择地图"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	title_row.add_child(title)

	var star_label := Label.new()
	star_label.text = "⭐ %d" % PlayerData.total_stars
	star_label.add_theme_font_size_override("font_size", 24)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1))
	star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(star_label)

	root.add_child(_make_difficulty_row())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for i in range(MAP_REGISTRY.MAPS.size()):
		grid.add_child(_make_card(i))

	var info_box := HBoxContainer.new()
	info_box.add_theme_constant_override("separation", 18)
	root.add_child(info_box)

	var info_color := ColorRect.new()
	info_color.custom_minimum_size = Vector2(14, 50)
	info_color.color = MAP_REGISTRY.MAPS[_selected_index]["color"]
	info_box.add_child(info_color)

	var info_label := Label.new()
	info_label.text = _info_text(_selected_index)
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("font_size", 17)
	info_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72, 1))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(info_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	root.add_child(buttons)

	var back := _make_button("返回首页", false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	buttons.add_child(back)

	var enter := _make_button("进入比赛", true)
	enter.pressed.connect(func() -> void:
		var map_id := str(MAP_REGISTRY.MAPS[_selected_index]["id"])
		if not PlayerData.has_map(map_id):
			_show_unlock_dialog(_selected_index)
			return
		GameSettings.set_selected_map(map_id)
		GameSettings.set_bot_difficulty(_selected_difficulty)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
	buttons.add_child(enter)

func _make_difficulty_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "电脑难度："
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var difficulties := [
		{"id": "easy", "name": "简单", "color": Color(0.28, 0.78, 0.38)},
		{"id": "normal", "name": "普通", "color": Color(0.88, 0.72, 0.22)},
		{"id": "hard", "name": "困难", "color": Color(0.88, 0.28, 0.22)},
	]

	for d in difficulties:
		var btn := Button.new()
		btn.text = d["name"]
		btn.custom_minimum_size = Vector2(88, 40)
		btn.add_theme_font_size_override("font_size", 17)
		var is_sel: bool = _selected_difficulty == d["id"]
		btn.add_theme_stylebox_override("normal", _diff_style(d["color"], is_sel))
		btn.add_theme_stylebox_override("hover", _diff_style(d["color"], true))
		btn.add_theme_stylebox_override("pressed", _diff_style(d["color"], true))
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1) if is_sel else Color(0.72, 0.70, 0.65, 1))
		var did: String = d["id"]
		btn.pressed.connect(func() -> void:
			_selected_difficulty = did
			_refresh_ui()
		)
		row.add_child(btn)

	return row

func _diff_style(accent: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.95) if selected else Color(0.11, 0.10, 0.09, 0.88)
	style.border_color = accent
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(10)
	return style

func _make_card(index: int) -> Control:
	var data: Dictionary = MAP_REGISTRY.MAPS[index]
	var map_id := str(data["id"])
	var is_locked := not PlayerData.has_map(map_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _card_style(data["color"], index == _selected_index))

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_right", 12)
	inner.add_theme_constant_override("margin_top", 10)
	inner.add_theme_constant_override("margin_bottom", 10)
	card.add_child(inner)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	inner.add_child(col)

	var color_bar := ColorRect.new()
	color_bar.custom_minimum_size = Vector2(1, 32)
	color_bar.color = data["color"] if not is_locked else Color(data["color"].r * 0.4, data["color"].g * 0.4, data["color"].b * 0.4, 1)
	col.add_child(color_bar)

	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.79, 0.45, 1) if index == _selected_index else Color(0.86, 0.82, 0.72, 1))
	col.add_child(name_label)

	if is_locked:
		var overlay := Control.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		var dark := ColorRect.new()
		dark.set_anchors_preset(Control.PRESET_FULL_RECT)
		dark.color = Color(0, 0, 0, 0.62)
		overlay.add_child(dark)
		var lock_col := VBoxContainer.new()
		lock_col.set_anchors_preset(Control.PRESET_CENTER)
		lock_col.add_theme_constant_override("separation", 2)
		var lock_icon := Label.new()
		lock_icon.text = "🔒"
		lock_icon.add_theme_font_size_override("font_size", 20)
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_col.add_child(lock_icon)
		var cost_label := Label.new()
		cost_label.text = "需要 %d⭐" % MAP_REGISTRY.get_cost(map_id)
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1))
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_col.add_child(cost_label)
		overlay.add_child(lock_col)
		card.add_child(overlay)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", _hover_style())
	btn.add_theme_stylebox_override("pressed", _hover_style())
	if is_locked:
		btn.pressed.connect(func() -> void:
			_show_unlock_dialog(index)
		)
	else:
		btn.pressed.connect(func() -> void:
			_selected_index = index
			_refresh_ui()
		)
	card.add_child(btn)

	return card

func _show_unlock_dialog(index: int) -> void:
	var data: Dictionary = MAP_REGISTRY.MAPS[index]
	var map_id := str(data["id"])
	var cost := MAP_REGISTRY.get_cost(map_id)
	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0.72)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.11, 0.10, 1)
	panel_style.border_color = Color(data["color"].r, data["color"].g, data["color"].b, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", panel_style)
	blocker.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(col)

	var title := Label.new()
	title.text = "解锁地图"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var desc := Label.new()
	desc.text = "%s\n消耗 %d⭐（当前 %d⭐）" % [data["name"], cost, PlayerData.total_stars]
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.82, 0.78, 0.70, 1))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(desc)

	var hint := Label.new()
	hint.text = ""
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)

	var cancel_btn := _make_button("取消", false)
	cancel_btn.custom_minimum_size = Vector2(90, 48)
	cancel_btn.pressed.connect(func() -> void:
		blocker.queue_free()
	)
	btn_row.add_child(cancel_btn)

	var confirm_btn := _make_button("确认解锁", true)
	confirm_btn.custom_minimum_size = Vector2(120, 48)
	confirm_btn.pressed.connect(func() -> void:
		if PlayerData.unlock_map(map_id):
			blocker.queue_free()
			_selected_index = index
			_refresh_ui()
		else:
			hint.text = "星星不足，先赢得比赛或领取奖励。"
	)
	btn_row.add_child(confirm_btn)

	var reward_btn := _make_button("获取星星", false)
	reward_btn.custom_minimum_size = Vector2(120, 48)
	reward_btn.disabled = not MonetizationService.is_rewarded_ad_available()
	if reward_btn.disabled:
		reward_btn.tooltip_text = "广告 SDK 未接入，当前 Release 不可用"
	reward_btn.pressed.connect(func() -> void:
		var amount := 3
		if MonetizationService.request_rewarded_stars("map_unlock", amount):
			desc.text = "%s\n消耗 %d⭐（当前 %d⭐）" % [data["name"], cost, PlayerData.total_stars]
			hint.text = "已获得 +%d⭐（调试/占位奖励）" % amount
		else:
			hint.text = "奖励暂不可用，请通过比赛或每日奖励获得星星。"
	)
	btn_row.add_child(reward_btn)

func _info_text(index: int) -> String:
	var data: Dictionary = MAP_REGISTRY.MAPS[index]
	return "%s  ·  %s" % [data["name"], data["desc"]]

func _make_button(label_text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(210, 58)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.85, 0.54, 0.14, 1) if primary else Color(0.14, 0.15, 0.18, 1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.66, 0.2, 1)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.08, 0.08, 0.09, 0.82)))
	return button

func _card_style(accent: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.095, 0.075, 0.88) if not selected else Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.95)
	style.border_color = accent if selected else Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 0.6)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(12)
	style.shadow_size = 12 if selected else 4
	style.shadow_color = Color(0, 0, 0, 0.4)
	return style

func _hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.set_corner_radius_all(12)
	return style

func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.85, 0.54, 0.14, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style
