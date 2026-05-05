class_name PlayerController
extends CharacterBody3D

signal player_health_changed(current_health: float, max_health: float)
signal player_weapon_changed(display_name: String)
signal player_ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal player_died

const SPEED := 7.2
const JUMP_VELOCITY := 6.5

var team := "blue"
var enemy_team := "orange"
var match_manager: Node = null
var camera: Camera3D
var health: Health
var weapon_system: WeaponSystem
var mobile_move := Vector2.ZERO
var mobile_fire_down := false
var weapon_holder: Node3D
var current_weapon_model: Node3D
var _pitch := 0.0
var _dead := false

func _ready() -> void:
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup(manager: Node, new_team: String) -> void:
	match_manager = manager
	team = new_team
	enemy_team = "orange" if team == "blue" else "blue"
	if health != null:
		health.reset(team, 120.0)

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value.limit_length(1.0)

func set_mobile_look(delta: Vector2) -> void:
	_apply_look(delta.x, delta.y)

func set_mobile_fire(pressed: bool) -> void:
	mobile_fire_down = pressed

func mobile_next_weapon() -> void:
	if weapon_system != null:
		weapon_system.next_weapon()

func mobile_reload() -> void:
	if weapon_system != null:
		weapon_system.start_reload()

func get_health() -> Health:
	return health

func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative.x, event.relative.y)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("weapon_next"):
		weapon_system.next_weapon()
	if event.is_action_pressed("weapon_1"):
		weapon_system.select_weapon(0)
	if event.is_action_pressed("weapon_2"):
		weapon_system.select_weapon(1)
	if event.is_action_pressed("weapon_3"):
		weapon_system.select_weapon(2)
	if event.is_action_pressed("reload"):
		weapon_system.start_reload()

func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_movement(delta)
	if Input.is_action_pressed("fire") or mobile_fire_down:
		weapon_system.try_fire(camera.global_position, -camera.global_transform.basis.z, self, enemy_team)

func _apply_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if mobile_move.length() > 0.05:
		input_dir = mobile_move
	var direction := (global_transform.basis.x * input_dir.x + global_transform.basis.z * input_dir.y).normalized()
	if direction.length() > 0.01:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _apply_look(relative_x: float, relative_y: float) -> void:
	var sensitivity: float = GameSettings.mouse_sensitivity
	rotate_y(deg_to_rad(-relative_x * sensitivity))
	_pitch = clampf(_pitch - deg_to_rad(relative_y * sensitivity), deg_to_rad(-82), deg_to_rad(82))
	camera.rotation.x = _pitch

func _build_body() -> void:
	if has_node("CollisionShape3D"):
		return
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	var body_model := ModelFactory.create_soldier_model(team)
	body_model.name = "BodyModel"
	body_model.visible = false
	add_child(body_model)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = 78
	camera.current = true
	add_child(camera)

	weapon_holder = Node3D.new()
	weapon_holder.name = "WeaponHolder"
	weapon_holder.position = Vector3(0.38, -0.24, -0.72)
	camera.add_child(weapon_holder)

	health = Health.new()
	health.name = "Health"
	health.reset(team, 120.0)
	health.health_changed.connect(func(current: float, max_value: float) -> void:
		player_health_changed.emit(current, max_value)
	)
	health.died.connect(_on_died)
	add_child(health)

	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	weapon_system.weapon_changed.connect(func(display_name: String) -> void:
		player_weapon_changed.emit(display_name)
		_refresh_weapon_model()
	)
	weapon_system.ammo_changed.connect(func(current: int, reserve: int, reloading: bool) -> void:
		player_ammo_changed.emit(current, reserve, reloading)
	)
	add_child(weapon_system)
	call_deferred("_refresh_weapon_model")

func _refresh_weapon_model() -> void:
	if weapon_holder == null or weapon_system == null:
		return
	if current_weapon_model != null:
		current_weapon_model.queue_free()
	current_weapon_model = ModelFactory.create_weapon_model(weapon_system.get_current_weapon_id(), true)
	current_weapon_model.position = Vector3.ZERO
	weapon_holder.add_child(current_weapon_model)

func _on_died(_killer: Node, _weapon_id: String) -> void:
	_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit()
