extends RefCounted

const TEST_SAVE_PATH := "user://player_data_test.cfg"

func run(t) -> void:
	var script := load("res://scripts/player_data.gd")
	var data = script.new()
	data.set_save_path_for_tests(TEST_SAVE_PATH)
	data.reset_progress()

	t.is_true(data.has_map("city"), "免费地图 city 应默认拥有")
	t.is_false(data.has_map("factory"), "付费地图 factory 初始应锁定")
	t.is_false(data.unlock_map("factory"), "星星不足时不能解锁地图")
	data.add_stars(6)
	t.equal(data.total_stars, 6, "增加星星后余额应正确")
	t.is_true(data.unlock_map("factory"), "首张锁定地图应 6 星可解锁")
	t.equal(data.total_stars, 0, "解锁后应扣除地图成本")
	t.is_true(data.has_map("factory"), "解锁后应拥有地图")
	t.is_false(data.unlock_map("missing"), "非法地图不能解锁")
	var reward: int = data.claim_daily_reward()
	t.equal(reward, data.DAILY_REWARD_STARS, "首次每日奖励应发放")
	t.equal(data.claim_daily_reward(), 0, "同一天不能重复领取每日奖励")
	data.mark_tutorial_completed(true)
	t.is_true(data.tutorial_completed, "教程完成状态应可保存")

	var tasks: Array[Dictionary] = data.get_daily_tasks()
	t.equal(tasks.size(), 3, "每日任务应包含 3 个固定目标")
	t.equal(_find_task(tasks, "daily_kills").get("progress", -1), 0, "每日击杀任务初始进度应为 0")
	data.record_match_for_daily_tasks(2, false, 0)
	t.equal(_find_task(data.get_daily_tasks(), "daily_kills").get("progress", -1), 2, "击杀任务应记录本局击杀")
	t.equal(_find_task(data.get_daily_tasks(), "daily_win").get("progress", -1), 0, "失败不应推进胜利任务")
	data.record_match_for_daily_tasks(1, true, 2)
	t.is_true(bool(_find_task(data.get_daily_tasks(), "daily_kills").get("completed", false)), "击杀任务应可完成")
	t.is_true(bool(_find_task(data.get_daily_tasks(), "daily_win").get("completed", false)), "胜利任务应可完成")
	t.is_true(bool(_find_task(data.get_daily_tasks(), "daily_battle_stars").get("completed", false)), "战斗星星任务应可完成")
	var stars_before_tasks: int = data.total_stars
	t.equal(data.claim_daily_task("daily_kills"), 1, "完成的击杀任务应可领取奖励")
	t.equal(data.claim_daily_task("daily_kills"), 0, "同一每日任务不能重复领取")
	t.equal(data.claim_daily_task("daily_win"), 2, "胜利任务奖励应正确")
	t.equal(data.claim_daily_task("daily_battle_stars"), 1, "战斗星星任务奖励应正确")
	t.equal(data.total_stars, stars_before_tasks + 4, "每日任务奖励应累计到星星")

	var data2 = script.new()
	data2.set_save_path_for_tests(TEST_SAVE_PATH)
	data2._load()
	t.is_true(data2.has_map("factory"), "地图解锁应持久化")
	t.is_true(data2.tutorial_completed, "教程状态应持久化")
	t.is_true(bool(_find_task(data2.get_daily_tasks(), "daily_win").get("claimed", false)), "每日任务领取状态应持久化")
	t.equal(_find_task(data2.get_daily_tasks(), "daily_battle_stars").get("progress", -1), 2, "每日任务进度应持久化")

func _find_task(tasks: Array[Dictionary], task_id: String) -> Dictionary:
	for task: Dictionary in tasks:
		if str(task.get("id", "")) == task_id:
			return task
	return {}
