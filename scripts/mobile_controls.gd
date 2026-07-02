extends CanvasLayer

var player: PlayerController = null
var joystick_base: Panel
var joystick_knob_panel: Panel
var joystick_touch_id := -1
var joystick_mouse_active := false
var joystick_radius := 90.0
var joystick_anchor := Vector2.ZERO
var fire_touch_id := -1
var left_fire_touch_id := -1
var weapon_touch_id := -1
var _look_area: Control
var _action_button_layer: Control
var _last_weapon_button_msec := -1000000

const FIRE_BUTTON_DIAMETER := 160.0
const LEFT_FIRE_BUTTON_DIAMETER := 132.0
const JUMP_BUTTON_DIAMETER := 104.0
const WEAPON_BUTTON_DIAMETER := 104.0
const RELOAD_BUTTON_DIAMETER := 80.0
const RIGHT_FIRE_MARGIN_X := 44.0
const RIGHT_FIRE_MARGIN_Y := 82.0
const ACTION_BUTTON_GAP := 18.0
const JOYSTICK_START_X_OFFSET := 34.0
const JOYSTICK_START_Y_OFFSET := -34.0
const WEAPON_BUTTON_DEBOUNCE_MSEC := 180

func _ready() -> void:
	visible = OS.is_debug_build() or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	_build_controls()

func bind_player(new_player: PlayerController) -> void:
	player = new_player
	if player != null:
		var is_touch_device := OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
		player.set_touch_controls_active(is_touch_device)

func _process(_delta: float) -> void:
	var should_show_actions := _is_gameplay_input_enabled()
	if _action_button_layer != null:
		_action_button_layer.visible = should_show_actions
	if _look_area != null:
		var should_block := _is_gameplay_touch_enabled()
		_look_area.mouse_filter = Control.MOUSE_FILTER_STOP if should_block else Control.MOUSE_FILTER_IGNORE
		if not should_block:
			_reset_all_inputs()

