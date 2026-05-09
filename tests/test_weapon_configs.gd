extends RefCounted

const WEAPON_PATHS := [
	"res://resources/weapons/m416.tres",
	"res://resources/weapons/barrett.tres",
	"res://resources/weapons/rpg.tres",
]

func run(t) -> void:
	for path in WEAPON_PATHS:
		var cfg = load(path)
		t.not_null(cfg, "武器资源必须可加载：%s" % path)
		if cfg == null:
			continue
		t.is_true(str(cfg.weapon_id).length() > 0, "weapon_id 不能为空：%s" % path)
		t.is_true(str(cfg.display_name).length() > 0, "display_name 不能为空：%s" % path)
		t.is_true(float(cfg.damage) > 0.0, "伤害必须大于 0：%s" % path)
		t.is_true(float(cfg.fire_cooldown) > 0.0, "开火冷却必须大于 0：%s" % path)
		t.is_true(float(cfg.range) > 0.0, "射程必须大于 0：%s" % path)
		t.is_true(int(cfg.magazine_size) > 0, "弹匣必须大于 0：%s" % path)
		t.is_true(int(cfg.reserve_ammo) >= 0, "备弹不能为负：%s" % path)
		t.is_true(float(cfg.reload_time) > 0.0, "装弹时间必须大于 0：%s" % path)
		if cfg.weapon_id == "barrett":
			t.equal(float(cfg.damage), 105.0, "巴雷特应能一枪击杀 100 HP AI")
			t.equal(float(cfg.fire_cooldown), 1.45, "巴雷特应以低射速换取高伤害")
		if cfg.weapon_id == "rpg":
			t.is_true(bool(cfg.is_projectile), "RPG 必须是投射物")
			t.equal(float(cfg.damage), 95.0, "RPG 直击伤害应接近击杀线")
			t.equal(float(cfg.splash_radius), 5.0, "RPG 爆炸半径应控制在 5 米")
			t.equal(float(cfg.reload_time), 2.6, "RPG 装弹时间应略快于旧版本")
