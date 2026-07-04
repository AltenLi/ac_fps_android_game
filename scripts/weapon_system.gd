class_name WeaponSystem
extends Node

signal weapon_changed(display_name: String)
signal weapon_fired(weapon_id: String)
signal ammo_changed(current_ammo: int, reserve_ammo: int, is_reloading: bool)
signal reload_started(weapon_id: String)
signal enemy_hit  ## 子弹命中敌方时发出，供 HUD 显示命中标记
signal damage_dealt(amount: float, hit_position: Vector3)  ## 命中位置 + 伤害量，供浮动数字

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const WEAPON_PATHS := [
	"res://resources/weapons/m416.tres",
	"res://resources/weapons/barrett.tres",
	"res://resources/weapons/knife.tres"
]
const ENEMY_DAMAGE_REDUCTION := 8.0

var weapons: Array[WeaponConfig] = []
var current_index := 0
var next_fire_time := 0.0
var magazine_ammo: Array[int] = []
var reserve_ammo: Array[int] = []
var is_reloading := false
var reload_finish_time := 0.0
## 供准星读取：上次开枪时刻（秒）
var last_fire_time := -999.0

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
	if _is_current_weapon_melee():
		return 0
	return magazine_ammo[current_index]

func get_current_reserve() -> int:
	if weapons.is_empty():
		return 0
	if _is_current_weapon_melee():
		return 0
	return reserve_ammo[current_index]

func get_current_ammo_text() -> String:
	if weapons.is_empty():
		return "0 / 0"
	if _is_current_weapon_melee():
		return "近战"
	var suffix := " 装弹中" if is_reloading else ""
	return "%d / %d%s" % [get_current_ammo(), get_current_reserve(), suffix]

func add_two_magazines_to_all() -> bool:
	if weapons.is_empty():
		return false
	var added := false
	for i in range(weapons.size()):
		if weapons[i].weapon_id == "knife":
			continue
		reserve_ammo[i] += weapons[i].magazine_size * 2
		added = true
	_emit_ammo_changed()
	return added

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
	if weapon.weapon_id == "knife":
		return false
	if magazine_ammo[current_index] >= weapon.magazine_size or reserve_ammo[current_index] <= 0:
		return false
	is_reloading = true
	reload_finish_time = Time.get_ticks_msec() / 1000.0 + weapon.reload_time
	SoundManager.play_reload()
	reload_started.emit(weapon.weapon_id)
	_emit_ammo_changed()
	return true

func try_fire(origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String, visual_origin: Vector3 = Vector3.ZERO) -> bool:
	if weapons.is_empty() or shooter == null:
		return false
	_update_reload_state()
	if is_reloading:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < next_fire_time:
		return false
	var weapon := weapons[current_index]
	var is_melee := weapon.weapon_id == "knife"
	if not is_melee and magazine_ammo[current_index] <= 0:
		SoundManager.play_empty_click()
		start_reload()
		return false
	if not is_melee:
		magazine_ammo[current_index] -= 1
	next_fire_time = now + weapon.fire_cooldown
	last_fire_time = now
	var shot_position := visual_origin if visual_origin != Vector3.ZERO else origin
	if is_melee:
		SoundManager.play_melee(shot_position, true)
	else:
		SoundManager.play_shot(weapon.weapon_id, shot_position, true)
	weapon_fired.emit(weapon.weapon_id)
	_emit_ammo_changed()
	if is_melee:
		_fire_melee(weapon, origin, direction.normalized(), shooter, enemy_team)
	elif weapon.is_projectile:
		_spawn_projectile(weapon, origin, direction.normalized(), shooter, enemy_team)
	else:
		var tracer_from := visual_origin if visual_origin != Vector3.ZERO else origin
		_fire_hitscan(weapon, origin, direction.normalized(), shooter, enemy_team, tracer_from)
	if not is_melee and magazine_ammo[current_index] <= 0 and reserve_ammo[current_index] > 0:
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

func _is_current_weapon_melee() -> bool:
	return not weapons.is_empty() and weapons[current_index].weapon_id == "knife"

func _fire_melee(weapon: WeaponConfig, origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String) -> void:
	var space := shooter.get_world_3d().direct_space_state
	var end_point := origin + direction * weapon.range
	var query := PhysicsRayQueryParameters3D.create(origin, end_point)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if shooter is CollisionObject3D:
		query.exclude = [(shooter as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var health := _find_health(hit.get("collider"))
	if health != null and health.team == enemy_team:
		var damage := _get_effective_damage(weapon, shooter)
		health.apply_damage(damage, shooter, weapon.weapon_id)
		enemy_hit.emit()
		damage_dealt.emit(damage, hit.get("position") as Vector3)

func _fire_hitscan(weapon: WeaponConfig, origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String, tracer_from: Vector3 = Vector3.ZERO) -> void:
	var spread_dir := _spread_direction(direction, weapon.spread_angle)
	var space := shooter.get_world_3d().direct_space_state
	var end_point := origin + spread_dir * weapon.range
	var query := PhysicsRayQueryParameters3D.create(origin, end_point)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if shooter is CollisionObject3D:
		query.exclude = [(shooter as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	var hit_pos := hit.get("position") as Vector3 if not hit.is_empty() else end_point
	var from := tracer_from if tracer_from != Vector3.ZERO else origin
	_spawn_tracer(shooter, from, hit_pos, weapon.tracer_color)
	if hit.is_empty():
		return
	var health := _find_health(hit.get("collider"))
	if health != null and health.team == enemy_team:
		var damage := _get_effective_damage(weapon, shooter)
		health.apply_damage(damage, shooter, weapon.weapon_id)
		enemy_hit.emit()
		damage_dealt.emit(damage, hit_pos)

## 在命中点和开枪位置之间绘制一条短暂的弹道线（0.06 秒后自动消失）
func _spawn_tracer(shooter: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var scene_root := shooter.get_tree().current_scene
	if scene_root == null:
		return
	## 用 ImmediateMesh 画一条线段
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = false
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	scene_root.add_child(mi)
	## 0.06 秒后自动删除
	var timer := scene_root.get_tree().create_timer(0.06)
	timer.timeout.connect(func() -> void: mi.queue_free())

## 在 direction 周围随机偏转最多 half_angle 弧度，返回新方向
func _spread_direction(direction: Vector3, half_angle: float) -> Vector3:
	if half_angle <= 0.0:
		return direction
	## 构造一个与 direction 垂直的随机偏移平面
	var up := Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right_vec := direction.cross(up).normalized()
	var up_vec := direction.cross(right_vec).normalized()
	var angle := randf() * half_angle
	var azimuth := randf() * TAU
	var offset := (right_vec * cos(azimuth) + up_vec * sin(azimuth)) * sin(angle)
	return (direction * cos(angle) + offset).normalized()

func _spawn_projectile(weapon: WeaponConfig, origin: Vector3, direction: Vector3, shooter: Node3D, enemy_team: String) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	shooter.get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin + direction * 1.0
	projectile.setup(direction, shooter, enemy_team, _get_effective_damage(weapon, shooter), weapon.splash_radius, weapon.projectile_speed, weapon.range)

func _get_effective_damage(weapon: WeaponConfig, shooter: Node3D) -> float:
	var damage := weapon.damage
	if shooter != null and str(shooter.get_meta("team", "")) == "orange":
		damage -= ENEMY_DAMAGE_REDUCTION
	return maxf(1.0, damage)

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
