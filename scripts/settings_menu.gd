extends Control

var _quality_options := ["performance", "balanced", "quality"]

func _ready() -> void:
	SoundManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.055, 0.06, 0.08, 1)
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
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	root.add_child(title)

	root.add_child(_make_slider_row("主音量", GameSettings.master_volume, 0.0, 1.0, func(v: float) -> void:
		GameSettings.set_master_volume(v)
	))
	root.add_child(_make_slider_row("视角灵敏度", GameSettings.mouse_sensitivity, 0.05, 0.6, func(v: float) -> void:
		GameSettings.set_mouse_sensitivity(v)
	))
	root.add_child(_make_quality_row())

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var save := _make_button("保存并返回首页")
	save.pressed.connect(func() -> void:
		GameSettings.save_settings()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	root.add_child(save)

func _make_slider_row(label_text: String, value: float, min_value: float, max_value: float, callback: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = value
	slider.value_changed.connect(callback)
	row.add_child(slider)
	return panel

func _make_quality_row() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var label := Label.new()
	label.text = "画质模式"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	row.add_child(label)
	var option := OptionButton.new()
	option.add_item("性能优先")
	option.add_item("平衡")
	option.add_item("画质优先")
	option.selected = max(0, _quality_options.find(GameSettings.quality_mode))
	option.item_selected.connect(func(index: int) -> void:
		GameSettings.set_quality_mode(_quality_options[index])
	)
	row.add_child(option)
	return panel

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 58)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.85, 0.54, 0.14, 1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.66, 0.2, 1)))
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.105, 0.08, 0.78)
	style.border_color = Color(0.85, 0.54, 0.14, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style

func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(14)
	style.shadow_size = 10
	style.shadow_color = Color(0, 0, 0, 0.32)
	return style
