extends PanelContainer

signal dismissed

const DEFAULT_DISPLAY_SEC: float = 3.0
const DEFAULT_FADE_SEC: float = 0.20
const DEFAULT_SLIDE_PX: float = 56.0

enum Kind { SUCCESS, INFO, WARNING, ERROR }

var message_label: Label
var icon_label: Label

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

func _ready() -> void:
	message_label = get_node("Margin/HBox/Message") as Label
	icon_label = get_node("Margin/HBox/Icon") as Label

	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

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

	message_label.text = text
	icon_label.text = "ℹ️"
	_set_kind_from_string(type)

	position.y = _target_y + (0.0 if _reduced_motion else _slide_px)

func set_width(w: float) -> void:
	custom_minimum_size.x = w
	size.x = w

func set_queued(queued: bool) -> void:
	_is_in_queue = queued
	if queued:
		_pause_timer()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_PASS

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
	_animate_out()

func _animate_out() -> void:
	_kill_tween()

	if _is_hovered or persistent or _is_in_queue:
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
	_timer.wait_time = max(0.5, _display_sec)
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
	var style := get_theme_stylebox("panel", "PanelContainer")
	var icon_txt := "ℹ️"

	if style is StyleBoxFlat:
		var sb := style.duplicate() as StyleBoxFlat
		var border := Color(0.40, 0.60, 1.00, 1.00)
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

		# Optional translucency: keep theme color but allow it to be slightly transparent.
		var bg := sb.bg_color
		sb.bg_color = Color(bg.r, bg.g, bg.b, min(bg.a, 0.92))

		add_theme_stylebox_override("panel", sb)
	# If not StyleBoxFlat, inherit as-is with no override.

	if icon_label:
		icon_label.text = icon_txt
