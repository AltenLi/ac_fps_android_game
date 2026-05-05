extends CanvasLayer

var player: PlayerController = null
var joystick_base: Panel
var joystick_knob_panel: Panel
var joystick_touch_id := -1
var joystick_mouse_active := false
var joystick_radius := 90.0
## 浮动摇杆中心：手指首次触摸的屏幕坐标（每次按下时更新）
var joystick_anchor := Vector2.ZERO
var _look_area: Control

func _ready() -> void:
	visible = OS.is_debug_build() or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	_build_controls()

func bind_player(new_player: PlayerController) -> void:
	player = new_player
	if player != null:
		## 仅在真实触屏设备（Android/iOS 或系统报告有触屏）时启用触控模式
		## Debug 桌面构建 visible=true 但并非触屏设备，不应屏蔽鼠标开火
		var is_touch_device := OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
		player.set_touch_controls_active(is_touch_device)

func _process(_delta: float) -> void:
	## 比赛结束（鼠标变为 VISIBLE）时停止 look_area 拦截，让结果面板按钮可点
	if _look_area != null:
		var should_block := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		_look_area.mouse_filter = Control.MOUSE_FILTER_STOP if should_block else Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not visible or joystick_base == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	## 触屏：左半屏触摸启动浮动摇杆
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_id == -1 and event.position.x < viewport_width * 0.5:
			joystick_touch_id = event.index
			joystick_anchor = event.position
			_show_joystick_at(joystick_anchor)
			_update_joystick(event.position)
		elif not event.pressed and event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_base.visible = false
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch_id:
		_update_joystick(event.position)
	## 鼠标（PC 调试用）：左半屏点击启动浮动摇杆
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not joystick_mouse_active and event.position.x < viewport_width * 0.5:
			joystick_mouse_active = true
			joystick_anchor = event.position
			_show_joystick_at(joystick_anchor)
			_update_joystick(event.position)
		elif not event.pressed and joystick_mouse_active:
			joystick_mouse_active = false
			joystick_base.visible = false
			_reset_joystick()
	elif event is InputEventMouseMotion and joystick_mouse_active:
		_update_joystick(event.position)

func _build_controls() -> void:
	## 底层：视野控制区 + 摇杆底盘（look_area 全屏覆盖）
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	## 视野控制区（全屏，仅处理非摇杆触点的拖动事件）
	var look_area := Control.new()
	look_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP
	look_area.gui_input.connect(_on_look_input)
	root.add_child(look_area)
	_look_area = look_area

	## 浮动摇杆底盘：初始隐藏，触摸时跟随手指位置显示
	var base_size := joystick_radius * 2
	joystick_base = Panel.new()
	joystick_base.size = Vector2(base_size, base_size)
	joystick_base.position = Vector2.ZERO
	joystick_base.visible = false
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_theme_stylebox_override("panel", _circle_style(
		Color(0.08, 0.09, 0.11, 0.30), Color(0.85, 0.54, 0.14, 0.50), int(joystick_radius)))
	root.add_child(joystick_base)

	var knob_size := 48.0
	joystick_knob_panel = Panel.new()
	joystick_knob_panel.size = Vector2(knob_size, knob_size)
	joystick_knob_panel.position = Vector2(joystick_radius - knob_size * 0.5, joystick_radius - knob_size * 0.5)
	joystick_knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob_panel.add_theme_stylebox_override("panel", _circle_style(
		Color(0.85, 0.54, 0.14, 0.60), Color(1.0, 0.78, 0.3, 0.70), int(knob_size * 0.5)))
	joystick_base.add_child(joystick_knob_panel)

	## ---- 上层：操作按钮容器（独立层，保证在 look_area 之上接收输入）----
	var btn_layer := Control.new()
	btn_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(btn_layer)  ## 直接挂在 CanvasLayer，z 序高于 root

	## ---- 右下角操作按钮布局 ----
	## 参考坐标（anchor 右下角 1,1）：
	##   开火   160×160 offset(-200,-240,-40,-80)   底部在屏幕下方 80px 处（说明栏上方）
	##   装弹    80×80  offset(-160,-330,-80,-250)   紧贴开火上方 10px
	##   切枪    72×72  offset(-242,-326,-170,-254)  装弹左侧 10px，垂直居中对齐

	## 开火按钮（最大，右下角）
	var fire_btn := _icon_button(160, Color(0.88, 0.22, 0.18, 0.55), Color(1.0, 0.35, 0.30, 0.72), "fire")
	fire_btn.anchor_left = 1.0; fire_btn.anchor_top = 1.0
	fire_btn.anchor_right = 1.0; fire_btn.anchor_bottom = 1.0
	fire_btn.offset_left = -200; fire_btn.offset_top = -240
	fire_btn.offset_right = -40;  fire_btn.offset_bottom = -80
	fire_btn.button_down.connect(func() -> void:
		if player != null: player.set_mobile_fire(true)
	)
	fire_btn.button_up.connect(func() -> void:
		if player != null: player.set_mobile_fire(false)
	)
	btn_layer.add_child(fire_btn)

	## 装弹按钮（中等，开火正上方）
	var reload_btn := _icon_button(80, Color(0.22, 0.52, 0.88, 0.50), Color(0.38, 0.68, 1.0, 0.70), "reload")
	reload_btn.anchor_left = 1.0; reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0; reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -160; reload_btn.offset_top = -330
	reload_btn.offset_right = -80;  reload_btn.offset_bottom = -250
	reload_btn.pressed.connect(func() -> void:
		if player != null: player.mobile_reload()
	)
	btn_layer.add_child(reload_btn)

	## 切枪按钮（装弹左侧，垂直居中对齐装弹）
	var weapon_btn := _icon_button(72, Color(0.22, 0.68, 0.42, 0.45), Color(0.38, 0.88, 0.58, 0.65), "weapon")
	weapon_btn.anchor_left = 1.0; weapon_btn.anchor_top = 1.0
	weapon_btn.anchor_right = 1.0; weapon_btn.anchor_bottom = 1.0
	weapon_btn.offset_left = -242; weapon_btn.offset_top = -326
	weapon_btn.offset_right = -170; weapon_btn.offset_bottom = -254
	weapon_btn.pressed.connect(func() -> void:
		if player != null: player.mobile_next_weapon()
	)
	btn_layer.add_child(weapon_btn)

