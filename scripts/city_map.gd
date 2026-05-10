class_name CityMap
extends BaseMap

## 城市巷战：沙色真实风格城市，中路/侧巷/掩体

func _ready() -> void:
	ground_color = Color(0.58, 0.43, 0.23, 1)
	sky_color = Color(0.55, 0.63, 0.75, 1)
	ambient_color = Color(0.88, 0.78, 0.62, 1)
	super._ready()

func _build_terrain() -> void:
	var wall := Color(0.64, 0.49, 0.27, 1)
	var dark_wall := Color(0.42, 0.31, 0.18, 1)
	var cover := Color(0.33, 0.26, 0.19, 1)
	var accent := Color(0.76, 0.58, 0.32, 1)

	_create_box("BlueSpawnBlock", Vector3(-28, 2.0, 29), Vector3(15, 4, 8), wall)
	_create_box("OrangeSpawnBlock", Vector3(28, 2.0, -29), Vector3(15, 4, 8), wall)

	_create_box("MidGateLeft", Vector3(-5.8, 2.5, 0), Vector3(4, 5, 12), dark_wall)
	_create_box("MidGateRight", Vector3(5.8, 2.5, 0), Vector3(4, 5, 12), dark_wall)
	_create_box("MidGateTop", Vector3(0, 6.0, 0), Vector3(15, 2, 12), dark_wall)

	_create_box("LongA_WallA", Vector3(-25, 2.2, -12), Vector3(5, 4.4, 34), wall)
	_create_box("LongA_WallB", Vector3(-12, 2.2, -25), Vector3(24, 4.4, 5), wall)
	_create_box("LongA_Corner", Vector3(-30, 2.2, -30), Vector3(12, 4.4, 10), dark_wall)

	_create_box("SideAlley_WallA", Vector3(25, 2.2, 12), Vector3(5, 4.4, 34), wall)
	_create_box("SideAlley_WallB", Vector3(12, 2.2, 25), Vector3(24, 4.4, 5), wall)
	_create_box("SideAlley_Corner", Vector3(30, 2.2, 30), Vector3(12, 4.4, 10), dark_wall)

	_create_box("CentralCoverA", Vector3(-12, 0.9, 8), Vector3(7, 1.8, 3), cover)
	_create_box("CentralCoverB", Vector3(12, 0.9, -8), Vector3(7, 1.8, 3), cover)
	_create_box("CrateStackA", Vector3(-2, 1.2, 16), Vector3(4, 2.4, 4), cover)
	_create_box("CrateStackB", Vector3(2, 1.2, -16), Vector3(4, 2.4, 4), cover)
	_create_box("MarketCover", Vector3(17, 0.9, 7), Vector3(9, 1.8, 3), cover)
	_create_box("TunnelCover", Vector3(-17, 0.9, -7), Vector3(9, 1.8, 3), cover)

	_create_box("BluePlatform", Vector3(-30, 1.3, 16), Vector3(12, 2.6, 9), accent)
	_create_box("OrangePlatform", Vector3(30, 1.3, -16), Vector3(12, 2.6, 9), accent)
	_create_box("BlueRamp", Vector3(-23, 0.45, 18), Vector3(7, 0.9, 5), Color(0.5, 0.37, 0.22, 1))
	_create_box("OrangeRamp", Vector3(23, 0.45, -18), Vector3(7, 0.9, 5), Color(0.5, 0.37, 0.22, 1))

	for i in range(8):
		var z := -28.0 + float(i) * 8.0
		_create_box("SmallCoverLeft%d" % i, Vector3(-34, 0.75, z), Vector3(4, 1.5, 3), cover)
		_create_box("SmallCoverRight%d" % i, Vector3(34, 0.75, -z), Vector3(4, 1.5, 3), cover)
	_add_theme_props("city")
