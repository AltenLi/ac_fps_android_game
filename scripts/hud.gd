extends CanvasLayer

var manager: MatchManager = null
var timer_label: Label
var score_label: Label
var health_label: Label
var shield_label: Label
var weapon_label: Label
var ammo_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_title: Label
var result_detail: Label
var result_subtitle: Label  ## 新增：显示击杀/存活详情的第二行

## 低血量屏幕边缘红色渐变
var _vignette: Control
var _current_health_ratio := 1.0  ## 0.0~1.0，用于平滑插值

## 动态准星四条线（上/下/左/右）
var _cross_top: ColorRect
var _cross_bottom: ColorRect
var _cross_left: ColorRect
var _cross_right: ColorRect
## 当前准星张开半径（像素），平滑插值目标
var _spread_radius := 13.0
## 命中标记剩余时间
var _hit_marker_time := 0.0

## 观战系统 UI
var _spectate_panel: Control = null
var _spectate_label: Label = null
var _spectating_player: Node = null  ## 持有 PlayerController 引用（弱引用避免循环）

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
	layer = 10  ## 确保 HUD（含结果面板按钮）层级高于 mobile_controls（layer 1），点击不被遮挡
	_build_hud()

func bind_manager(new_manager: MatchManager) -> void:
	manager = new_manager
	if manager.player != null:
		manager.player.player_health_changed.connect(_on_health_changed)
		manager.player.player_shield_changed.connect(_on_shield_changed)
		manager.player.player_weapon_changed.connect(_on_weapon_changed)
		manager.player.player_ammo_changed.connect(_on_ammo_changed)
		manager.player.player_died.connect(_on_player_died)
		var health := manager.get_player_health()
		if health != null:
			_on_health_changed(health.current_health, health.max_health)
			_on_shield_changed(health.shield, health.max_shield)
		_on_weapon_changed(manager.get_current_weapon_name())
		if manager.player.weapon_system != null:
			_on_ammo_changed(manager.player.weapon_system.get_current_ammo(), manager.player.weapon_system.get_current_reserve(), manager.player.weapon_system.is_reloading)
			## 监听命中事件（武器发射信号）
			manager.player.weapon_system.weapon_fired.connect(_on_weapon_fired)
			manager.player.weapon_system.enemy_hit.connect(show_hit_marker)

func _on_player_died() -> void:
	pass  ## 观战模式由 player_controller 通过 enter_spectate_mode() 直接调用

## 进入观战模式：隐藏准星和底部 HUD，显示观战面板
func enter_spectate_mode(player_node: Node) -> void:
	_spectating_player = player_node
	## 隐藏准星
	for rect: ColorRect in [_cross_top, _cross_bottom, _cross_left, _cross_right]:
		if rect != null:
			rect.visible = false
	## 隐藏底部标签
	for lbl: Label in [health_label, shield_label, weapon_label, ammo_label, hint_label]:
		if lbl != null:
			lbl.visible = false
	## 构建观战面板
	_build_spectate_panel()
	## 初始化目标名称
	if player_node != null and player_node.has_method("_get_spectate_name"):
		update_spectate_target_name(player_node._get_spectate_name())

## 刷新观战目标名称标签
func update_spectate_target_name(name: String) -> void:
	if _spectate_label != null:
		_spectate_label.text = "👁 正在观战：%s" % name

func _build_spectate_panel() -> void:
	if _spectate_panel != null:
		return
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 88
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.72)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_spectate_panel = panel

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	## ← 按钮
	var btn_prev := _spectate_button("←", func() -> void:
		if _spectating_player != null and _spectating_player.has_method("spectate_prev"):
			_spectating_player.spectate_prev()
	)
	hbox.add_child(btn_prev)

	## 观战名称标签
	_spectate_label = Label.new()
	_spectate_label.text = "👁 正在观战：—"
	_spectate_label.add_theme_font_size_override("font_size", 20)
	_spectate_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75, 1.0))
	_spectate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_spectate_label.custom_minimum_size = Vector2(260, 0)
	_spectate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_spectate_label)

	## → 按钮
	var btn_next := _spectate_button("→", func() -> void:
		if _spectating_player != null and _spectating_player.has_method("spectate_next"):
			_spectating_player.spectate_next()
	)
	hbox.add_child(btn_next)

	## 跳过本局按钮（展开子选项）
	var btn_skip := _spectate_button("跳过本局 ▾", func() -> void:
		_toggle_skip_options()
	)
	btn_skip.name = "SkipButton"
	btn_skip.custom_minimum_size = Vector2(130, 42)
	hbox.add_child(btn_skip)

	## 子选项容器（默认隐藏）
	var skip_options := HBoxContainer.new()
	skip_options.name = "SkipOptions"
	skip_options.visible = false
	skip_options.add_theme_constant_override("separation", 8)
	hbox.add_child(skip_options)

	var btn_next_game := _spectate_button("下一局", func() -> void:
		if manager != null:
			manager.restart_match()
	)
	skip_options.add_child(btn_next_game)

	var btn_home := _spectate_button("返回首页", func() -> void:
		if manager != null:
			manager.return_to_main_menu()
	)
	skip_options.add_child(btn_home)

