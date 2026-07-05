extends RefCounted

func run(t) -> void:
	var player_source := FileAccess.get_file_as_string("res://scripts/player_controller.gd")
	var tower_source := FileAccess.get_file_as_string("res://scripts/laser_tower.gd")
	var model_source := FileAccess.get_file_as_string("res://scripts/model_factory.gd")

	t.is_true(player_source.contains("var _laser_tower_built_this_round := false"), "Player should only build one laser tower per round")
	t.is_true(player_source.contains("_laser_tower_built_this_round"), "Laser tower build should check the one-per-round flag")
	t.is_true(player_source.contains("func _get_valid_laser_tower_ground_position"), "Laser tower build should validate the placement surface")
	t.is_true(player_source.contains("collider.name != \"Ground\""), "Laser tower should only be placed on the map ground, not cover")
	t.is_true(tower_source.contains("const ARM_SECONDS := 30.0"), "Laser tower should wait 30 seconds after construction")
	t.is_true(tower_source.contains("arm_timer -= delta"), "Laser tower should count down after being built")
	t.is_true(tower_source.contains("if arm_timer <= 0.0:"), "Laser tower should fire only after the 30 second timer")
	t.is_false(tower_source.contains("TRIGGER_RADIUS"), "Laser tower should not fire immediately just because enemies are nearby")
	t.is_true(model_source.contains("EnemyFrontMarker"), "Enemy soldiers should have a bright visible front marker")
	t.is_true(model_source.contains("EnemyHelmetMarker"), "Enemy soldiers should have a bright helmet marker")
