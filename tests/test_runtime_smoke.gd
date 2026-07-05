extends RefCounted

const MAP_REGISTRY := preload("res://scripts/map_registry.gd")

func run(t) -> void:
	_smoke_maps(t)
	_smoke_models(t)
	_smoke_weapon_resources(t)
	_smoke_save_data_scripts(t)
	_smoke_scene_resources(t)

func _smoke_maps(t) -> void:
	for map_data: Dictionary in MAP_REGISTRY.MAPS:
		var scene_path := str(map_data.get("scene", ""))
		var packed := load(scene_path) as PackedScene
		t.not_null(packed, "Map scene should load: %s" % scene_path)
		if packed == null:
			continue
		var map := packed.instantiate()
		t.is_true(map is BaseMap, "Map scene should instantiate as BaseMap: %s" % scene_path)
		if map is BaseMap:
			var base_map := map as BaseMap
			base_map._build_spawn_points()
			base_map._build_patrol_points()
			t.is_true(base_map.get_spawn_points("blue").size() >= 5, "Map should provide blue spawns: %s" % scene_path)
			t.is_true(base_map.get_spawn_points("orange").size() >= 5, "Map should provide orange spawns: %s" % scene_path)
			t.is_true(base_map.get_patrol_points().size() > 0, "Map should provide patrol points: %s" % scene_path)
		map.free()

func _smoke_models(t) -> void:
	var soldier := ModelFactory.create_soldier_model("blue")
	t.is_true(soldier.get_child_count() > 0, "Soldier model should create mesh children")
	soldier.free()
	for weapon_id in ["m416", "barrett", "knife"]:
		var fp_model := ModelFactory.create_weapon_model(weapon_id, true)
		t.is_true(fp_model.get_child_count() > 0, "First-person weapon model should create children: %s" % weapon_id)
		t.is_true(fp_model.name == "WeaponModel_%s" % weapon_id, "Weapon model should be named by id: %s" % weapon_id)
		fp_model.free()

func _smoke_weapon_resources(t) -> void:
	var weapon_paths := [
		"res://resources/weapons/m416.tres",
		"res://resources/weapons/barrett.tres",
		"res://resources/weapons/knife.tres",
	]
	for path: String in weapon_paths:
		var weapon := load(path)
		t.is_true(weapon is WeaponConfig, "Weapon resource should instantiate as WeaponConfig: %s" % path)
		if weapon is WeaponConfig:
			var cfg := weapon as WeaponConfig
			t.is_true(cfg.weapon_id.length() > 0, "Weapon should have id: %s" % path)
			t.is_true(cfg.display_name.length() > 0, "Weapon should have display name: %s" % path)
			t.is_true(cfg.damage > 0.0, "Weapon should have positive damage: %s" % path)

func _smoke_save_data_scripts(t) -> void:
	var player_data_script := load("res://scripts/player_data.gd")
	var data = player_data_script.new()
	data.reset_progress()
	t.equal(data.total_stars, 0, "PlayerData should reset stars")
	data.add_stars(3)
	t.equal(data.total_stars, 3, "PlayerData should add stars")
	t.is_true(data.has_map("city"), "PlayerData should always allow free city map")
	t.is_true(data.unlock_achievement("simo_hayha"), "PlayerData should unlock valid achievement")
	t.is_true(data.has_achievement("simo_hayha"), "PlayerData should report unlocked achievement")

	var settings_script := load("res://scripts/settings.gd")
	var settings = settings_script.new()
	settings.set_quality_mode("ultra")
	t.equal(settings.quality_mode, "ultra", "GameSettings should accept ultra quality")
	settings.set_selected_character("engineer")
	t.equal(settings.selected_character_id, "engineer", "GameSettings should accept engineer role")

func _smoke_scene_resources(t) -> void:
	var scene_paths := [
		"res://scenes/player.tscn",
		"res://scenes/mobile_controls.tscn",
		"res://scenes/projectile.tscn",
		"res://scenes/hud.tscn",
		"res://scenes/game.tscn",
		"res://scenes/main_menu.tscn",
		"res://scenes/map_select.tscn",
		"res://scenes/settings_menu.tscn",
	]
	for path: String in scene_paths:
		t.resource_exists(path, "Scene resource should exist: %s" % path)