func _show_joystick_at(screen_pos: Vector2) -> void:
	joystick_base.position = screen_pos - Vector2(joystick_radius, joystick_radius)
	joystick_base.visible = true

## 创建圆形图标按钮，用 Label 绘制 Emoji 图标
func _icon_button(diameter: int, bg: Color, border: Color, icon_type: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(diameter, diameter)
	btn.size = Vector2(diameter, diameter)
	btn.add_theme_stylebox_override("normal", _circle_style(bg, border, diameter / 2))
	btn.add_theme_stylebox_override("hover", _circle_style(
		Color(bg.r + 0.1, bg.g + 0.1, bg.b + 0.1, minf(bg.a + 0.15, 1.0)), border, diameter / 2))
	btn.add_theme_stylebox_override("pressed", _circle_style(
		Color(border.r * 0.9, border.g * 0.9, border.b * 0.9, 0.85), border, diameter / 2))
	## 在按钮上叠加 Label（Emoji 图标代替图片，简洁且无需资源文件）
	var icon_label := Label.new()
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match icon_type:
		"fire":
			icon_label.text = "🔫"
			icon_label.add_theme_font_size_override("font_size", diameter / 2 + 4)
		"reload":
			icon_label.text = "↺"
			icon_label.add_theme_font_size_override("font_size", diameter / 2 + 6)
			icon_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.95))
		"weapon":
			icon_label.text = "⇄"
			icon_label.add_theme_font_size_override("font_size", diameter / 2 + 2)
			icon_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.90, 0.95))
	btn.add_child(icon_label)
	return btn

func _on_look_input(event: InputEvent) -> void:
	if player == null:
		return
	## 跳过摇杆正在使用的触点，避免摇杆拖动同时旋转视角
	if event is InputEventScreenDrag and event.index != joystick_touch_id:
		player.set_mobile_look(event.relative)

func _update_joystick(screen_pos: Vector2) -> void:
	var vec := (screen_pos - joystick_anchor).limit_length(joystick_radius)
	var knob_size := 48.0
	joystick_knob_panel.position = Vector2(joystick_radius, joystick_radius) + vec - Vector2(knob_size * 0.5, knob_size * 0.5)
	if player != null:
		player.set_mobile_move(vec / joystick_radius)

func _reset_joystick() -> void:
	var knob_size := 48.0
	joystick_knob_panel.position = Vector2(joystick_radius - knob_size * 0.5, joystick_radius - knob_size * 0.5)
	if player != null:
		player.set_mobile_move(Vector2.ZERO)
		player.set_mobile_fire(false)

func _circle_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
