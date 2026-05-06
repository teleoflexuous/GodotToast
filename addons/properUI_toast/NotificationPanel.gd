extends PanelContainer

## Optional persistent notification panel for properUI_toast addon
## Shows a docked list of persistent notifications with actions

signal notification_clicked(notification_id: String)
signal notification_dismissed(notification_id: String)

enum Priority { LOW, MEDIUM, HIGH, CRITICAL }

@export var max_notifications: int = 10
@export var auto_collapse_low_priority: bool = true

var _notifications: Array[Dictionary] = []
var _notification_items: Dictionary = {}

@onready var notification_list: VBoxContainer = %NotificationList
@onready var clear_all_button: Button = %ClearAllButton

func _ready() -> void:
	if clear_all_button:
		clear_all_button.pressed.connect(_on_clear_all_pressed)
	visible = false

func add_notification(id: String, message: String, priority: Priority, action: Callable = Callable()) -> void:
	if _notification_items.has(id):
		return
	if _notifications.size() >= max_notifications:
		_remove_oldest_low_priority()
	var notification_data := {
		"id": id,
		"message": message,
		"priority": priority,
		"action": action,
		"timestamp": Time.get_ticks_msec()
	}
	_notifications.append(notification_data)
	_sort_notifications()
	_create_notification_item(notification_data)
	visible = true

func remove_notification(id: String) -> void:
	if not _notification_items.has(id):
		return
	_notifications = _notifications.filter(func(n): return n.id != id)
	var item: Control = _notification_items[id]
	if is_instance_valid(item):
		item.queue_free()
	_notification_items.erase(id)
	notification_dismissed.emit(id)
	if _notifications.is_empty():
		visible = false

func clear_all() -> void:
	for id in _notification_items.keys():
		var item = _notification_items[id]
		if is_instance_valid(item):
			item.queue_free()
	_notifications.clear()
	_notification_items.clear()
	visible = false

func get_notification_count(priority: Priority = -1) -> int:
	if priority == -1:
		return _notifications.size()
	return _notifications.filter(func(n): return n.priority == priority).size()

func _sort_notifications() -> void:
	_notifications.sort_custom(func(a, b): 
		if a.priority != b.priority:
			return a.priority > b.priority
		return a.timestamp < b.timestamp
	)

func _create_notification_item(data: Dictionary) -> void:
	var item := PanelContainer.new()
	item.name = "Notification_" + data.id
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	item.add_child(margin)
	var hbox := HBoxContainer.new()
	margin.add_child(hbox)
	var icon := Label.new()
	icon.custom_minimum_size = Vector2(24, 0)
	match data.priority:
		Priority.CRITICAL: icon.text = "❗"
		Priority.HIGH: icon.text = "⚠️"
		Priority.MEDIUM: icon.text = "ℹ️"
		Priority.LOW: icon.text = "·"
	hbox.add_child(icon)
	var message_label := Label.new()
	message_label.text = data.message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(message_label)
	if data.action.is_valid():
		var action_btn := Button.new()
		action_btn.text = "→"
		action_btn.pressed.connect(func():
			notification_clicked.emit(data.id)
			data.action.call()
		)
		hbox.add_child(action_btn)
	var dismiss_btn := Button.new()
	dismiss_btn.text = "✕"
	dismiss_btn.pressed.connect(func(): remove_notification(data.id))
	hbox.add_child(dismiss_btn)
	_apply_priority_style(item, data.priority)
	notification_list.add_child(item)
	_notification_items[data.id] = item

func _apply_priority_style(item: PanelContainer, priority: Priority) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_width_left = 3
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_left = 4
	match priority:
		Priority.CRITICAL: style.border_color = Color(1.0, 0.3, 0.3, 1.0)
		Priority.HIGH: style.border_color = Color(1.0, 0.7, 0.3, 1.0)
		Priority.MEDIUM: style.border_color = Color(0.4, 0.6, 1.0, 1.0)
		Priority.LOW: style.border_color = Color(0.5, 0.5, 0.5, 0.6)
	item.add_theme_stylebox_override("panel", style)

func _remove_oldest_low_priority() -> void:
	for notif in _notifications:
		if notif.priority == Priority.LOW:
			remove_notification(notif.id)
			return
	for notif in _notifications:
		if notif.priority == Priority.MEDIUM:
			remove_notification(notif.id)
			return

func _on_clear_all_pressed() -> void:
	clear_all()
