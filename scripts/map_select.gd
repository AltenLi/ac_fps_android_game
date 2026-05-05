extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.075, 1)
	add_child(bg)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 90)
	shell.add_theme_constant_override("margin_right", 90)
	shell.add_theme_constant_override("margin_top", 70)
	shell.add_theme_constant_override("margin_bottom", 70)
	add_child(shell)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	shell.add_child(root)

	var title := Label.new()
	title.text = "选择地图"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	root.add_child(title)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	root.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 14)
	margin.add_child(card_box)

	var map_name := Label.new()
	map_name.text = "城市巷战 · Dust City"
	map_name.add_theme_font_size_override("font_size", 30)
	map_name.add_theme_color_override("font_color", Color(1.0, 0.79, 0.45, 1))
	card_box.add_child(map_name)

	var preview := ColorRect.new()
	preview.custom_minimum_size = Vector2(1, 210)
	preview.color = Color(0.56, 0.42, 0.22, 1)
	card_box.add_child(preview)

	var desc := Label.new()
	desc.text = "原创低模沙色城市地图：中路、侧巷、掩体、屋顶平台。模式：玩家 + 4 队友 AI 对战 5 敌方 AI，限时 5 分钟。"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72, 1))
	card_box.add_child(desc)

	var tag := Label.new()
	tag.text = "5v5 · 低模 FPS · RPG / M416 / 巴雷特"
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color(0.35, 0.65, 1.0, 1))
	card_box.add_child(tag)

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
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
	buttons.add_child(enter)

func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(210, 58)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.85, 0.54, 0.14, 1) if primary else Color(0.14, 0.15, 0.18, 1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.66, 0.2, 1)))
	return button

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.095, 0.075, 0.88)
	style.border_color = Color(0.85, 0.54, 0.14, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_size = 18
	style.shadow_color = Color(0, 0, 0, 0.36)
	return style

func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.85, 0.54, 0.14, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style
