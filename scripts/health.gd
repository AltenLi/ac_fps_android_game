class_name Health
extends Node

signal health_changed(current_health: float, max_health: float)
signal died(killer: Node, weapon_id: String)

@export var team := "neutral"
@export var max_health := 100.0

var current_health := 100.0
var is_alive := true

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func reset(new_team: String, new_max_health: float = 100.0) -> void:
	team = new_team
	max_health = new_max_health
	current_health = max_health
	is_alive = true
	health_changed.emit(current_health, max_health)

func apply_damage(amount: float, attacker: Node = null, weapon_id: String = "") -> void:
	if not is_alive or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die(attacker, weapon_id)

func heal(amount: float) -> void:
	if not is_alive:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func _die(killer: Node, weapon_id: String) -> void:
	if not is_alive:
		return
	is_alive = false
	died.emit(killer, weapon_id)
