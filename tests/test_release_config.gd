extends RefCounted

func run(t) -> void:
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	t.is_true(text.contains("name=\"Android Release\""), "应存在 Android Release 预设")
	t.is_true(text.contains("export_path=\"build/android/CS5v5.aab\""), "Android Release 应输出 AAB")
	t.is_true(text.contains("gradle_build/export_format=1"), "Android Release 应使用 AAB 导出格式")
	t.is_true(text.contains("gradle_build/min_sdk=\"23\""), "Android minSdk 应明确为 23")
	t.is_true(text.contains("gradle_build/target_sdk=\"35\""), "Android targetSdk 应明确为 35")
	t.is_true(text.contains("package/show_as_launcher_app=true"), "Android 应显示为启动器 App")
	t.is_true(text.contains("user_data_backup/allow=false"), "商业发布不应默认备份本地进度")
	t.is_true(text.contains("permissions/internet=false"), "未接入真实 SDK 前不应打开网络权限")
	t.is_true(FileAccess.file_exists("res://RELEASE_CHECKLIST.md"), "发布清单必须存在")
	t.is_true(FileAccess.file_exists("res://docs/privacy-policy.md"), "隐私政策模板必须存在")
