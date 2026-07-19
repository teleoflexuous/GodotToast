extends PanelContainer

signal dismissed
signal action_invoked(name: String)

const DEFAULT_DISPLAY_SEC: float = 3.0
const DEFAULT_FADE_SEC: float = 0.20
const DEFAULT_SLIDE_PX: float = 56.0

enum Kind { SUCCESS, INFO, WARNING, ERROR }

var message_label: Label
var icon_label: Label
var primary_button: Button
var secondary_button: Button
var actions_box: HBoxContainer
var dismiss_button: Button

var kind: Kind = Kind.INFO
var persistent: bool = false

var _tween: Tween
var _timer: Timer
var _is_hovered: bool = false
var _target_y: float = 0.0
var _display_sec: float = DEFAULT_DISPLAY_SEC
var _fade_sec: float = DEFAULT_FADE_SEC
var _slide_px: float = DEFAULT_SLIDE_PX
var _reduced_motion: bool = false
var _is_in_queue: bool = false
var _aria_role: String = "status"
var _action_name_primary: String = ""
var _action_name_secondary: String = ""
var _click_action_name: String = ""
var _dismiss_on_click_action: bool = false
var _fit_to_content: bool = false
var _fit_max_lines: int = 8
var _celebration: bool = false
var _celebration_time: float = 0.0

func _ready() -> void:
	message_label = get_node("Margin/HBox/Content/Message") as Label
	icon_label = get_node("Margin/HBox/Icon") as Label
	actions_box = get_node("Margin/HBox/Content/Actions") as HBoxContainer
	primary_button = get_node("Margin/HBox/Content/Actions/ActionButton") as Button
	secondary_button = get_node("Margin/HBox/Content/Actions/SecondaryActionButton") as Button
	dismiss_button = get_node("Margin/HBox/Dismiss") as Button
	var margin := get_node("Margin") as Control
	var hbox := get_node("Margin/HBox") as Control
	var content := get_node("Margin/HBox/Content") as Control

	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	primary_button.pressed.connect(func(): _emit_action(_action_name_primary))
	secondary_button.pressed.connect(func(): _emit_action(_action_name_secondary))
	dismiss_button.pressed.connect(func(): dismiss())

	_update_accessibility()

	visible = false
	modulate = Color(1, 1, 1, 1)

func setup(text: String, type: String = "info", opts: Dictionary = {}) -> void:
	if not message_label or not icon_label:
		return

	_display_sec = float(opts.get("display_sec", DEFAULT_DISPLAY_SEC))
	_fade_sec = float(opts.get("fade_sec", DEFAULT_FADE_SEC))
	_slide_px = float(opts.get("slide_px", DEFAULT_SLIDE_PX))
	_reduced_motion = bool(opts.get("reduced_motion", false))
	persistent = bool(opts.get("persistent", false))

	_configure_actions(opts)
	_click_action_name = String(opts.get("click_action_name", ""))
	_dismiss_on_click_action = bool(opts.get("dismiss_on_click_action", false))
	_fit_to_content = bool(opts.get("fit_to_content", false))
	_fit_max_lines = int(opts.get("fit_max_lines", 8))

	# Label behavior
	message_label.text = text
	message_label.clip_text = false
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var max_lines := int(opts.get("max_lines", 3))
	if _fit_to_content:
		message_label.max_lines_visible = -1
		_fit_message_lines()
		call_deferred("_fit_message_lines")
	else:
		if max_lines == -1:
			message_label.max_lines_visible = -1
		else:
			if max_lines <= 0:
				max_lines = 3
			message_label.max_lines_visible = max_lines
	_set_kind_from_string(type)
	_set_aria_role_for_kind()
	_celebration = bool(opts.get("celebration", false))
	if _celebration:
		icon_label.text = "🎉"
		set_process(true)
		queue_redraw()

	# Dismiss affordance
	dismiss_button.visible = bool(opts.get("show_dismiss", true))

	# RTL mirroring support: respect project/parent layout
	layout_direction = int(opts.get("layout_direction", Control.LAYOUT_DIRECTION_INHERITED))

	position.y = _target_y + (0.0 if _reduced_motion else _slide_px)