func _input(event: InputEvent) -> void:
	if not visible or joystick_base == null or not _is_gameplay_input_enabled():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_width := viewport_size.x
	if event is InputEventScreenTouch:
		if event.pressed:
			if _right_fire_rect(viewport_size).has_point(event.position):
				fire_touch_id = event.index
				if player != null:
					player.set_mobile_fire(true)
				return
			if _left_fire_rect(viewport_size).has_point(event.position):
				left_fire_touch_id = event.index
				if player != null:
					player.set_mobile_fire(true)
				return
			if _reload_rect(viewport_size).has_point(event.position):
				if player != null:
					player.mobile_reload()
				return
			if _jump_rect(viewport_size).has_point(event.position):
				if player != null:
					player.mobile_jump()
				return
			if _weapon_rect(viewport_size).has_point(event.position):
				weapon_touch_id = event.index
				_request_next_weapon()
				return
			if joystick_touch_id == -1 and event.position.x < viewport_width * 0.5:
				joystick_touch_id = event.index
				joystick_anchor = event.position + Vector2(JOYSTICK_START_X_OFFSET, JOYSTICK_START_Y_OFFSET)
				_show_joystick_at(joystick_anchor)
				_update_joystick(event.position)
		elif event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_base.visible = false
			_reset_joystick()
		elif event.index == fire_touch_id:
			fire_touch_id = -1
			if player != null:
				player.set_mobile_fire(left_fire_touch_id != -1)
		elif event.index == left_fire_touch_id:
			left_fire_touch_id = -1
			if player != null:
				player.set_mobile_fire(fire_touch_id != -1)
		elif event.index == weapon_touch_id:
			weapon_touch_id = -1
	elif event is InputEventScreenDrag and event.index == joystick_touch_id:
		_update_joystick(event.position)
	elif event is InputEventScreenDrag and event.index == fire_touch_id:
		if player != null:
			player.set_mobile_look(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not joystick_mouse_active and event.position.x < viewport_width * 0.5:
			joystick_mouse_active = true
			joystick_anchor = event.position + Vector2(JOYSTICK_START_X_OFFSET, JOYSTICK_START_Y_OFFSET)
			_show_joystick_at(joystick_anchor)
			_update_joystick(event.position)
		elif not event.pressed and joystick_mouse_active:
			joystick_mouse_active = false
			joystick_base.visible = false
			_reset_joystick()
	elif event is InputEventMouseMotion and joystick_mouse_active:
		_update_joystick(event.position)

func _build_controls() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var look_area := Control.new()
	look_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP
	look_area.gui_input.connect(_on_look_input)
	root.add_child(look_area)
	_look_area = look_area

	var base_size := joystick_radius * 2.0
	joystick_base = Panel.new()
	joystick_base.size = Vector2(base_size, base_size)
	joystick_base.visible = false
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_theme_stylebox_override("panel", _circle_style(Color(0.06, 0.08, 0.10, 0.34), Color(0.12, 0.86, 1.0, 0.58), int(joystick_radius)))
	root.add_child(joystick_base)

	var knob_size := 48.0
	joystick_knob_panel = Panel.new()
	joystick_knob_panel.size = Vector2(knob_size, knob_size)
	joystick_knob_panel.position = Vector2(joystick_radius - knob_size * 0.5, joystick_radius - knob_size * 0.5)
	joystick_knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob_panel.add_theme_stylebox_override("panel", _circle_style(Color(0.12, 0.86, 1.0, 0.68), Color(0.78, 0.98, 1.0, 0.78), int(knob_size * 0.5)))
	joystick_base.add_child(joystick_knob_panel)

	var btn_layer := Control.new()
	btn_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(btn_layer)
	_action_button_layer = btn_layer

	var fire_btn := _icon_button(int(FIRE_BUTTON_DIAMETER), Color(0.90, 0.18, 0.16, 0.55), Color(1.0, 0.38, 0.32, 0.74), "fire")
	fire_btn.anchor_left = 1.0
	fire_btn.anchor_top = 1.0
	fire_btn.anchor_right = 1.0
	fire_btn.anchor_bottom = 1.0
	fire_btn.offset_left = -RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER
	fire_btn.offset_top = -RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER
	fire_btn.offset_right = -RIGHT_FIRE_MARGIN_X
	fire_btn.offset_bottom = -RIGHT_FIRE_MARGIN_Y
	fire_btn.button_down.connect(func() -> void:
		if _is_gameplay_input_enabled() and player != null:
			player.set_mobile_fire(true)
	)
	fire_btn.button_up.connect(func() -> void:
		fire_touch_id = -1
		if player != null:
			player.set_mobile_fire(left_fire_touch_id != -1)
	)
	btn_layer.add_child(fire_btn)

	var weapon_btn := _icon_button(int(WEAPON_BUTTON_DIAMETER), Color(0.18, 0.58, 0.92, 0.48), Color(0.38, 0.82, 1.0, 0.70), "weapon")
	weapon_btn.anchor_left = 1.0
	weapon_btn.anchor_top = 1.0
	weapon_btn.anchor_right = 1.0
	weapon_btn.anchor_bottom = 1.0
	var weapon_left := -RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER - ACTION_BUTTON_GAP - WEAPON_BUTTON_DIAMETER
	var weapon_top := -RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER * 0.5 - WEAPON_BUTTON_DIAMETER * 0.5
	weapon_btn.offset_left = weapon_left
	weapon_btn.offset_top = weapon_top
	weapon_btn.offset_right = weapon_left + WEAPON_BUTTON_DIAMETER
	weapon_btn.offset_bottom = weapon_top + WEAPON_BUTTON_DIAMETER
	weapon_btn.pressed.connect(func() -> void:
		if _is_gameplay_input_enabled():
			_request_next_weapon()
	)
	btn_layer.add_child(weapon_btn)

	var jump_btn := _icon_button(int(JUMP_BUTTON_DIAMETER), Color(0.62, 0.42, 0.92, 0.48), Color(0.86, 0.68, 1.0, 0.70), "jump")
	jump_btn.anchor_left = 1.0
	jump_btn.anchor_top = 1.0
	jump_btn.anchor_right = 1.0
	jump_btn.anchor_bottom = 1.0
	var jump_left := -RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER - ACTION_BUTTON_GAP - WEAPON_BUTTON_DIAMETER - ACTION_BUTTON_GAP - JUMP_BUTTON_DIAMETER
	var jump_top := -RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER * 0.5 - JUMP_BUTTON_DIAMETER * 0.5
	jump_btn.offset_left = jump_left
	jump_btn.offset_top = jump_top
	jump_btn.offset_right = jump_left + JUMP_BUTTON_DIAMETER
	jump_btn.offset_bottom = jump_top + JUMP_BUTTON_DIAMETER
	jump_btn.pressed.connect(func() -> void:
		if _is_gameplay_input_enabled() and player != null:
			player.mobile_jump()
	)
	btn_layer.add_child(jump_btn)

	var reload_btn := _icon_button(int(RELOAD_BUTTON_DIAMETER), Color(0.16, 0.42, 0.68, 0.44), Color(0.44, 0.78, 1.0, 0.62), "reload")
	reload_btn.anchor_left = 1.0
	reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0
	reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER * 0.58
	reload_btn.offset_top = -RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER - RELOAD_BUTTON_DIAMETER - 18.0
	reload_btn.offset_right = reload_btn.offset_left + RELOAD_BUTTON_DIAMETER
	reload_btn.offset_bottom = reload_btn.offset_top + RELOAD_BUTTON_DIAMETER
	reload_btn.pressed.connect(func() -> void:
		if _is_gameplay_input_enabled() and player != null:
			player.mobile_reload()
	)
	btn_layer.add_child(reload_btn)

	var left_fire_btn := _icon_button(int(LEFT_FIRE_BUTTON_DIAMETER), Color(0.90, 0.18, 0.16, 0.42), Color(1.0, 0.38, 0.32, 0.62), "fire")
	left_fire_btn.anchor_left = 0.0
	left_fire_btn.anchor_top = 0.0
	left_fire_btn.anchor_right = 0.0
	left_fire_btn.anchor_bottom = 0.0
	left_fire_btn.offset_left = 28.0
	left_fire_btn.offset_top = 142.0
	left_fire_btn.offset_right = 28.0 + LEFT_FIRE_BUTTON_DIAMETER
	left_fire_btn.offset_bottom = 142.0 + LEFT_FIRE_BUTTON_DIAMETER
	left_fire_btn.button_down.connect(func() -> void:
		if _is_gameplay_input_enabled() and player != null:
			player.set_mobile_fire(true)
	)
	left_fire_btn.button_up.connect(func() -> void:
		left_fire_touch_id = -1
		if player != null:
			player.set_mobile_fire(fire_touch_id != -1)
	)
	btn_layer.add_child(left_fire_btn)

func _show_joystick_at(screen_pos: Vector2) -> void:
	joystick_base.position = screen_pos - Vector2(joystick_radius, joystick_radius)
	joystick_base.visible = true

func _icon_button(diameter: int, bg: Color, border: Color, icon_type: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(diameter, diameter)
	btn.size = Vector2(diameter, diameter)
	btn.add_theme_stylebox_override("normal", _circle_style(bg, border, diameter / 2))
	btn.add_theme_stylebox_override("hover", _circle_style(Color(bg.r + 0.1, bg.g + 0.1, bg.b + 0.1, minf(bg.a + 0.15, 1.0)), border, diameter / 2))
	btn.add_theme_stylebox_override("pressed", _circle_style(Color(border.r * 0.9, border.g * 0.9, border.b * 0.9, 0.85), border, diameter / 2))
	var icon_label := Label.new()
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.96))
	match icon_type:
		"fire":
			icon_label.text = "F"
			icon_label.add_theme_font_size_override("font_size", diameter / 2 + 4)
		"reload":
			icon_label.text = "R"
			icon_label.add_theme_font_size_override("font_size", diameter / 2)
		"jump":
			icon_label.text = "^"
			icon_label.add_theme_font_size_override("font_size", diameter / 2 + 8)
		"weapon":
			icon_label.text = "W"
			icon_label.add_theme_font_size_override("font_size", diameter / 2)
	btn.add_child(icon_label)
	return btn

