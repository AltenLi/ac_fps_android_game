extends RefCounted

const WEAPON_PATHS := [
	"res://resources/weapons/m416.tres",
	"res://resources/weapons/barrett.tres",
	"res://resources/weapons/knife.tres",
]

func run(t) -> void:
	var weapon_system_source := FileAccess.get_file_as_string("res://scripts/weapon_system.gd")
	t.is_true(weapon_system_source.contains("if is_melee:\n\t\t_fire_melee"), "Knife should use melee hit detection instead of spawning bullets")
	t.is_true(weapon_system_source.contains("func _fire_melee"), "Weapon system should keep knife strikes separate from gun traces")
	t.is_true(weapon_system_source.contains("ENEMY_DAMAGE_REDUCTION := 8.0"), "Enemy damage should be reduced by 8")
	t.is_true(weapon_system_source.contains("team\", \"\")) == \"orange\""), "Damage reduction should only affect orange enemies")
	t.is_true(weapon_system_source.contains("resources/weapons/knife.tres"), "Weapon loadout should include the tactical knife")
	t.is_true(weapon_system_source.contains("if weapons[i].weapon_id == \"knife\""), "Ammo pickups should not add bullets to the knife")
	t.is_true(weapon_system_source.contains("var is_melee := weapon.weapon_id == \"knife\""), "Knife firing should bypass bullet consumption")
	t.is_true(weapon_system_source.contains("return \"近战\""), "Knife ammo text should be melee-only")
	for path in WEAPON_PATHS:
		var cfg = load(path)
		t.not_null(cfg, "Weapon resource should load: %s" % path)
		if cfg == null:
			continue
		t.is_true(str(cfg.weapon_id).length() > 0, "weapon_id cannot be empty: %s" % path)
		t.is_true(str(cfg.display_name).length() > 0, "display_name cannot be empty: %s" % path)
		t.is_true(float(cfg.damage) > 0.0, "damage must be positive: %s" % path)
		t.is_true(float(cfg.fire_cooldown) > 0.0, "fire cooldown must be positive: %s" % path)
		t.is_true(float(cfg.range) > 0.0, "range must be positive: %s" % path)
		if cfg.weapon_id == "knife":
			t.equal(int(cfg.magazine_size), 0, "Knife should not have bullets")
		else:
			t.is_true(int(cfg.magazine_size) > 0, "magazine size must be positive: %s" % path)
		t.is_true(int(cfg.reserve_ammo) >= 0, "reserve ammo cannot be negative: %s" % path)
		t.is_true(float(cfg.reload_time) > 0.0, "reload time must be positive: %s" % path)
		if cfg.weapon_id == "barrett":
			t.equal(float(cfg.damage), 105.0, "Barrett should one-shot a 100 HP AI")
			t.equal(float(cfg.fire_cooldown), 1.45, "Barrett should trade fire rate for high damage")
		if cfg.weapon_id == "knife":
			t.is_true(not bool(cfg.is_projectile), "Knife should use a close hitscan strike")
			t.equal(float(cfg.range), 1.9, "Knife should stay within close melee range")
			t.equal(float(cfg.fire_cooldown), 0.5, "Knife should swing every half second")
			t.equal(float(cfg.damage), 50.0, "Knife should deal 50 melee damage")
