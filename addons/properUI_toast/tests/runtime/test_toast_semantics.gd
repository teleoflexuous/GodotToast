extends GutTest


const ToastScene := preload("res://addons/properUI_toast/Toast.tscn")
const ToastManagerScript := preload("res://addons/properUI_toast/ToastManager.gd")


func test_celebration_overrides_icon_and_enables_processing() -> void:
	var toast = add_child_autofree(ToastScene.instantiate())
	await wait_process_frames(1)
	toast.setup("Achievement unlocked", "success", {"celebration": true})
	await wait_process_frames(1)
	assert_eq(toast.icon_label.text, "🎉")
	assert_true(toast.is_processing())


func test_celebration_false_keeps_kind_icon() -> void:
	var toast = add_child_autofree(ToastScene.instantiate())
	await wait_process_frames(1)
	toast.setup("Saved", "success", {"celebration": false})
	await wait_process_frames(1)
	assert_eq(toast.icon_label.text, "✅")
	assert_false(toast.is_processing())


func test_refresh_layout_recomputes_size_for_fit_to_content() -> void:
	var toast = add_child_autofree(ToastScene.instantiate())
	await wait_process_frames(1)
	toast.set_width(220.0)
	toast.setup("Line one\nLine two\nLine three\nLine four", "info", {"fit_to_content": true, "fit_max_lines": 8})
	await wait_process_frames(2)
	var height_before: float = toast.size.y
	toast.refresh_layout()
	await wait_process_frames(1)
	assert_gte(toast.size.y, height_before)
	assert_gte(toast.size.y, toast.get_combined_minimum_size().y)


func test_stylebox_lookup_uses_node_type_variation() -> void:
	var toast = add_child_autofree(ToastScene.instantiate())
	await wait_process_frames(1)
	assert_eq(toast.theme_type_variation, &"ToastPanel")


func test_manager_applies_ui_theme_to_spawned_toast() -> void:
	var manager = add_child_autofree(ToastManagerScript.new())
	await wait_process_frames(1)
	var theme := Theme.new()
	manager.ui_theme = theme
	manager.show_toast("Themed toast", "info", {}, "BR")
	await wait_process_frames(3)
	var toast: Control = manager._active["BR"][0]
	assert_eq(toast.theme, theme)


func test_manager_processes_while_scene_tree_paused() -> void:
	var manager = add_child_autofree(ToastManagerScript.new())
	await wait_process_frames(1)
	assert_eq(manager.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_set_stack_box_updates_geometry_and_relayouts() -> void:
	var manager = add_child_autofree(ToastManagerScript.new())
	await wait_process_frames(1)
	var before_bottom: float = manager._roots["BR"].offset_bottom
	manager.set_stack_box("BR", {"bottom": 140.0})
	await wait_process_frames(1)
	assert_ne(manager._roots["BR"].offset_bottom, before_bottom)
	assert_eq(manager._roots["BR"].offset_bottom, -140.0)


func test_set_stack_box_ignores_unknown_key() -> void:
	var manager = add_child_autofree(ToastManagerScript.new())
	await wait_process_frames(1)
	# Should not push errors or create new roots.
	manager.set_stack_box("XX", {"bottom": 100.0})
	assert_false(manager._roots.has("XX"))