func set_width(w: float) -> void:
	custom_minimum_size.x = w
	size.x = w


func refresh_layout() -> void:
	if _fit_to_content:
		_fit_message_lines()
	update_minimum_size()
	reset_size()

func set_queued(queued: bool) -> void:
	_is_in_queue = queued
	if queued:
		_pause_timer()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP

func place_immediately(y: float) -> void:
	_target_y = y
	position.y = y + (0.0 if _reduced_motion else _slide_px)

func animate_in_to(y: float) -> void:
	_target_y = y
	_kill_tween()
	visible = true

	if _reduced_motion:
		position.y = _target_y
	else:
		_tween = create_tween()
		_tween.tween_property(self, "position:y", _target_y, _fade_sec) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_start_timer_if_needed()

func move_to(y: float) -> void:
	_target_y = y
	_kill_tween()
	var t: Tween = create_tween()
	t.tween_property(self, "position:y", _target_y, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func dismiss() -> void:
	if not is_inside_tree():
		return
	_animate_out(true)

func _animate_out(force: bool = false) -> void:
	_kill_tween()

	if not force and (_is_hovered or persistent or _is_in_queue):
		if not persistent and not _is_in_queue:
			_timer.wait_time = 0.25
			_timer.start()
		return

	if _reduced_motion:
		_cleanup_and_emit()
		return

	_tween = create_tween()
	_tween.tween_property(self, "position:y", _target_y + _slide_px, _fade_sec) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_cleanup_and_emit)

func _cleanup_and_emit() -> void:
	visible = false
	if is_inside_tree():
		queue_free()
	emit_signal("dismissed")

func _start_timer_if_needed() -> void:
	if persistent or _is_in_queue:
		return
	var min_read: float = 0.5
	if kind == Kind.WARNING:
		_timer.wait_time = max(min_read, max(_display_sec, 4.0))
	elif kind == Kind.ERROR:
		_timer.wait_time = max(min_read, max(_display_sec, 5.0))
	else:
		_timer.wait_time = max(min_read, _display_sec)
	_timer.start()

func _pause_timer() -> void:
	if _timer and not _timer.is_stopped():
		_timer.paused = true

func _resume_timer_if_needed() -> void:
	if _timer and not _timer.is_stopped():
		_timer.paused = false

func _on_timer_timeout() -> void:
	_animate_out()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_pause_timer()

func _on_mouse_exited() -> void:
	_is_hovered = false
	if not persistent and not _is_in_queue:
		_resume_timer_if_needed()

func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null

func _set_kind_from_string(type_str: String) -> void:
	match type_str.to_lower():
		"success":
			_set_kind(Kind.SUCCESS)
		"warning":
			_set_kind(Kind.WARNING)
		"error":
			_set_kind(Kind.ERROR)
		_:
			_set_kind(Kind.INFO)

func _set_kind(value: Kind) -> void:
	kind = value
	_apply_visuals_for_kind()

func _apply_visuals_for_kind() -> void:
	# Look up the panel stylebox using the node's own type variation so hosts can
	# theme `ToastPanel` (or any custom variation) without forcing PanelContainer.
	var style := get_theme_stylebox("panel")
	var icon_txt: String = "ℹ️"

	if style is StyleBoxFlat:
		var sb := style.duplicate() as StyleBoxFlat
		var border := Color(0.40, 0.60, 1.00, 1.00)
		var shadow_size := 8
		var shadow_color := Color(0, 0, 0, 0.18)

		match kind:
			Kind.SUCCESS:
				border = Color(0.20, 0.75, 0.35, 1.00)
				icon_txt = "✅"
			Kind.INFO:
				border = Color(0.40, 0.60, 1.00, 1.00)
				icon_txt = "ℹ️"
			Kind.WARNING:
				border = Color(1.00, 0.75, 0.30, 1.00)
				icon_txt = "⚠️"
			Kind.ERROR:
				border = Color(1.00, 0.40, 0.40, 1.00)
				icon_txt = "❌"

		sb.border_color = border
		var bg := sb.bg_color
		sb.bg_color = Color(bg.r, bg.g, bg.b, min(bg.a, 0.95))
		sb.shadow_size = shadow_size
		sb.shadow_color = shadow_color
		add_theme_stylebox_override("panel", sb)

	if icon_label:
		icon_label.text = "🎉" if _celebration else icon_txt


