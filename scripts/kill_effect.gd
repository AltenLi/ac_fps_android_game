class_name KillEffect
extends Node3D

## 夸张击杀特效：在击杀位置生成彩色扩散球体 + 光源 + 灵魂上升效果
## 用法：var ke := KillEffect.new(); scene.add_child(ke); ke.setup(kill_position)

func setup(pos: Vector3) -> void:
	global_position = pos

	## 随机选一种颜色（橙/金/红）
	var colors := [
		Color(1.0, 0.55, 0.1),   ## 橙
		Color(1.0, 0.88, 0.1),   ## 金
		Color(1.0, 0.22, 0.18),  ## 红
	]
	var color: Color = colors[randi() % colors.size()]

	## 球体 MeshInstance3D
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	## 点光源
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 6.0
	light.omni_range = 5.0
	add_child(light)

	## Tween：球体扩大 + 淡出
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(8.0, 8.0, 8.0), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.28).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(light, "light_energy", 0.0, 0.22)

	## 灵魂上升效果（独立节点，不受父级 scale tween 影响）
	_spawn_soul(pos)

	await tween.finished
	queue_free()

## 在击杀位置生成半透明灵魂轮廓，向上飘起并淡出
func _spawn_soul(pos: Vector3) -> void:
	var soul_root := Node3D.new()
	soul_root.global_position = pos + Vector3(0, 0.6, 0)
	get_parent().add_child(soul_root)

	## 身体：胶囊体（躯干）
	var body_inst := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 1.1
	body_inst.mesh = capsule
	var soul_mat := StandardMaterial3D.new()
	soul_mat.albedo_color = Color(0.72, 0.88, 1.0, 0.72)
	soul_mat.emission_enabled = true
	soul_mat.emission = Color(0.55, 0.78, 1.0)
	soul_mat.emission_energy_multiplier = 1.8
	soul_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	soul_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soul_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	body_inst.material_override = soul_mat
	soul_root.add_child(body_inst)

	## 头部：小球
	var head_inst := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.22
	head_sphere.height = 0.44
	head_inst.mesh = head_sphere
	head_inst.material_override = soul_mat
	head_inst.position = Vector3(0, 0.78, 0)
	soul_root.add_child(head_inst)

	## 灵魂光晕：略大的半透明外壳
	var glow_inst := MeshInstance3D.new()
	var glow_capsule := CapsuleMesh.new()
	glow_capsule.radius = 0.38
	glow_capsule.height = 1.3
	glow_inst.mesh = glow_capsule
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.6, 0.82, 1.0, 0.22)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.4, 0.65, 1.0)
	glow_mat.emission_energy_multiplier = 1.2
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_inst.material_override = glow_mat
	soul_root.add_child(glow_inst)

	## Tween：上升 + 淡出 + 轻微摇摆
	var soul_tween := soul_root.create_tween()
	soul_tween.set_parallel(true)
	## 上升约 3.5 个单位，历时 1.4 秒
	soul_tween.tween_property(soul_root, "position:y", soul_root.position.y + 3.5, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	## 轻微左右摇摆（旋转 Y 轴）
	soul_tween.tween_property(soul_root, "rotation:y", deg_to_rad(25.0), 0.7).set_trans(Tween.TRANS_SINE)
	## 身体淡出：前 0.4 秒保持，之后 1.0 秒内淡出
	soul_tween.tween_property(soul_mat, "albedo_color:a", 0.0, 1.0).set_delay(0.4)
	soul_tween.tween_property(glow_mat, "albedo_color:a", 0.0, 1.0).set_delay(0.4)
	## 向上逐渐缩小（灵魂散逸感）
	soul_tween.tween_property(soul_root, "scale", Vector3(0.6, 1.3, 0.6), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await soul_tween.finished
	soul_root.queue_free()
