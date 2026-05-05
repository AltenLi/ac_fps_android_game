class_name DamageNumber
extends Node3D

## 在命中位置生成一个浮动伤害数字，自动向上漂移并淡出

func setup(damage: float, hit_pos: Vector3) -> void:
	global_position = hit_pos + Vector3(randf_range(-0.18, 0.18), 0.3, randf_range(-0.18, 0.18))

	var label := Label3D.new()
	label.text = str(int(damage))
	label.font_size = 52
	label.modulate = Color(1.0, 0.88, 0.18, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 6
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.75)
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	## 向上漂移 1.2 单位（0.75 秒）
	tween.tween_property(self, "global_position:y", global_position.y + 1.2, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	## 0.2 秒延迟后淡出（共 0.55 秒淡出）
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.22)

	var timer := get_tree().create_timer(0.85)
	timer.timeout.connect(queue_free)
