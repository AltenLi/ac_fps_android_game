extends RefCounted

func run(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ai_controller.gd")
	t.is_true(source.length() > 0, "AIController 源码必须可读取")
	t.is_true(source.contains("const DEFAULT_ATTACK_RANGE := 32.0"), "AI 默认攻击距离应为 32")
	t.is_true(source.contains("\"m416\": 45.0"), "M416 AI 攻击距离应为 45")
	t.is_true(source.contains("\"barrett\": 85.0"), "巴雷特 AI 攻击距离应为 85")
	t.is_true(source.contains("\"rpg\": 50.0"), "RPG AI 攻击距离应为 50")
	t.is_true(source.contains("_get_current_attack_range()"), "AI 行为应使用当前武器攻击距离")
