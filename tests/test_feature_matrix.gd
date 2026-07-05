extends RefCounted

func run(t) -> void:
	var doc := FileAccess.get_file_as_string("res://design/FEATURE_TEST_MATRIX.md")
	t.is_true(doc.length() > 0, "Feature matrix document should exist")
	var required_terms := [
		"Core Match",
		"Weapons And Combat",
		"Aiming And Movement",
		"Grenades",
		"Laser Tower",
		"AI",
		"Maps",
		"Mobile Controls",
		"Roles And Tactical Chips",
		"Progression, Tutorial, And Achievements",
		"Audio And Visuals",
		"Build And Release",
		"Double jump",
		"First-person reload animation",
		"Snow base achievement",
		"解锁成就：西蒙海耶",
		"Manual Checks Still Needed",
	]
	for term: String in required_terms:
		t.is_true(doc.contains(term), "Feature matrix should mention %s" % term)

	var runner := FileAccess.get_file_as_string("res://tests/test_runner.gd")
	t.is_true(runner.contains("res://tests/test_feature_matrix.gd"), "Feature matrix test should be part of the full test runner")
