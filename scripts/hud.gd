extends CanvasLayer

var manager: MatchManager = null
var timer_label: Label
var score_label: Label
var health_label: Label
var weapon_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_title: Label
var result_detail: Label

func _ready() -> void:
	_build_hud()

func bind_manager(new_manager: MatchManager) -> void:
	manager = new_manager
	if manager.player != null:
		manager.player.player_health_changed.connect(_on_health_changed)
		manager.player.player_weapon_changed.connect(_on_weapon_changed)
		var health := manager.get_player_health()
		if health != null:
			_on_health_changed(health.current_health, health.max_health)
		_on_weapon_changed(manager.get_current_weapon_name())

func _process(_delta: float) -> void:
	if manager == null:
		return
	var seconds := int(ceil(manager.remaining_time))
	var minutes := int(seconds / 60)
	timer_label.text = "时间 %02d:%02d" % [minutes, seconds % 60]
	score_label.text = "蓝队 %d  :  %d 橙队" % [manager.get_living_count("blue"), manager.get_living_count("orange")]
	weapon_label.text = "武器：%s" % manager.get_current_weapon_name()

func show_result(title: String, reason: String, blue_left: int, orange_left: int, player_kills: int) -> void:
	result_panel.visible = true
	result_title.text = title
	result_detail.text = "原因：%s\n蓝队剩余：%d    橙队剩余：%d\n你的队伍击杀：%d" % [reason, blue_left, orange_left, player_kills]
	hint_label.text = "比赛结束"

func _on_health_changed(current: float, max_value: float) -> void:
	health_label.text = "生命：%d / %d" % [int(current), int(max_value)]

func _on_weapon_changed(display_name: String) -> void:
	weapon_label.text = "武器：%s" % display_name

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.anchor_right = 1.0
	top.anchor_bottom = 0.0
	top.offset_left = 24
	top.offset_top = 18
	top.offset_right = -24
	top.offset_bottom = 64
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)

	timer_label = _make_pill_label("时间 05:00", Color(0.09, 0.1, 0.12, 0.76))
	top.add_child(timer_label)
	score_label = _make_pill_label("蓝队 5  :  5 橙队", Color(0.1, 0.12, 0.16, 0.76))
	top.add_child(score_label)

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.0
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 24
	bottom.offset_top = -72
	bottom.offset_right = -24
	bottom.offset_bottom = -18
	bottom.add_theme_constant_override("separation", 18)
	root.add_child(bottom)

	health_label = _make_pill_label("生命：120 / 120", Color(0.06, 0.18, 0.1, 0.78))
	bottom.add_child(health_label)
	weapon_label = _make_pill_label("武器：M416", Color(0.15, 0.11, 0.06, 0.78))
	bottom.add_child(weapon_label)
	hint_label = _make_pill_label("WASD 移动 · 鼠标瞄准 · 左键射击 · 1/2/3 切枪", Color(0.08, 0.08, 0.1, 0.62))
	bottom.add_child(hint_label)

	_build_crosshair(root)
	_build_result_panel(root)

func _make_pill_label(text: String, bg: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(170, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.85, 0.54, 0.14, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	label.add_theme_stylebox_override("normal", style)
	return label

func _build_crosshair(root: Control) -> void:
	var h := ColorRect.new()
	h.color = Color(0.96, 0.93, 0.87, 0.92)
	h.anchor_left = 0.5
	h.anchor_right = 0.5
	h.anchor_top = 0.5
	h.anchor_bottom = 0.5
	h.offset_left = -13
	h.offset_right = 13
	h.offset_top = -1
	h.offset_bottom = 1
	root.add_child(h)

	var v := ColorRect.new()
	v.color = Color(0.96, 0.93, 0.87, 0.92)
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = -1
	v.offset_right = 1
	v.offset_top = -13
	v.offset_bottom = 13
	root.add_child(v)

func _build_result_panel(root: Control) -> void:
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.anchor_left = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -270
	result_panel.offset_top = -185
	result_panel.offset_right = 270
	result_panel.offset_bottom = 185
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.075, 0.92)
	style.border_color = Color(0.85, 0.54, 0.14, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_size = 18
	style.shadow_color = Color(0, 0, 0, 0.45)
	result_panel.add_theme_stylebox_override("panel", style)
	root.add_child(result_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	result_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 44)
	result_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38, 1))
	box.add_child(result_title)

	result_detail = Label.new()
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.add_theme_font_size_override("font_size", 18)
	result_detail.add_theme_color_override("font_color", Color(0.9, 0.86, 0.76, 1))
	box.add_child(result_detail)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(_result_button("重新开始", func() -> void: manager.restart_match()))
	buttons.add_child(_result_button("地图选择", func() -> void: manager.return_to_map_select()))
	buttons.add_child(_result_button("返回首页", func() -> void: manager.return_to_main_menu()))

func _result_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(callback)
	return button
