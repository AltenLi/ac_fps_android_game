class_name JungleMap
extends BaseMap

## 丛林营地：绿色地面，树桩/植被掩体，弯曲通道

func _ready() -> void:
	ground_color = Color(0.22, 0.40, 0.16, 1)
	sky_color = Color(0.38, 0.56, 0.30, 1)
	ambient_color = Color(0.55, 0.72, 0.38, 1)
	sun_energy = 1.6
	super._ready()

func _build_terrain() -> void:
	var bark := Color(0.35, 0.22, 0.10, 1)
	var leaf := Color(0.08, 0.30, 0.08, 1)
	var dark_green := Color(0.16, 0.30, 0.10, 1)
	var mud := Color(0.28, 0.20, 0.10, 1)
	var thatch := Color(0.42, 0.31, 0.12, 1)
	var stone := Color(0.40, 0.38, 0.28, 1)

	## 丛林一眼识别：泥路 + 圆柱树干 + 球状树冠，不再是方柱森林
	_create_box("MudTrailMain", Vector3(0, 0.07, 0), Vector3(9.0, 0.10, 74), mud, Vector3(0, 9, 0), "ground", false)
	_create_box("MudTrailCross", Vector3(0, 0.08, 0), Vector3(70, 0.10, 7.5), mud.darkened(0.08), Vector3(0, -8, 0), "ground", false)

	var trees := [
		Vector3(-14, 2.7, -14), Vector3(-24, 2.7, 4), Vector3(-8, 2.7, 22),
		Vector3(14, 2.7, 14), Vector3(24, 2.7, -4), Vector3(8, 2.7, -22),
		Vector3(-33, 2.7, -24), Vector3(33, 2.7, 24), Vector3(-34, 2.7, 20), Vector3(34, 2.7, -20)
	]
	for i in range(trees.size()):
		var p: Vector3 = trees[i]
		_create_cylinder("TreeTrunk%d" % i, p, 0.55, 5.4, bark, Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), "bark", true)
		_create_sphere("TreeCanopy%d" % i, p + Vector3(0, 3.6, 0), Vector3(2.4, 1.25, 2.4), leaf if i % 2 == 0 else dark_green, "leaf", false)
		_create_cylinder("HangingVine%d" % i, p + Vector3(0.8, 3.1, 0.3), 0.055, 2.7, Color(0.06, 0.22, 0.05, 1), Vector3(12, 0, 18), "leaf", false)

	## 木屋改成有茅草斜屋顶的营地
	_create_box("CampHutA", Vector3(-24, 1.8, 16), Vector3(10, 3.6, 7), mud, Vector3.ZERO, "wood")
	_create_box("CampHutARoofL", Vector3(-26.8, 4.2, 16), Vector3(6.2, 0.55, 8.4), thatch, Vector3(0, 0, -18), "wood", false)
	_create_box("CampHutARoofR", Vector3(-21.2, 4.2, 16), Vector3(6.2, 0.55, 8.4), thatch, Vector3(0, 0, 18), "wood", false)
	_create_box("CampHutB", Vector3(24, 1.8, -16), Vector3(10, 3.6, 7), mud, Vector3.ZERO, "wood")
	_create_box("CampHutBRoofL", Vector3(21.2, 4.2, -16), Vector3(6.2, 0.55, 8.4), thatch, Vector3(0, 0, -18), "wood", false)
	_create_box("CampHutBRoofR", Vector3(26.8, 4.2, -16), Vector3(6.2, 0.55, 8.4), thatch, Vector3(0, 0, 18), "wood", false)

	## 植被和岩石掩体更自然
	var bushes := [Vector3(-13, 0.9, 7), Vector3(13, 0.9, -7), Vector3(-4, 0.9, 25), Vector3(4, 0.9, -25), Vector3(-22, 0.9, -7), Vector3(22, 0.9, 7)]
	for i in range(bushes.size()):
		_create_sphere("BushCluster%d" % i, bushes[i], Vector3(2.3, 0.75, 1.8), dark_green, "leaf", true)

	_create_rock("JungleRockA", Vector3(-31, 1.0, 0), Vector3(2.2, 1.0, 2.8), stone, "stone", true)
	_create_rock("JungleRockB", Vector3(31, 1.0, 0), Vector3(2.2, 1.0, 2.8), stone, "stone", true)
	_create_rock("JungleRockC", Vector3(0, 1.0, 31), Vector3(2.8, 1.0, 2.2), stone, "stone", true)
	_create_rock("JungleRockD", Vector3(0, 1.0, -31), Vector3(2.8, 1.0, 2.2), stone, "stone", true)
	_add_theme_props("jungle")

func _build_patrol_points() -> void:
	patrol_points = [
		Vector3(0, 1.1, 0), Vector3(-16, 1.1, 2), Vector3(16, 1.1, -2),
		Vector3(-7, 1.1, -16), Vector3(7, 1.1, 16),
		Vector3(-26, 1.1, -18), Vector3(26, 1.1, 18),
		Vector3(-6, 1.1, -32), Vector3(6, 1.1, 32)
	]
	for i in range(patrol_points.size()):
		_create_marker("Patrol%d" % i, patrol_points[i])
