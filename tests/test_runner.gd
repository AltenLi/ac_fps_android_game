extends SceneTree

const ASSERT_SCRIPT := preload("res://tests/test_assert.gd")
const STATUS_PATH := "res://.test_status"
const TEST_SCRIPTS := [
	"res://tests/test_map_registry.gd",
	"res://tests/test_player_data.gd",
	"res://tests/test_weapon_configs.gd",
	"res://tests/test_ai_balance.gd",
	"res://tests/test_tutorial_flow.gd",
	"res://tests/test_settings.gd",
	"res://tests/test_mobile_controls.gd",
	"res://tests/test_laser_tower.gd",
	"res://tests/test_sound_manager.gd",
	"res://tests/test_release_config.gd",
	"res://tests/test_feature_matrix.gd",
	"res://tests/test_runtime_smoke.gd",
]

func _init() -> void:
	var total_checks := 0
	var total_failures := 0
	print("\nCS 5v5 test runner")
	for path: String in TEST_SCRIPTS:
		var test_script := load(path)
		if test_script == null or not test_script.can_instantiate():
			push_error("无法加载测试：%s" % path)
			total_failures += 1
			continue
		var asserts = ASSERT_SCRIPT.new()
		var test = test_script.new()
		print("- %s" % path)
		test.run(asserts)
		total_checks += asserts.checks
		for failure: String in asserts.failures:
			total_failures += 1
			push_error("  FAIL: %s" % failure)
	if total_failures == 0:
		print("PASS: %d checks" % total_checks)
	else:
		push_error("FAILED: %d failures / %d checks" % [total_failures, total_checks])
	_write_status(total_failures)
	quit(total_failures)

func _write_status(failed_count: int) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(STATUS_PATH), FileAccess.WRITE)
	if file != null:
		file.store_string(str(failed_count))
