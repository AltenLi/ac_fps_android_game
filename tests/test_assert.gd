extends RefCounted

var checks := 0
var failures: Array[String] = []

func is_true(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func is_false(value: bool, message: String) -> void:
	is_true(not value, message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func not_null(value: Variant, message: String) -> void:
	checks += 1
	if value == null:
		failures.append(message)

func resource_exists(path: String, message: String) -> void:
	checks += 1
	if not ResourceLoader.exists(path):
		failures.append("%s | missing=%s" % [message, path])
