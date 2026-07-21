extends Node

const UI_FONT := preload("res://resources/fonts/NotoSansSC-Static.ttf")

func _enter_tree() -> void:
	ThemeDB.fallback_font = UI_FONT
