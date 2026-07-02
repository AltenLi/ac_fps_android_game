extends Node

const KEY_ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_backward": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"weapon_next": [KEY_Q],
	"weapon_1": [KEY_1],
	"weapon_2": [KEY_2],
	"weapon_3": [KEY_3],
	"reload": [KEY_R],
	"scope_zoom": [KEY_Z],
	"throw_grenade": [KEY_G],
	"capture_mouse": [KEY_TAB]
}

func _ready() -> void:
	_setup_keyboard_actions()
	_setup_mouse_actions()

func _setup_keyboard_actions() -> void:
	for action in KEY_ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in KEY_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

func _setup_mouse_actions() -> void:
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
	var fire_event := InputEventMouseButton.new()
	fire_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", fire_event)
	if not InputMap.has_action("scope_zoom"):
		InputMap.add_action("scope_zoom")
	var scope_event := InputEventMouseButton.new()
	scope_event.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("scope_zoom", scope_event)