func _on_look_input(event: InputEvent) -> void:
	if not _is_gameplay_touch_enabled():
		return
	if event is InputEventScreenDrag and event.index != joystick_touch_id and event.index != fire_touch_id and event.index != left_fire_touch_id:
		if not _is_action_position(event.position):
			player.set_mobile_look(event.relative)

func _fire_rect(viewport_size: Vector2) -> Rect2:
	return _right_fire_rect(viewport_size)

func _right_fire_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(Vector2(viewport_size.x - RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER, viewport_size.y - RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER), Vector2(FIRE_BUTTON_DIAMETER, FIRE_BUTTON_DIAMETER))

func _left_fire_rect(_viewport_size: Vector2) -> Rect2:
	return Rect2(Vector2(28.0, 142.0), Vector2(LEFT_FIRE_BUTTON_DIAMETER, LEFT_FIRE_BUTTON_DIAMETER))

func _is_fire_position(position: Vector2, viewport_size: Vector2) -> bool:
	return _right_fire_rect(viewport_size).has_point(position) or _left_fire_rect(viewport_size).has_point(position)

func _reload_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(Vector2(viewport_size.x - RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER * 0.58, viewport_size.y - RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER - RELOAD_BUTTON_DIAMETER - 18.0), Vector2(RELOAD_BUTTON_DIAMETER, RELOAD_BUTTON_DIAMETER))