func _process(delta: float) -> void:
	if not _celebration:
		set_process(false)
		return
	_celebration_time += delta
	queue_redraw()


func _draw() -> void:
	if not _celebration:
		return
	# Lightweight code-drawn confetti so milestone/achievement toasts get a
	# celebratory affordance without bitmap dependencies.
	var palette: Array[Color] = [Color("ffe76a"), Color("58e0ca"), Color("ff6b82")]
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	for index: int in range(18):
		var angle: float = float(index) * TAU / 18.0 + _celebration_time * (0.25 if index % 2 == 0 else -0.18)
		var radius: float = 26.0 + fmod(float(index * 17), 62.0)
		var point: Vector2 = center + Vector2.from_angle(angle) * radius
		draw_rect(Rect2(point - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), palette[index % palette.size()])

func _configure_actions(opts: Dictionary) -> void:
	var act = opts.get("action", null)
	var sec = opts.get("secondary_action", null)

	if act is Dictionary and act.has("text"):
		_action_name_primary = String(act.get("name", "primary"))
		primary_button.text = String(act.get("text", ""))
		primary_button.visible = true
	else:
		primary_button.visible = false
		_action_name_primary = ""

	if sec is Dictionary and sec.has("text"):
		_action_name_secondary = String(sec.get("name", "secondary"))
		secondary_button.text = String(sec.get("text", ""))
		secondary_button.visible = true
	else:
		secondary_button.visible = false
		_action_name_secondary = ""

	actions_box.visible = primary_button.visible or secondary_button.visible

func _emit_action(name: String) -> void:
	if name == "":
		return
	emit_signal("action_invoked", name)
	# Do not auto-dismiss on action; let explicit dismiss button handle it


func _on_gui_input(event: InputEvent) -> void:
	if _click_action_name.is_empty():
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var local_point := mouse_event.position
	var global_point := get_global_transform_with_canvas() * local_point
	if dismiss_button and dismiss_button.visible and dismiss_button.get_global_rect().has_point(global_point):
		return
	if primary_button and primary_button.visible and primary_button.get_global_rect().has_point(global_point):
		return
	if secondary_button and secondary_button.visible and secondary_button.get_global_rect().has_point(global_point):
		return

	_emit_action(_click_action_name)
	if _dismiss_on_click_action:
		dismiss()
	get_viewport().set_input_as_handled()


func _fit_message_lines() -> void:
	if not message_label:
		return
	var line_count := message_label.get_line_count()
	if line_count <= 0:
		line_count = message_label.text.count("\n") + 1
	line_count = max(line_count, 1)
	message_label.max_lines_visible = mini(line_count, _fit_max_lines) if _fit_max_lines > 0 else line_count
	message_label.custom_minimum_size.y = 0
	message_label.update_minimum_size()
	update_minimum_size()
	reset_size()

func _unhandled_key_input(event: InputEvent) -> void:
	if not has_focus() and not _is_hovered:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel"):
			dismiss()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") and primary_button.visible:
			_emit_action(_action_name_primary)
			get_viewport().set_input_as_handled()

func _update_accessibility() -> void:
	tooltip_text = ""
	if has_method("set_accessible_name"):
		var heading := ""
		match kind:
			Kind.SUCCESS: heading = "Success"
			Kind.INFO: heading = "Information"
			Kind.WARNING: heading = "Warning"
			Kind.ERROR: heading = "Error"
		var msg := message_label.text if message_label else ""
		var action := ""
		if primary_button.visible:
			action = " Action: %s." % primary_button.text
		call_deferred("set_accessible_name", "%s toast. %s.%s" % [heading, msg, action])

func _set_aria_role_for_kind() -> void:
	_aria_role = "status"
	if kind == Kind.WARNING or kind == Kind.ERROR:
		_aria_role = "alert"