func _toggle_skip_options() -> void:
	if _spectate_panel == null:
		return
	var opts := _spectate_panel.find_child("SkipOptions", true, false)
	if opts != null:
		opts.visible = not opts.visible

func _spectate_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(54, 42)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.75, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.14, 0.88)
	style.border_color = Color(0.85, 0.54, 0.14, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", style)
	var style_h := style.duplicate() as StyleBoxFlat
	style_h.bg_color = Color(0.22, 0.18, 0.10, 0.95)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.pressed.connect(callback)
	return btn

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
	_update_vignette(delta)

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

func _build_vignette(root: Control) -> void:
	## 用 PanelContainer 全屏覆盖，StyleBoxFlat 只画边框不画中心
	## border 宽 42px ≈ 1cm（96 dpi），颜色深红，透明度由血量驱动
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0.85, 0.05, 0.05, 1.0)
	style.set_border_width_all(42)
	style.set_corner_radius_all(0)
	style.draw_center = false
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate.a = 0.0
	root.add_child(panel)
	_vignette = panel

## 低血量屏幕边缘红色渐变：血量 < 50% 时出现，血越低越深
func _update_vignette(_delta: float) -> void:
	if _vignette == null:
		return
	## 低于 50% 血量才显示，t = 0（50%血）→ 1（0%血）
	var t := clampf(1.0 - _current_health_ratio * 2.0, 0.0, 1.0)
	## alpha：最大约 0.72，曲线用二次方让低血更明显
	var alpha := t * t * 0.72
	_vignette.modulate.a = alpha
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

func show_result(title: String, reason: String, blue_left: int, orange_left: int, player_kills: int, stars_earned: int = 0, combatant_stats: Array[Dictionary] = []) -> void:
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
	if hint_label != null:
		hint_label.text = "比赛结束"

	## 确定MVP（本局击杀最多的单位）
	var mvp_kills := 0
	for s: Dictionary in combatant_stats:
		var k: int = s.get("kills", 0)
		if k > mvp_kills:
			mvp_kills = k

	## 用combatant_stats填充战绩表；如无数据则退回到简单文字
	var box := result_subtitle.get_parent()
	if combatant_stats.size() > 0:
		result_subtitle.visible = false
		## 构建表格容器
		var table_container := _build_stats_table(combatant_stats, mvp_kills)
		## 插入到 result_subtitle 之后
		box.add_child(table_container)
		box.move_child(table_container, result_subtitle.get_index() + 1)
	else:
		result_subtitle.text = "蓝队剩余 %d 人  ·  橙队剩余 %d 人  ·  你的击杀 %d" % [blue_left, orange_left, player_kills]

	## 星星奖励显示
	if stars_earned > 0:
		var star_text := "⭐ × %d   总计 %d 颗星" % [stars_earned, PlayerData.total_stars]
		var star_label := Label.new()
		star_label.text = star_text
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 20)
		star_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
		box.add_child(star_label)
		var table_or_sub_idx := result_subtitle.get_index() + 1
		box.move_child(star_label, table_or_sub_idx + (1 if combatant_stats.size() > 0 else 0))

	## 面板弹出动画
	result_panel.scale = Vector2(0.75, 0.75)
	result_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_panel, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.18)

	## 胜利时发射彩色纸屑
	if title == "胜利":
		_spawn_confetti()