func _jump_rect(viewport_size: Vector2) -> Rect2:
	var jump_left := viewport_size.x - RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER - ACTION_BUTTON_GAP - WEAPON_BUTTON_DIAMETER - ACTION_BUTTON_GAP - JUMP_BUTTON_DIAMETER
	var jump_top := viewport_size.y - RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER * 0.5 - JUMP_BUTTON_DIAMETER * 0.5
	return Rect2(Vector2(jump_left, jump_top), Vector2(JUMP_BUTTON_DIAMETER, JUMP_BUTTON_DIAMETER))

func _weapon_rect(viewport_size: Vector2) -> Rect2:
	var weapon_left := viewport_size.x - RIGHT_FIRE_MARGIN_X - FIRE_BUTTON_DIAMETER - ACTION_BUTTON_GAP - WEAPON_BUTTON_DIAMETER
	var weapon_top := viewport_size.y - RIGHT_FIRE_MARGIN_Y - FIRE_BUTTON_DIAMETER * 0.5 - WEAPON_BUTTON_DIAMETER * 0.5
	return Rect2(Vector2(weapon_left, weapon_top), Vector2(WEAPON_BUTTON_DIAMETER, WEAPON_BUTTON_DIAMETER))

func _is_action_position(position: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return _is_fire_position(position, viewport_size) or _reload_rect(viewport_size).has_point(position) or _jump_rect(viewport_size).has_point(position) or _weapon_rect(viewport_size).has_point(position)

func _is_gameplay_input_enabled() -> bool:
	return visible and player != null and player.can_accept_mobile_input()

func _is_gameplay_touch_enabled() -> bool:
	return _is_gameplay_input_enabled() and player.touch_controls_active

func _request_next_weapon() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_weapon_button_msec < WEAPON_BUTTON_DEBOUNCE_MSEC:
		return
	_last_weapon_button_msec = now
	if player != null:
		player.mobile_next_weapon()

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

func _reset_all_inputs() -> void:
	joystick_touch_id = -1
	joystick_mouse_active = false
	fire_touch_id = -1
	left_fire_touch_id = -1
	weapon_touch_id = -1
	joystick_base.visible = false
	_reset_joystick()
	if player != null:
		player.set_mobile_fire(false)

func _circle_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
