extends CanvasLayer

var manager: MatchManager = null
var timer_label: Label
var score_label: Label
var health_label: Label
var weapon_label: Label
var ammo_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_title: Label
var result_detail: Label
var result_subtitle: Label  ## 新增：显示击杀/存活详情的第二行

## 动态准星四条线（上/下/左/右）
var _cross_top: ColorRect
var _cross_bottom: ColorRect
var _cross_left: ColorRect
var _cross_right: ColorRect
## 当前准星张开半径（像素），平滑插值目标
var _spread_radius := 13.0
## 命中标记剩余时间
var _hit_marker_time := 0.0

## 准星参数
const CROSS_LINE_LEN   := 10    ## 每条线的长度（像素）
const CROSS_LINE_THICK := 2     ## 线宽（像素）
const CROSS_GAP_MIN    := 5.0   ## 静止时准星中心到线的距离
const CROSS_GAP_MAX    := 26.0  ## 全速移动时距离
const CROSS_FIRE_BONUS := 12.0  ## 开枪后额外扩散
const CROSS_FIRE_DECAY := 0.35  ## 开枪扩散衰减时间（秒）
const CROSS_LERP_SPEED := 8.0   ## 收缩/扩张速度
const HIT_MARKER_DUR   := 0.12  ## 命中标记持续时间（秒）

func _ready() -> void:
	_build_hud()

func bind_manager(new_manager: MatchManager) -> void:
	manager = new_manager
	if manager.player != null:
		manager.player.player_health_changed.connect(_on_health_changed)
		manager.player.player_weapon_changed.connect(_on_weapon_changed)
		manager.player.player_ammo_changed.connect(_on_ammo_changed)
		var health := manager.get_player_health()
		if health != null:
			_on_health_changed(health.current_health, health.max_health)
		_on_weapon_changed(manager.get_current_weapon_name())
		if manager.player.weapon_system != null:
			_on_ammo_changed(manager.player.weapon_system.get_current_ammo(), manager.player.weapon_system.get_current_reserve(), manager.player.weapon_system.is_reloading)
			## 监听命中事件（武器发射信号）
			manager.player.weapon_system.weapon_fired.connect(_on_weapon_fired)
			manager.player.weapon_system.enemy_hit.connect(show_hit_marker)

func _on_weapon_fired(_weapon_id: String) -> void:
	pass  ## 开枪时准星扩散由 _process 里的 last_fire_time 驱动

func _process(delta: float) -> void:
	if manager == null:
		return
	var seconds := int(ceil(manager.remaining_time))
	var minutes := int(seconds / 60)
	timer_label.text = "时间 %02d:%02d" % [minutes, seconds % 60]
	score_label.text = "蓝队 %d  :  %d 橙队" % [manager.get_living_count("blue"), manager.get_living_count("orange")]
	weapon_label.text = "武器：%s" % manager.get_current_weapon_name()
	_update_crosshair(delta)

func _update_crosshair(delta: float) -> void:
	if manager == null or manager.player == null:
		return
	var player := manager.player
	## 速度比例 0~1
	var speed_ratio := Vector2(player.velocity.x, player.velocity.z).length() / player.SPEED
	speed_ratio = clampf(speed_ratio, 0.0, 1.0)
	## 开枪额外扩散：根据距上次开枪时间线性衰减
	var fire_bonus := 0.0
	if player.weapon_system != null:
		var since_fire := (Time.get_ticks_msec() / 1000.0) - player.weapon_system.last_fire_time
		fire_bonus = CROSS_FIRE_BONUS * clampf(1.0 - since_fire / CROSS_FIRE_DECAY, 0.0, 1.0)
	## 目标间距
	var target_gap := CROSS_GAP_MIN + (CROSS_GAP_MAX - CROSS_GAP_MIN) * speed_ratio + fire_bonus
	_spread_radius = lerpf(_spread_radius, target_gap, clampf(CROSS_LERP_SPEED * delta, 0.0, 1.0))
	## 命中标记倒计时
	if _hit_marker_time > 0.0:
		_hit_marker_time -= delta
	var cross_color := Color(1.0, 0.28, 0.22, 0.95) if _hit_marker_time > 0.0 else Color(0.96, 0.93, 0.87, 0.92)
	_apply_cross_line(_cross_top,    _spread_radius, cross_color)
	_apply_cross_line(_cross_bottom, _spread_radius, cross_color)
	_apply_cross_line(_cross_left,   _spread_radius, cross_color)
	_apply_cross_line(_cross_right,  _spread_radius, cross_color)

## 显示命中标记（由外部调用，例如 health.apply_damage 后）
func show_hit_marker() -> void:
	_hit_marker_time = HIT_MARKER_DUR

