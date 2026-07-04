class_name TacticalChip
extends Area3D

signal picked(chip: TacticalChip, collector: Node3D)

var chip_id := "speed_boost"

func setup(new_chip_id: String) -> void:
	chip_id = new_chip_id
	_build_visual()

func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body is PlayerController:
			picked.emit(self, body)
	)

func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.7
	collision.shape = shape
	add_child(collision)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.18, 0.8)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.82, 1.0, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.18, 0.82, 1.0, 1)
	mat.emission_energy_multiplier = 1.7
	mesh.material_override = mat
	add_child(mesh)

func _process(delta: float) -> void:
	rotate_y(delta * 2.4)
