extends RefCounted

func run(t) -> void:
	t.resource_exists("res://scenes/mobile_controls.tscn", "移动端触控场景必须存在")
	var mobile_text := FileAccess.get_file_as_string("res://scripts/mobile_controls.gd")
	var hud_text := FileAccess.get_file_as_string("res://scripts/hud.gd")
	var player_text := FileAccess.get_file_as_string("res://scripts/player_controller.gd")

	t.is_true(mobile_text.contains("func _is_gameplay_input_enabled()"), "移动端输入应有统一可用状态判断")
	t.is_true(mobile_text.contains("func _is_gameplay_touch_enabled()"), "触摸视角应有真实触屏状态判断")
	t.is_true(mobile_text.contains("_look_area.mouse_filter = Control.MOUSE_FILTER_STOP if should_block else Control.MOUSE_FILTER_IGNORE"), "视角触摸区应按战斗状态启停拦截")
	t.is_true(mobile_text.contains("if not should_block:"), "视角触摸区停用时应清理摇杆/开火状态")
	t.is_true(mobile_text.contains("player.set_mobile_look(event.relative)"), "右半屏拖动应继续驱动视角旋转")
	t.is_true(mobile_text.contains("event is InputEventScreenDrag and event.index != joystick_touch_id"), "摇杆触点不应同时驱动视角旋转")
	t.is_true(mobile_text.contains("fire_btn.button_down.connect"), "开火按钮应响应按下事件")
	t.is_true(mobile_text.contains("fire_btn.button_up.connect"), "开火按钮应响应松开事件")
	t.is_true(mobile_text.contains("player.mobile_reload()"), "装弹按钮应调用玩家装弹")
	t.is_true(mobile_text.contains("player.mobile_next_weapon()"), "切枪按钮应调用玩家切枪")

	t.is_true(player_text.contains("func can_accept_mobile_input()"), "玩家应暴露移动端输入可用状态")
	t.is_true(player_text.contains("not _dead") and player_text.contains("match_manager.match_over"), "死亡或结算后应拒绝移动端战斗输入")

	t.is_true(hud_text.contains("root.mouse_filter = Control.MOUSE_FILTER_IGNORE"), "HUD 全屏根节点不应吞掉移动端触摸")
	t.is_true(hud_text.contains("top.mouse_filter = Control.MOUSE_FILTER_IGNORE"), "HUD 顶部信息条不应吞掉移动端触摸")
	t.is_true(hud_text.contains("bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE"), "HUD 底部信息条不应吞掉移动端触摸")
	t.is_true(hud_text.contains("label.mouse_filter = Control.MOUSE_FILTER_IGNORE"), "HUD 文本标签不应吞掉移动端触摸")
	t.is_true(hud_text.contains("rect.mouse_filter = Control.MOUSE_FILTER_IGNORE"), "准星节点不应吞掉移动端触摸")
	t.is_true(hud_text.contains("result_panel.mouse_filter = Control.MOUSE_FILTER_STOP"), "结算面板应保留按钮点击拦截")
