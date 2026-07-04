class_name ModelFactory
extends RefCounted

static func create_weapon_model(weapon_id: String, first_person: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "WeaponModel_%s" % weapon_id
	match weapon_id:
		"barrett":
			_build_barrett(root)
		"knife":
			_build_knife(root)
		_:
			_build_m416(root)
	if first_person:
		root.scale = Vector3(0.82, 0.82, 0.82)
		root.rotation_degrees = Vector3(-4, -8, 0)
	else:
		root.scale = Vector3(0.58, 0.58, 0.58)
	return root

static func create_soldier_model(team: String) -> Node3D:
	var root := Node3D.new()
	root.name = "SoldierModel"
	var team_color := Color(0.15, 0.35, 0.95, 1) if team == "blue" else Color(0.95, 0.33, 0.12, 1)
	var cloth := Color(0.12, 0.15, 0.16, 1)
	var armor := Color(0.035, 0.045, 0.052, 1)
	var trim := Color(0.10, 0.90, 1.0, 1) if team == "blue" else Color(1.0, 0.38, 0.18, 1)
	var skin := Color(0.78, 0.58, 0.42, 1)
	_add_box(root, "Pelvis", Vector3(0.54, 0.28, 0.26), Vector3(0, 0.86, 0), Vector3.ZERO, cloth)
	_add_box(root, "Torso", Vector3(0.62, 0.72, 0.32), Vector3(0, 1.22, 0), Vector3.ZERO, team_color)
	_add_box(root, "Vest", Vector3(0.68, 0.5, 0.36), Vector3(0, 1.18, -0.03), Vector3.ZERO, armor)
	_add_box(root, "ChestPlate", Vector3(0.50, 0.42, 0.045), Vector3(0, 1.27, -0.235), Vector3.ZERO, armor.lightened(0.08))
	_add_box(root, "TeamCore", Vector3(0.18, 0.08, 0.035), Vector3(0, 1.34, -0.27), Vector3.ZERO, trim)
	_add_box(root, "LeftShoulderPad", Vector3(0.28, 0.15, 0.32), Vector3(-0.48, 1.54, -0.02), Vector3(0, 0, -10), armor.lightened(0.05))
	_add_box(root, "RightShoulderPad", Vector3(0.28, 0.15, 0.32), Vector3(0.48, 1.54, -0.02), Vector3(0, 0, 10), armor.lightened(0.05))
	_add_capsule(root, "Head", 0.22, 0.34, Vector3(0, 1.75, 0), Vector3.ZERO, skin)
	_add_box(root, "Helmet", Vector3(0.46, 0.17, 0.38), Vector3(0, 1.93, 0), Vector3.ZERO, armor)
	_add_box(root, "Visor", Vector3(0.36, 0.06, 0.03), Vector3(0, 1.78, -0.2), Vector3.ZERO, trim.darkened(0.25))
	_add_capsule(root, "LeftArm", 0.1, 0.72, Vector3(-0.44, 1.25, -0.05), Vector3(0, 0, -18), cloth)
	_add_capsule(root, "RightArm", 0.1, 0.72, Vector3(0.44, 1.25, -0.05), Vector3(0, 0, 18), cloth)
	_add_capsule(root, "LeftLeg", 0.12, 0.86, Vector3(-0.18, 0.38, 0), Vector3(0, 0, 0), Color(0.09, 0.1, 0.11, 1))
	_add_capsule(root, "RightLeg", 0.12, 0.86, Vector3(0.18, 0.38, 0), Vector3(0, 0, 0), Color(0.09, 0.1, 0.11, 1))
	_add_box(root, "LeftBoot", Vector3(0.2, 0.12, 0.34), Vector3(-0.18, 0.04, -0.06), Vector3.ZERO, armor)
	_add_box(root, "RightBoot", Vector3(0.2, 0.12, 0.34), Vector3(0.18, 0.04, -0.06), Vector3.ZERO, armor)
	_add_box(root, "Backpack", Vector3(0.5, 0.54, 0.18), Vector3(0, 1.18, 0.25), Vector3.ZERO, Color(0.08, 0.09, 0.08, 1))
	_add_box(root, "BeltGlow", Vector3(0.44, 0.045, 0.035), Vector3(0, 0.98, -0.21), Vector3.ZERO, trim.darkened(0.05))
	return root

static func _build_m416(root: Node3D) -> void:
	var metal := Color(0.07, 0.08, 0.075, 1)
	var rail := Color(0.015, 0.018, 0.018, 1)
	_add_box(root, "Receiver", Vector3(0.22, 0.18, 0.84), Vector3(0, 0, -0.18), Vector3.ZERO, metal)
	_add_box(root, "Handguard", Vector3(0.2, 0.15, 0.62), Vector3(0, 0.01, -0.86), Vector3.ZERO, Color(0.09, 0.1, 0.095, 1))
	_add_cylinder(root, "Barrel", 0.035, 0.72, Vector3(0, 0.02, -1.27), Vector3(90, 0, 0), Color(0.02, 0.022, 0.02, 1))
	_add_box(root, "Stock", Vector3(0.2, 0.16, 0.5), Vector3(0, -0.01, 0.42), Vector3.ZERO, metal)
	_add_box(root, "Magazine", Vector3(0.15, 0.36, 0.18), Vector3(0, -0.24, -0.1), Vector3(-10, 0, 0), Color(0.04, 0.045, 0.04, 1))
	_add_box(root, "Grip", Vector3(0.13, 0.28, 0.14), Vector3(0, -0.27, 0.18), Vector3(12, 0, 0), rail)
	_add_box(root, "TopRail", Vector3(0.18, 0.045, 0.92), Vector3(0, 0.13, -0.32), Vector3.ZERO, rail)
	_add_cylinder(root, "Muzzle", 0.05, 0.12, Vector3(0, 0.02, -1.67), Vector3(90, 0, 0), rail)
	_add_box(root, "HoloSightBase", Vector3(0.18, 0.05, 0.18), Vector3(0, 0.19, -0.35), Vector3.ZERO, rail)
	_add_box(root, "HoloSightGlass", Vector3(0.14, 0.12, 0.025), Vector3(0, 0.28, -0.43), Vector3(-8, 0, 0), Color(0.14, 0.72, 0.90, 1))
	_add_box(root, "BlueReceiverStripe", Vector3(0.235, 0.035, 0.36), Vector3(0, 0.105, -0.16), Vector3.ZERO, Color(0.10, 0.85, 1.0, 1))
	_add_box(root, "AngledGrip", Vector3(0.12, 0.24, 0.12), Vector3(0, -0.18, -0.70), Vector3(-24, 0, 0), rail)
	for i in range(5):
		_add_box(root, "HandguardSlot%d" % i, Vector3(0.215, 0.018, 0.055), Vector3(0, 0.095, -1.06 + i * 0.11), Vector3.ZERO, Color(0.16, 0.18, 0.18, 1))

static func _build_barrett(root: Node3D) -> void:
	var dark := Color(0.055, 0.055, 0.052, 1)
	_add_box(root, "Receiver", Vector3(0.28, 0.2, 1.0), Vector3(0, 0, -0.1), Vector3.ZERO, dark)
	_add_cylinder(root, "LongBarrel", 0.04, 1.42, Vector3(0, 0.02, -1.22), Vector3(90, 0, 0), Color(0.015, 0.016, 0.015, 1))
	_add_cylinder(root, "Brake", 0.08, 0.18, Vector3(0, 0.02, -1.96), Vector3(90, 0, 0), Color(0.02, 0.022, 0.02, 1))
	_add_box(root, "Stock", Vector3(0.24, 0.18, 0.66), Vector3(0, 0.0, 0.62), Vector3.ZERO, Color(0.09, 0.085, 0.075, 1))
	_add_box(root, "Magazine", Vector3(0.18, 0.46, 0.2), Vector3(0, -0.3, -0.08), Vector3(-4, 0, 0), Color(0.025, 0.025, 0.023, 1))
	_add_cylinder(root, "Scope", 0.09, 0.56, Vector3(0, 0.23, -0.2), Vector3(90, 0, 0), Color(0.02, 0.025, 0.027, 1))
	_add_cylinder(root, "ScopeLens", 0.095, 0.035, Vector3(0, 0.23, -0.5), Vector3(90, 0, 0), Color(0.12, 0.28, 0.34, 1))
	_add_cylinder(root, "ScopeRearLens", 0.095, 0.035, Vector3(0, 0.23, 0.10), Vector3(90, 0, 0), Color(0.10, 0.36, 0.46, 1))
	_add_box(root, "AntiMaterielStripe", Vector3(0.30, 0.035, 0.50), Vector3(0, 0.12, -0.28), Vector3.ZERO, Color(1.0, 0.72, 0.22, 1))
	_add_box(root, "CheekRest", Vector3(0.18, 0.08, 0.42), Vector3(0, 0.16, 0.48), Vector3.ZERO, Color(0.12, 0.115, 0.10, 1))
	_add_box(root, "BipodLeft", Vector3(0.035, 0.48, 0.035), Vector3(-0.13, -0.23, -0.85), Vector3(0, 0, -18), dark)
	_add_box(root, "BipodRight", Vector3(0.035, 0.48, 0.035), Vector3(0.13, -0.23, -0.85), Vector3(0, 0, 18), dark)

static func _build_rpg(root: Node3D) -> void:
	_add_cylinder(root, "Tube", 0.13, 1.24, Vector3(0, 0, -0.38), Vector3(90, 0, 0), Color(0.12, 0.19, 0.11, 1))
	_add_cylinder(root, "Warhead", 0.16, 0.34, Vector3(0, 0, -1.16), Vector3(90, 0, 0), Color(0.28, 0.36, 0.18, 1))
	_add_cylinder(root, "Nozzle", 0.17, 0.14, Vector3(0, 0, 0.32), Vector3(90, 0, 0), Color(0.07, 0.075, 0.065, 1))
	_add_box(root, "Grip", Vector3(0.13, 0.34, 0.14), Vector3(0, -0.28, -0.18), Vector3(12, 0, 0), Color(0.055, 0.04, 0.025, 1))
	_add_box(root, "ShoulderPad", Vector3(0.26, 0.18, 0.14), Vector3(0, -0.04, 0.36), Vector3.ZERO, Color(0.035, 0.036, 0.032, 1))
	_add_box(root, "Sight", Vector3(0.09, 0.14, 0.2), Vector3(0, 0.2, -0.25), Vector3.ZERO, Color(0.03, 0.03, 0.028, 1))

static func _build_knife(root: Node3D) -> void:
	_add_box(root, "BladeCore", Vector3(0.08, 0.025, 0.86), Vector3(0, 0.02, -0.42), Vector3.ZERO, Color(0.62, 0.76, 0.82, 1))
	_add_box(root, "BladeEdgeLeft", Vector3(0.025, 0.035, 0.78), Vector3(-0.052, 0.025, -0.44), Vector3(0, 0, -7), Color(0.88, 0.98, 1.0, 1))
	_add_box(root, "BladeEdgeRight", Vector3(0.025, 0.035, 0.78), Vector3(0.052, 0.025, -0.44), Vector3(0, 0, 7), Color(0.88, 0.98, 1.0, 1))
	_add_box(root, "Point", Vector3(0.065, 0.028, 0.20), Vector3(0, 0.02, -0.94), Vector3(0, 0, 45), Color(0.78, 0.95, 1.0, 1))
	_add_box(root, "Guard", Vector3(0.32, 0.07, 0.08), Vector3(0, -0.01, 0.03), Vector3.ZERO, Color(0.04, 0.05, 0.055, 1))
	_add_box(root, "Grip", Vector3(0.16, 0.18, 0.44), Vector3(0, -0.03, 0.31), Vector3.ZERO, Color(0.025, 0.032, 0.036, 1))
	_add_box(root, "GripStripeA", Vector3(0.17, 0.19, 0.035), Vector3(0, -0.035, 0.17), Vector3.ZERO, Color(0.12, 0.82, 0.88, 1))
	_add_box(root, "GripStripeB", Vector3(0.17, 0.19, 0.035), Vector3(0, -0.035, 0.31), Vector3.ZERO, Color(0.12, 0.82, 0.88, 1))
	_add_box(root, "Pommel", Vector3(0.20, 0.13, 0.09), Vector3(0, -0.02, 0.58), Vector3.ZERO, Color(0.05, 0.058, 0.062, 1))

static func _add_box(parent: Node3D, name: String, size: Vector3, position: Vector3, rotation_deg: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(parent, name, mesh, position, rotation_deg, color)

static func _add_capsule(parent: Node3D, name: String, radius: float, height: float, position: Vector3, rotation_deg: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return _add_mesh(parent, name, mesh, position, rotation_deg, color)

static func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, position: Vector3, rotation_deg: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	return _add_mesh(parent, name, mesh, position, rotation_deg, color)

static func _add_mesh(parent: Node3D, name: String, mesh: Mesh, position: Vector3, rotation_deg: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.position = position
	instance.rotation_degrees = rotation_deg
	instance.material_override = _make_premium_material(name, color)
	parent.add_child(instance)
	return instance

static func _make_premium_material(part_name: String, color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var kind := _infer_premium_kind(part_name, color)
	var display_color := color.lightened(0.08)
	display_color.s = minf(1.0, display_color.s * 1.08)
	display_color.a = color.a
	mat.albedo_color = display_color
	mat.albedo_texture = _make_premium_texture(part_name, display_color, kind)
	mat.roughness = 0.58
	mat.metallic = 0.08
	match kind:
		"gunmetal":
			mat.metallic = 0.72
			mat.roughness = 0.28
			mat.emission_enabled = true
			mat.emission = display_color.darkened(0.72)
			mat.emission_energy_multiplier = 0.10
		"armor":
			mat.metallic = 0.34
			mat.roughness = 0.38
			mat.emission_enabled = true
			mat.emission = display_color.darkened(0.70)
			mat.emission_energy_multiplier = 0.08
		"cloth":
			mat.roughness = 0.88
		"glass", "lens":
			mat.metallic = 0.08
			mat.roughness = 0.12
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var glass_color := display_color
			glass_color.a = minf(glass_color.a, 0.72)
			mat.albedo_color = glass_color
			mat.emission_enabled = true
			mat.emission = display_color
			mat.emission_energy_multiplier = 0.42
		"edge", "glow":
			mat.roughness = 0.24
			mat.emission_enabled = true
			mat.emission = display_color
			mat.emission_energy_multiplier = 1.65
	return mat

static func _infer_premium_kind(part_name: String, color: Color) -> String:
	var lower := part_name.to_lower()
	if lower.contains("glass") or lower.contains("lens") or lower.contains("visor") or lower.contains("sight"):
		return "lens"
	if lower.contains("stripe") or lower.contains("core") or lower.contains("glow"):
		return "glow"
	if lower.contains("blade") or lower.contains("edge") or lower.contains("point"):
		return "edge"
	if lower.contains("helmet") or lower.contains("vest") or lower.contains("plate") or lower.contains("pad") or lower.contains("boot"):
		return "armor"
	if lower.contains("receiver") or lower.contains("barrel") or lower.contains("rail") or lower.contains("muzzle") or lower.contains("stock") or lower.contains("magazine") or lower.contains("grip") or lower.contains("guard") or lower.contains("pommel") or color.v < 0.18:
		return "gunmetal"
	if lower.contains("arm") or lower.contains("leg") or lower.contains("torso") or lower.contains("pelvis"):
		return "cloth"
	return "armor"

static func _make_premium_texture(part_name: String, color: Color, kind: String) -> Texture2D:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var name_hash := float(part_name.hash() & 1023) * 0.013
	for y in range(48):
		for x in range(48):
			var seed_value := sin(float(x) * 18.27 + float(y) * 41.13 + name_hash + color.r * 31.0 + color.g * 57.0 + color.b * 73.0) * 43758.5453
			var n := seed_value - floor(seed_value)
			var grain := (n - 0.5) * 0.18
			match kind:
				"gunmetal":
					grain += (0.18 if x % 12 == 0 or y % 12 == 0 else -0.02)
					grain += (0.08 if abs(x - y) % 17 == 0 else 0.0)
				"armor":
					grain += (0.12 if (x / 8 + y / 8) % 2 == 0 else -0.04)
				"cloth":
					grain += (0.10 if x % 5 < 2 else -0.04)
					grain += (0.06 if y % 7 < 2 else 0.0)
				"lens", "glass":
					grain += (0.22 if abs(x - y) < 3 or x % 16 == 0 else -0.02)
				"edge", "glow":
					grain += (0.18 if x % 6 < 2 else 0.04)
			var factor := clampf(1.0 + grain, 0.62, 1.48)
			image.set_pixel(x, y, Color(clampf(color.r * factor, 0.0, 1.0), clampf(color.g * factor, 0.0, 1.0), clampf(color.b * factor, 0.0, 1.0), color.a))
	return ImageTexture.create_from_image(image)
