class_name AmmoPickup
extends Area3D

signal picked_up(pickup: AmmoPickup, player: PlayerController)

var rotate_speed := 75.0
var bob_speed := 2.4
var bob_amount := 0.16
var base_y := 0.0
var visual: Node3D
var _time := 0.0

func _ready() -> void:
	base_y = position.y
	_build_pickup()
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	if visual != null:
		visual.rotation_degrees.y += rotate_speed * delta
		visual.position.y = sin(_time * bob_speed) * bob_amount

func _build_pickup() -> void:
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	collision.shape = sphere
	add_child(collision)

	visual = Node3D.new()
	visual.name = "AmmoVisual"
	add_child(visual)

	_add_box("Crate", Vector3(1.1, 0.48, 0.72), Vector3(0, 0.34, 0), Color(0.12, 0.1, 0.07, 1))
	_add_box("Stripe", Vector3(1.16, 0.08, 0.76), Vector3(0, 0.55, 0), Color(0.92, 0.62, 0.18, 1))
	for i in range(4):
		var x := -0.36 + float(i) * 0.24
		_add_cylinder("Round%d" % i, 0.045, 0.55, Vector3(x, 0.74, 0), Vector3(90, 0, 0), Color(0.88, 0.72, 0.32, 1))

	var light := OmniLight3D.new()
	light.name = "AmmoGlow"
	light.light_color = Color(1.0, 0.66, 0.22, 1)
	light.light_energy = 0.55
	light.omni_range = 3.8
	light.position = Vector3(0, 0.8, 0)
	add_child(light)

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController:
		picked_up.emit(self, body as PlayerController)

func _add_box(name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color)
	visual.add_child(mesh_instance)

func _add_cylinder(name: String, radius: float, height: float, pos: Vector3, rot: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rot
	mesh_instance.material_override = _material(color)
	visual.add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mat.emission_enabled = true
	mat.emission = color * 0.18
	return mat