## 构建10行战绩表格
func _build_stats_table(stats: Array[Dictionary], mvp_kills: int) -> Control:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)

	## 表头
	var headers := ["名称", "本局击杀", "累计击杀", "累计死亡"]
	for h: String in headers:
		var cell := _make_table_cell(h, true, false, false, "")
		grid.add_child(cell)

	## 数据行
	for s: Dictionary in stats:
		var is_mvp: bool = mvp_kills > 0 and int(s.get("kills", 0)) == mvp_kills
		var is_player: bool = s.get("is_player", false)
		var team: String = s.get("team", "blue")
		var name_text: String = s.get("name", "?")
		if is_mvp:
			name_text = "🏆 " + name_text

		var kills_str := str(s.get("kills", 0))
		var cum_kills_str := str(PlayerData.total_kills) if is_player else "—"
		var cum_deaths_str := str(PlayerData.total_deaths) if is_player else "—"

		grid.add_child(_make_table_cell(name_text, false, is_mvp, team == "blue", team))
		grid.add_child(_make_table_cell(kills_str, false, is_mvp, team == "blue", team))
		grid.add_child(_make_table_cell(cum_kills_str, false, is_mvp, team == "blue", team))
		grid.add_child(_make_table_cell(cum_deaths_str, false, is_mvp, team == "blue", team))

	return grid

## 创建一个表格单元格
func _make_table_cell(text: String, is_header: bool, is_mvp: bool, _is_blue: bool, team: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(130, 28)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	if is_header:
		style.bg_color = Color(0.12, 0.11, 0.14, 0.95)
		style.border_color = Color(0.3, 0.28, 0.25, 0.5)
	elif is_mvp:
		style.bg_color = Color(0.28, 0.22, 0.04, 0.95)
		style.border_color = Color(0.85, 0.68, 0.12, 0.8)
	elif team == "blue":
		style.bg_color = Color(0.06, 0.10, 0.18, 0.82)
		style.border_color = Color(0.18, 0.32, 0.55, 0.4)
	else:
		style.bg_color = Color(0.18, 0.08, 0.06, 0.82)
		style.border_color = Color(0.55, 0.20, 0.12, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size := 14 if is_header else 13
	label.add_theme_font_size_override("font_size", font_size)
	var font_color: Color
	if is_header:
		font_color = Color(0.72, 0.70, 0.62, 1)
	elif is_mvp:
		font_color = Color(1.0, 0.88, 0.25, 1)
	else:
		font_color = Color(0.88, 0.85, 0.78, 1)
	label.add_theme_color_override("font_color", font_color)
	panel.add_child(label)
	return panel

func _on_health_changed(current: float, max_value: float) -> void:
	health_label.text = "生命：%d / %d" % [int(current), int(max_value)]
	_current_health_ratio = current / max_value if max_value > 0.0 else 1.0

func _on_shield_changed(current: float, max_value: float) -> void:
	if shield_label == null:
		return
	shield_label.visible = max_value > 0.0
	shield_label.text = "护盾：%d / %d" % [int(current), int(max_value)]

func _on_weapon_changed(display_name: String) -> void:
	weapon_label.text = "武器：%s" % display_name

func _on_ammo_changed(current: int, reserve: int, is_reloading: bool) -> void:
	if manager != null and manager.player != null and manager.player.weapon_system != null and manager.player.weapon_system.get_current_weapon_id() == "knife":
		ammo_label.text = "近战：无限挥砍"
		return
	var suffix := "  装弹中" if is_reloading else ""
	ammo_label.text = "子弹：%d / %d%s" % [current, reserve, suffix]

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	health_label = _make_pill_label("生命：100 / 100", Color(0.06, 0.18, 0.1, 0.78), 180)
	bottom.add_child(health_label)
	shield_label = _make_pill_label("护盾：30 / 30", Color(0.06, 0.14, 0.28, 0.78), 170)
	bottom.add_child(shield_label)
	weapon_label = _make_pill_label("武器：M416", Color(0.15, 0.11, 0.06, 0.78), 170)
	bottom.add_child(weapon_label)
	ammo_label = _make_pill_label("子弹：30 / 120", Color(0.12, 0.11, 0.16, 0.78), 190)
	bottom.add_child(ammo_label)
	if _should_show_control_hint():
		hint_label = _make_pill_label("WASD 移动 · 鼠标瞄准 · 左键射击 · R 装弹 · 1/2/3 切枪", Color(0.08, 0.08, 0.1, 0.62), 430)
		bottom.add_child(hint_label)

	_build_crosshair(root)
	_build_vignette(root)
	_build_result_panel(root)

func _should_show_control_hint() -> bool:
	return not OS.has_feature("android") and not OS.has_feature("ios")

func _make_pill_label(text: String, bg: Color, width: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	result_panel.offset_left = -310
	result_panel.offset_top = -265
	result_panel.offset_right = 310
	result_panel.offset_bottom = 265
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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

## 右上角旗型击杀条幅：从右侧滑入，1.8秒后滑出
func show_kill_banner(killer_name: String, victim_name: String) -> void:
	## 外层容器：旗型背景
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.92)
	style.border_color = Color(1.0, 0.62, 0.08, 1.0)
	style.set_border_width_all(0)
	style.border_width_left = 4
	style.border_width_bottom = 2
	style.set_corner_radius_all(0)
	style.corner_radius_bottom_left = 10
	style.corner_radius_top_left = 10
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	## 锚点在右上角
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 90
	panel.offset_bottom = 90

	## 内容行
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	## 剑图标
	var icon := Label.new()
	icon.text = "⚔"
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color(1.0, 0.62, 0.08, 1.0))
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	## 击杀者（你）
	var killer_label := Label.new()
	killer_label.text = killer_name
	killer_label.add_theme_font_size_override("font_size", 18)
	killer_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.45, 1.0))
	killer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(killer_label)

	## 动词
	var verb := Label.new()
	verb.text = "击杀了"
	verb.add_theme_font_size_override("font_size", 15)
	verb.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66, 1.0))
	verb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(verb)

	## 被击杀者
	var victim_label := Label.new()
	victim_label.text = victim_name
	victim_label.add_theme_font_size_override("font_size", 18)
	victim_label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.32, 1.0))
	victim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(victim_label)

	add_child(panel)

	## 等布局完成后取到实际宽度，做滑入动画
	await get_tree().process_frame
	var panel_width: float = panel.size.x
	panel.offset_left = 0
	panel.offset_right = 0

	## 滑入：从右边界外滑入到右边 -panel_width-16
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "offset_left", -panel_width - 16, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "offset_right", -16, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

	## 停留 1.4 秒后滑出
	await get_tree().create_timer(1.4).timeout
	var tween2 := create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(panel, "offset_left", 0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween2.tween_property(panel, "offset_right", 0, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween2.tween_property(panel, "modulate:a", 0.0, 0.18).set_delay(0.04)
	await tween2.finished
	_queue_free_if_valid(panel)

## 从屏幕左上和右上发射彩色纸屑
func show_achievement(message: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.10, 0.94)
	style.border_color = Color(0.70, 0.90, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = 112
	panel.offset_bottom = 168

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0, 1.0))
	panel.add_child(label)
	add_child(panel)

	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.28)
	tween.tween_callback(_queue_free_if_valid.bind(panel))

