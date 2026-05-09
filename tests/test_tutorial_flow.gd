extends RefCounted

const MAIN_MENU_PATH := "res://scripts/main_menu.gd"

func run(t) -> void:
	var source := FileAccess.get_file_as_string(MAIN_MENU_PATH)
	t.is_true(source.contains("const TUTORIAL_STEPS"), "首页应维护分步骤教程内容")
	t.is_true(source.contains("if not PlayerData.tutorial_completed"), "首次进入首页应检查教程完成状态")
	t.is_true(source.contains("call_deferred(\"_show_tutorial\", true)"), "未完成教程时应自动弹出首局引导")
	t.is_true(source.contains("_set_tutorial_step"), "教程应支持步骤切换")
	t.is_true(source.contains("上一步"), "教程应支持返回上一步")
	t.is_true(source.contains("下一步"), "教程应支持进入下一步")
	t.is_true(source.contains("开始作战"), "最后一步应引导玩家开始作战")
	t.is_true(source.contains("PlayerData.mark_tutorial_completed(true)"), "完成或跳过教程后应保存完成状态")
	t.is_true(source.contains("1. 任务目标"), "教程应说明任务目标")
	t.is_true(source.contains("2. 移动与瞄准"), "教程应说明移动与瞄准")
	t.is_true(source.contains("3. 射击、装弹与切枪"), "教程应说明射击、装弹与切枪")
	t.is_true(source.contains("4. 武器定位"), "教程应说明武器定位")
	t.is_true(source.contains("5. 星星与地图"), "教程应说明星星与地图")
