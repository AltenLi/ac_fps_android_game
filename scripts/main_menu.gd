extends Control

const COLOR_BG := Color(0.055, 0.06, 0.08, 1.0)
const COLOR_PANEL := Color(0.12, 0.105, 0.08, 0.72)
const COLOR_ACCENT := Color(0.85, 0.54, 0.14, 1.0)
const COLOR_TEXT := Color(0.96, 0.93, 0.87, 1.0)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	## macOS 需要等窗口真正获得焦点后再设一次，否则首次点击会被系统消耗
	call_deferred("_ensure_mouse_visible")
	_build_ui()

func _notification(what: int) -> void:
	## 每次窗口重新获得焦点（如 Alt+Tab 回来）都强制显示鼠标
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ensure_mouse_visible() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_ui() -> void:
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
	shell.add_theme_constant_override("margin_left", 90)
	shell.add_theme_constant_override("margin_right", 90)
	shell.add_theme_constant_override("margin_top", 70)
	shell.add_theme_constant_override("margin_bottom", 50)
	add_child(shell)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 22)
	shell.add_child(root)

	var title := Label.new()
	title.text = "CS 5v5"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "低模 3D 单人枪战原型 · 5v5 · RPG / M416 / 巴雷特"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.8, 0.68, 1.0))
	root.add_child(subtitle)

	var star_label := Label.new()
	star_label.text = "⭐ %d" % PlayerData.total_stars
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 20)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
	root.add_child(star_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 28)
	root.add_child(spacer)

	var start_button := _make_button("开始游戏", true)
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/map_select.tscn")
	)
	root.add_child(start_button)

	var settings_button := _make_button("设置", false)
	settings_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
	)
	root.add_child(settings_button)

	var hint := Label.new()
	hint.text = "桌面：WASD 移动 · 鼠标瞄准 · 左键射击 · 1/2/3 或 Q 切枪 · ESC 释放鼠标"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62, 1.0))
	root.add_child(hint)

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
	button.custom_minimum_size = Vector2(340, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _button_style(COLOR_ACCENT if primary else COLOR_PANEL, COLOR_ACCENT))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.98, 0.66, 0.2, 1.0), Color(1.0, 0.82, 0.45, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.52, 0.31, 0.09, 1.0), COLOR_ACCENT))
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