func _spawn_confetti() -> void:
	var _root := get_node_or_null("..") if get_parent() != null else self
	## 添加到 CanvasLayer 本身
	for i in range(2):
		var p := CPUParticles2D.new()
		## 手动设置像素位置（left/right cannon）
		p.position = Vector2(get_viewport().get_visible_rect().size.x * (0.15 if i == 0 else 0.85), 0)
		p.amount = 80
		p.lifetime = 3.5
		p.one_shot = true
		p.explosiveness = 0.12
		p.direction = Vector2(0.0, 1.0)
		p.spread = 55.0
		p.gravity = Vector2(0.0, 180.0)
		p.initial_velocity_min = 220.0
		p.initial_velocity_max = 420.0
		p.angular_velocity_min = -120.0
		p.angular_velocity_max = 120.0
		p.scale_amount_min = 6.0
		p.scale_amount_max = 14.0
		p.color = Color(1, 1, 1, 1)
		p.color_ramp = _make_confetti_gradient()
		add_child(p)
		p.restart()
		## 4秒后自动清理；用 bind 固定当前粒子引用，并在回调里检查有效性，避免滑动/切场景后空引用。
		get_tree().create_timer(4.5).timeout.connect(_queue_free_if_valid.bind(p))

func _queue_free_if_valid(node: Node) -> void:
	if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
		node.queue_free()

func _make_confetti_gradient() -> Gradient:
	var g := Gradient.new()
	g.offsets = [0.0, 0.25, 0.5, 0.75, 1.0]
	g.colors = [
		Color(1.0, 0.22, 0.22, 1.0),
		Color(1.0, 0.85, 0.12, 1.0),
		Color(0.22, 0.85, 0.28, 1.0),
		Color(0.22, 0.52, 1.0, 1.0),
		Color(0.9, 0.22, 0.9, 1.0),
	]
	return g
