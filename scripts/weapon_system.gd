class_name WeaponSystem
extends Node

signal weapon_changed(display_name: String)
signal weapon_fired(weapon_id: String)
signal ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal reload_started(weapon_id: String)

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const WEAPON_PATHS := [
	"res://resources/weapons/m416.tres",
	"res://resources/weapons/barrett.tres",
	"res://resources/weapons/rpg.tres"
]

var weapons: Array[WeaponConfig] = []
var current_index := 0
var next_fire_time := 0.0
var magazine_ammo: Array[int] = []
var reserve_ammo: Array[int] = []
var is_reloading := false
var reload_finish_time := 0.0

func _ready() -> void:
	_load_weapons()
	if not weapons.is_empty():
		weapon_changed.emit(get_current_weapon_name())
		_emit_ammo_changed()

func _process(_delta: float) -> void:
	_update_reload_state()

func get_current_weapon_name() -> String:
	if weapons.is_empty():
		return "无武器"
	return weapons[current_index].display_name

func get_current_weapon_id() -> String:
	if weapons.is_empty():
		return ""
	return weapons[current_index].weapon_id

func get_current_ammo() -> int:
	if weapons.is_empty():
		return 0
	return magazine_ammo[current_index]

func get_current_reserve() -> int:
	if weapons.is_empty():
		return 0
	return reserve_ammo[current_index]

func get_current_ammo_text() -> String:
	if weapons.is_empty():
		return "0 / 0"
	var suffix := " 装弹中" if is_reloading else ""
	return "%d / %d%s" % [get_current_ammo(), get_current_reserve(), suffix]

func select_weapon(index: int) -> void:
	if weapons.is_empty():
		return
	is_reloading = false
	current_index = clampi(index, 0, weapons.size() - 1)
	weapon_changed.emit(get_current_weapon_name())
	_emit_ammo_changed()

func next_weapon() -> void:
	if weapons.is_empty():
		return
	is_reloading = false
	current_index = (current_index + 1) % weapons.size()
	weapon_changed.emit(get_current_weapon_name())
	_emit_ammo_changed()

func start_reload() -> bool:
	if weapons.is_empty() or is_reloading:
		return false
	var weapon := weapons[current_index]
	if magazine_ammo[current_index] >= weapon.magazine_size or reserve_ammo[current_index] <= 0:
		return false
	is_reloading = true
	reload_finish_time = Time.get_ticks_msec() / 1000.0 + weapon.reload_time
	reload_started.emit(weapon.weapon_id)
	_emit_ammo_changed()
	return true

func try_fire(origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String) -> bool:
	if weapons.is_empty() or shooter == null:
		return false
	_update_reload_state()
	if is_reloading:
		return false
	if magazine_ammo[current_index] <= 0:
		start_reload()
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < next_fire_time:
		return false
	var weapon := weapons[current_index]
	magazine_ammo[current_index] -= 1
	next_fire_time = now + weapon.fire_cooldown
	weapon_fired.emit(weapon.weapon_id)
	_emit_ammo_changed()
	if weapon.is_projectile:
		_spawn_projectile(weapon, origin, direction.normalized(), shooter, enemy_team)
	else:
		_fire_hitscan(weapon, origin, direction.normalized(), shooter, enemy_team)
	if magazine_ammo[current_index] <= 0 and reserve_ammo[current_index] > 0:
		start_reload()
	return true

func _load_weapons() -> void:
	weapons.clear()
	magazine_ammo.clear()
	reserve_ammo.clear()
	for path in WEAPON_PATHS:
		var resource := load(path)
		if resource is WeaponConfig:
			var weapon := resource as WeaponConfig
			weapons.append(weapon)
			magazine_ammo.append(weapon.magazine_size)
			reserve_ammo.append(weapon.reserve_ammo)

func _update_reload_state() -> void:
	if not is_reloading:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < reload_finish_time:
		return
	_finish_reload()

func _finish_reload() -> void:
	if weapons.is_empty():
		is_reloading = false
		return
	var weapon := weapons[current_index]
	var need := weapon.magazine_size - magazine_ammo[current_index]
	var amount := mini(need, reserve_ammo[current_index])
	magazine_ammo[current_index] += amount
	reserve_ammo[current_index] -= amount
	is_reloading = false
	_emit_ammo_changed()

func _emit_ammo_changed() -> void:
	ammo_changed.emit(get_current_ammo(), get_current_reserve(), is_reloading)

func _fire_hitscan(weapon: WeaponConfig, origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String) -> void:
	var space := shooter.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * weapon.range)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if shooter is CollisionObject3D:
		query.exclude = [(shooter as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var health := _find_health(hit.get("collider"))
	if health != null and health.team == enemy_team:
		health.apply_damage(weapon.damage, shooter, weapon.weapon_id)

func _spawn_projectile(weapon: WeaponConfig, origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	shooter.get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin + direction * 1.0
	projectile.setup(direction, shooter, enemy_team, weapon.damage, weapon.splash_radius, weapon.projectile_speed, weapon.range)

func _find_health(target: Variant) -> Health:
	if target == null or not (target is Node):
		return null
	var node := target as Node
	while node != null:
		if node is Health:
			return node as Health
		if node.has_node("Health"):
			return node.get_node("Health") as Health
		node = node.get_parent()
	return null
