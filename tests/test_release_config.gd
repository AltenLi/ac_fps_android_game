extends RefCounted

func run(t) -> void:
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	t.is_true(text.contains("name=\"Android Release\""), "Android Release preset should exist")
	t.is_true(text.contains("export_path=\"build/android/DustCityFPS.apk\""), "Android Release should currently output an APK for device testing")
	t.is_true(text.contains("gradle_build/export_format=0"), "Android Release should currently use APK export format")
	t.is_true(text.contains("gradle_build/use_gradle_build=false"), "Android test export should not require Gradle")
	t.is_true(text.contains("package/show_as_launcher_app=true"), "Android should show as launcher app")
	t.is_true(text.contains("user_data_backup/allow=false"), "Local progress should not be backed up by default")
	t.is_true(text.contains("permissions/internet=false"), "Network permission should stay disabled before real SDK integration")
	t.is_true(text.contains("encrypt_pck=false"), "Android test export should not encrypt pck resources")
	t.is_true(FileAccess.file_exists("res://RELEASE_CHECKLIST.md"), "Release checklist should exist")
	t.is_true(FileAccess.file_exists("res://docs/privacy-policy.md"), "Privacy policy template should exist")