## 将一条准星线定位到正确位置
func _apply_cross_line(rect: ColorRect, gap: float, color: Color) -> void:
	rect.color = color
	var g := int(gap)
	if rect == _cross_top:
		rect.offset_left  = -CROSS_LINE_THICK / 2
		rect.offset_right = CROSS_LINE_THICK / 2
		rect.offset_top    = -(g + CROSS_LINE_LEN)
		rect.offset_bottom = -g
	elif rect == _cross_bottom:
		rect.offset_left  = -CROSS_LINE_THICK / 2
		rect.offset_right = CROSS_LINE_THICK / 2
		rect.offset_top    = g
		rect.offset_bottom = g + CROSS_LINE_LEN
	elif rect == _cross_left:
		rect.offset_left  = -(g + CROSS_LINE_LEN)
		rect.offset_right = -g
		rect.offset_top    = -CROSS_LINE_THICK / 2
		rect.offset_bottom = CROSS_LINE_THICK / 2
	elif rect == _cross_right:
		rect.offset_left  = g
		rect.offset_right = g + CROSS_LINE_LEN
		rect.offset_top    = -CROSS_LINE_THICK / 2
		rect.offset_bottom = CROSS_LINE_THICK / 2

func show_result(title: String, reason: String, blue_left: int, orange_left: int, player_kills: int) -> void:
	result_panel.visible = true
	result_title.text = title

	## 颜色：胜利金色，失败红色，平局灰白
	var title_color: Color
	match title:
		"胜利":
			title_color = Color(1.0, 0.85, 0.25, 1)
		"失败":
			title_color = Color(1.0, 0.35, 0.3, 1)
		_:
			title_color = Color(0.82, 0.80, 0.75, 1)
	result_title.add_theme_color_override("font_color", title_color)

	result_detail.text = "原因：%s" % reason
	result_subtitle.text = "蓝队剩余 %d 人  ·  橙队剩余 %d 人  ·  你的击杀 %d" % [blue_left, orange_left, player_kills]
	hint_label.text = "比赛结束"

	## 面板弹出动画
	result_panel.scale = Vector2(0.75, 0.75)
	result_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_panel, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.18)

func _on_health_changed(current: float, max_value: float) -> void:
	health_label.text = "生命：%d / %d" % [int(current), int(max_value)]

func _on_weapon_changed(display_name: String) -> void:
	weapon_label.text = "武器：%s" % display_name

func _on_ammo_changed(current: int, reserve: int, is_reloading: bool) -> void:
	var suffix := "  装弹中" if is_reloading else ""
	ammo_label.text = "子弹：%d / %d%s" % [current, reserve, suffix]

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

	timer_label = _make_pill_label("时间 05:00", Color(0.09, 0.1, 0.12, 0.76), 170)
	top.add_child(timer_label)
	score_label = _make_pill_label("蓝队 5  :  5 橙队", Color(0.1, 0.12, 0.16, 0.76), 210)
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

	health_label = _make_pill_label("生命：120 / 120", Color(0.06, 0.18, 0.1, 0.78), 180)
	bottom.add_child(health_label)
	weapon_label = _make_pill_label("武器：M416", Color(0.15, 0.11, 0.06, 0.78), 170)
	bottom.add_child(weapon_label)
	ammo_label = _make_pill_label("子弹：30 / 120", Color(0.12, 0.11, 0.16, 0.78), 190)
	bottom.add_child(ammo_label)
	hint_label = _make_pill_label("WASD 移动 · 鼠标瞄准 · 左键射击 · R 装弹 · 1/2/3 切枪", Color(0.08, 0.08, 0.1, 0.62), 430)
	bottom.add_child(hint_label)

	_build_crosshair(root)
	_build_result_panel(root)

func _make_pill_label(text: String, bg: Color, width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 42)
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
	var color := Color(0.96, 0.93, 0.87, 0.92)
	_cross_top    = _make_cross_rect(root, color)
	_cross_bottom = _make_cross_rect(root, color)
	_cross_left   = _make_cross_rect(root, color)
	_cross_right  = _make_cross_rect(root, color)
	## 初始化到默认位置
	_apply_cross_line(_cross_top,    CROSS_GAP_MIN, color)
	_apply_cross_line(_cross_bottom, CROSS_GAP_MIN, color)
	_apply_cross_line(_cross_left,   CROSS_GAP_MIN, color)
	_apply_cross_line(_cross_right,  CROSS_GAP_MIN, color)

func _make_cross_rect(root: Control, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.anchor_left   = 0.5
	rect.anchor_right  = 0.5
	rect.anchor_top    = 0.5
	rect.anchor_bottom = 0.5
	root.add_child(rect)
	return rect

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

	result_subtitle = Label.new()
	result_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_subtitle.add_theme_font_size_override("font_size", 16)
	result_subtitle.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65, 1))
	box.add_child(result_subtitle)

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
