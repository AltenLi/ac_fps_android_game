extends CanvasLayer

var player: PlayerController = null
var joystick_base: Panel
var joystick_knob: ColorRect
var joystick_touch_id := -1
var joystick_radius := 64.0

func _ready() -> void:
	visible = OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	_build_controls()

func bind_player(new_player: PlayerController) -> void:
	player = new_player

func _build_controls() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var look_area := Control.new()
	look_area.anchor_left = 0.42
	look_area.anchor_top = 0.0
	look_area.anchor_right = 1.0
	look_area.anchor_bottom = 1.0
	look_area.mouse_filter = Control.MOUSE_FILTER_PASS
	look_area.gui_input.connect(_on_look_input)
	root.add_child(look_area)

	joystick_base = Panel.new()
	joystick_base.anchor_left = 0.0
	joystick_base.anchor_top = 1.0
	joystick_base.anchor_right = 0.0
	joystick_base.anchor_bottom = 1.0
	joystick_base.offset_left = 38
	joystick_base.offset_top = -176
	joystick_base.offset_right = 166
	joystick_base.offset_bottom = -48
	joystick_base.add_theme_stylebox_override("panel", _circle_style(Color(0.08, 0.09, 0.11, 0.52), Color(0.85, 0.54, 0.14, 0.62)))
	joystick_base.gui_input.connect(_on_joystick_input)
	root.add_child(joystick_base)

	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.85, 0.54, 0.14, 0.82)
	joystick_knob.offset_left = 47
	joystick_knob.offset_top = 47
	joystick_knob.offset_right = 81
	joystick_knob.offset_bottom = 81
	joystick_base.add_child(joystick_knob)

	var fire := _button("开火", Vector2(-160, -150), Vector2(118, 72))
	fire.button_down.connect(func() -> void:
		if player != null:
			player.set_mobile_fire(true)
	)
	fire.button_up.connect(func() -> void:
		if player != null:
			player.set_mobile_fire(false)
	)
	root.add_child(fire)

	var weapon := _button("切枪", Vector2(-292, -128), Vector2(108, 58))
	weapon.pressed.connect(func() -> void:
		if player != null:
			player.mobile_next_weapon()
	)
	root.add_child(weapon)

	var capture := _button("锁定", Vector2(-160, -232), Vector2(118, 52))
	capture.pressed.connect(func() -> void:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	root.add_child(capture)

func _button(text: String, bottom_right_offset: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = bottom_right_offset.x
	button.offset_top = bottom_right_offset.y
	button.offset_right = bottom_right_offset.x + size.x
	button.offset_bottom = bottom_right_offset.y + size.y
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _circle_style(Color(0.12, 0.12, 0.14, 0.58), Color(0.85, 0.54, 0.14, 0.72)))
	button.add_theme_stylebox_override("pressed", _circle_style(Color(0.85, 0.54, 0.14, 0.82), Color(1, 0.82, 0.45, 0.9)))
	return button

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and joystick_touch_id == -1:
			joystick_touch_id = event.index
			_update_joystick(event.position - joystick_base.global_position)
		elif not event.pressed and event.index == joystick_touch_id:
			joystick_touch_id = -1
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch_id:
		_update_joystick(event.position - joystick_base.global_position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position - joystick_base.global_position)

func _on_look_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventScreenDrag:
		player.set_mobile_look(event.relative)

func _update_joystick(local_pos: Vector2) -> void:
	var center := Vector2(64, 64)
	var vec := (local_pos - center).limit_length(joystick_radius)
	joystick_knob.position = center + vec - Vector2(17, 17)
	if player != null:
		player.set_mobile_move(vec / joystick_radius)

func _reset_joystick() -> void:
	joystick_knob.position = Vector2(47, 47)
	if player != null:
		player.set_mobile_move(Vector2.ZERO)
		player.set_mobile_fire(false)

func _circle_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	return style
