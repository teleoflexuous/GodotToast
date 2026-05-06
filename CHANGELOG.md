# Changelog

## 1.1.0 (2026-05-06)

### Added
- **Action API**: Primary and secondary action buttons with named signals (`action`, `secondary_action` in opts).
- **Body-click actions**: `click_action_name` and `dismiss_on_click_action` options allow triggering actions by clicking the toast body. Mouse filter set to `STOP` to capture clicks, with hit-testing to ignore button clicks.
- **Fit-to-content**: `fit_to_content` and `fit_max_lines` options auto-size toast to message length.
- **Action callback**: `action_callback` option wires a `Callable` directly to the toast's `action_invoked` signal.
- **Notification Panel**: Optional persistent notification sidebar with priority levels (LOW, MEDIUM, HIGH, CRITICAL), dockable to any corner. Enable via `enable_notification_panel` export. API: `add_notification()`, `remove_notification()`, `clear_all_notifications()`, `get_notification_panel()`.
- **Optional debug logging**: Both `Toast.gd` and `ToastManager.gd` log to `_debug_logger_name` autoload (default: `"DebugLogger"`) when available. Fully functional without any logger.

### Changed
- Actions no longer auto-dismiss on invoke -- let the explicit dismiss button handle closure, or use `dismiss_on_click_action`.
- `mouse_filter` changed from `PASS` to `STOP` to support body-click capture.
- Fixed broken script path in `TestScene.tscn` (`addons/addons/` double path).

### Merged from 1.0.2
- Preserved `max_lines_visible = 3` default in `Toast.tscn` scene.
- Preserved troubleshooting and theming documentation.
- Preserved `toast_safe` wrapper pattern.
