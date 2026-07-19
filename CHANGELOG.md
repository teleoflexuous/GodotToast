# Changelog

## 1.2.0 (2026-07-19)

### Added
- **`ToastManager.ui_theme`**: Optional host `Theme` applied to every spawned toast. Solves the same CanvasLayer-loses-game-root-theme issue as modal; the addon stays theme-neutral by default.
- **`celebration` option**: `opts["celebration"] = true` enables lightweight code-drawn confetti (no bitmap dependency) and swaps the icon to 🎉. Generic opt-in affordance for milestones/achievements.
- **`set_stack_box(key, config)`**: Runtime API for updating an existing stack box's insets, then re-laying out the stack. Backed by the new private `_create_stack_root_geometry()` extracted from `_create_stack_root()`.
- **`Toast.refresh_layout()`**: Public helper that recomputes fit-to-content lines and reapplies the size. Used by the manager after spawning.
- **`ToastPanel` theme type variation**: The `Toast` root now declares `theme_type_variation = &"ToastPanel"` so hosts can theme toasts through their own variation. `Toast._apply_visuals_for_kind()` now looks up the panel stylebox via the node's own type variation instead of forcing `PanelContainer`.
- **Pause-aware manager**: `ToastManager._ready()` now sets `process_mode = PROCESS_MODE_ALWAYS` so milestone/settings feedback remains usable from pause UI.
- **Idempotent autoload registration**: `ToastPlugin` only registers `ToastManager` when `autoload/ToastManager` is not already declared in `ProjectSettings`, and only removes what it registered. Projects that declare the singleton explicitly no longer collide with the plugin.
- **ML/C/MR vertical centering**: `_place_and_animate()` now distributes center-stack toasts outward from the vertical midpoint instead of stacking from the top.
- **Measured spawn sizing**: `_spawn_and_show_in()` now calls `refresh_layout()` and reapplies `toast.size` using the measured minimum height so toasts always have a correct height before animation.
- **8 GUT tests** under `tests/runtime/test_toast_semantics.gd` (celebration icon/processing, refresh_layout, ToastPanel type variation, ui_theme application, pause processing, set_stack_box geometry/unknown-key handling).

### Changed
- **`Toast._fit_message_lines()`**: Now treats `_fit_max_lines <= 0` as "no cap" (uses the raw line count), and recomputes both `message_label.update_minimum_size()` and `reset_size()` so the layout is correctly flushed.

### Removed
- **`DebugLogger` integration**: Dropped the `_debug_logger_name` field, the `_log_ui()` helper, and every call site from both `Toast.gd` and `ToastManager.gd`. Restores addon portability; the addon was already fully functional without a logger.

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
