@tool
extends EditorPlugin

var _registered_autoload: bool = false

func _enter_tree() -> void:
	# Idempotent: skip when the project already declares the singleton so explicit
	# autoload registration in project.godot does not collide with the plugin.
	if not ProjectSettings.has_setting("autoload/ToastManager"):
		add_autoload_singleton("ToastManager", "res://addons/properUI_toast/ToastManager.gd")
		_registered_autoload = true

func _exit_tree() -> void:
	if _registered_autoload:
		remove_autoload_singleton("ToastManager")
