# ProperUI Toast

Lightweight, theme-friendly toast notifications with stacking, queueing, and 9 anchor positions for Godot 4.x. Inherits your project Theme; only border color changes per "kind".

## Features

- **9 positions**: TL, T, TR, ML, C, MR, BL, B, BR
- **Stacking** with per-position `max_active` and queued promotion
- **Center-stack distribution** for ML/C/MR positions (toasts spread outward from the vertical midpoint)
- **Hover pauses** auto-dismiss; persistent mode; reduced motion option
- **CanvasLayer** renders above game UI
- **Theme-first**: inherits your theme through the node's `ToastPanel` type variation and your fonts
- **Actions**: Primary and secondary action buttons with named signals
- **Body-click actions**: Click the toast body itself to trigger an action
- **Fit-to-content**: Auto-size toast to message length
- **Celebration confetti**: Opt-in lightweight code-drawn confetti for milestones
- **Notification Panel**: Optional persistent notification sidebar with priority levels

## Installation

1. Copy `addons/properUI_toast` into your project.
2. **Project > Project Settings > Plugins** -> enable "ProperUI Toast".
3. The autoload singleton `/root/ToastManager` (`ToastManager.gd`) is registered automatically.

## Quick Start

```gdscript
ToastManager.show_toast("Saved!", "success")
ToastManager.show_toast("Heads up", "warning", {"display_sec": 5.0}, "TR")
```

### Kinds
`"success"` | `"info"` | `"warning"` | `"error"`

### Positions
TL, T, TR, ML, C, MR, BL, B, BR

### Options (`opts` dictionary)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `display_sec` | float | 3.0 | Auto-dismiss duration |
| `fade_sec` | float | 0.20 | Slide animation duration |
| `slide_px` | float | 56.0 | Slide distance |
| `reduced_motion` | bool | false | Skip animations |
| `persistent` | bool | false | Never auto-dismiss |
| `max_lines` | int | 3 | Max visible text lines (-1 = unlimited) |
| `fit_to_content` | bool | false | Auto-size to message length |
| `fit_max_lines` | int | 8 | Upper cap when fit_to_content is true |
| `show_dismiss` | bool | true | Show dismiss button |
| `action` | Dictionary | null | Primary action: `{"text": "Undo", "name": "undo"}` |
| `secondary_action` | Dictionary | null | Secondary action: `{"text": "View", "name": "view"}` |
| `action_callback` | Callable | null | Callable invoked on any action |
| `click_action_name` | String | "" | Action triggered by clicking toast body |
| `dismiss_on_click_action` | bool | false | Auto-dismiss after body click action |
| `celebration` | bool | false | Show confetti and swap icon to 🎉 |

### Manager Properties (exported)

- `default_position` (String, default "BR")
- `spacing_px` (float)
- `reduced_motion` (bool)
- `toast_widths` (Dictionary per position)
- `max_active` (Dictionary per position)
- `stack_boxes` (Insets per position)
- `enable_notification_panel` (bool)
- `notification_panel_position` (String)

## Actions

```gdscript
ToastManager.show_toast("File deleted", "warning", {
    "action": {"text": "Undo", "name": "undo"},
    "secondary_action": {"text": "View", "name": "view"},
    "action_callback": func(): print("Action taken!")
})
```

The `action_invoked(name)` signal is emitted. Actions do **not** auto-dismiss -- let the explicit dismiss button handle closure, or use `dismiss_on_click_action`.

## Body-Click Actions

```gdscript
ToastManager.show_toast("Click to open inventory", "info", {
    "click_action_name": "open_inventory",
    "dismiss_on_click_action": true
})
```

The toast captures mouse input and fires the action on click, while correctly ignoring clicks on buttons.

## Fit-to-Content

```gdscript
ToastManager.show_toast(long_message, "info", {
    "fit_to_content": true,
    "fit_max_lines": 12
})
```

Automatically sizes the toast to fit the message text (capped by `fit_max_lines`).

## Celebration

```gdscript
ToastManager.show_toast("Achievement unlocked!", "success", {
    "celebration": true
})
```

Draws lightweight code-drawn confetti (no bitmap dependency) and swaps the icon to 🎉. Useful for milestones, level-ups, and achievement toasts.

## Notification Panel

Enable via the inspector or code:

```gdscript
ToastManager.enable_notification_panel = true
ToastManager.add_notification("quest_1", "New quest available", NotificationPanel.Priority.HIGH, func(): open_quest("quest_1"))
ToastManager.remove_notification("quest_1")
ToastManager.clear_all_notifications()
```

Priority levels: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

## Theming

- `Toast.tscn` declares `theme_type_variation = &"ToastPanel"` and otherwise has no theme overrides; it inherits your project theme through that variation.
- `Toast._apply_visuals_for_kind()` looks up the panel `StyleBoxFlat` via the node's own type variation (i.e. `ToastPanel` if defined, otherwise `PanelContainer`), duplicates it, and only adjusts `border_color` per kind.
- If your theme does not provide a `StyleBoxFlat` for the relevant type, the addon leaves the style untouched.

### Host Theme

`ToastManager.ui_theme` is an optional `Theme` applied to every spawned toast. Set it at runtime to share a project theme with CanvasLayer-based toast UI that would otherwise lose the game root theme:

```gdscript
ToastManager.ui_theme = preload("res://resources/themes/my_theme.tres")
```

The addon is theme-neutral by default.

### Runtime Stack Box Tweaks

`set_stack_box(key, config)` updates an existing stack box's insets at runtime and re-layouts the stack. Useful for adapting to safe areas, notch insets, or dynamic UI:

```gdscript
ToastManager.set_stack_box("BR", {"bottom": 80.0})
```

### Pause Awareness

`ToastManager` runs with `process_mode = PROCESS_MODE_ALWAYS`, so milestone/settings feedback remains usable from pause UI. Children inherit this mode, so spawned toasts also process during pause.

### Idempotent Autoload

The plugin registers the `ToastManager` autoload only when one is not already declared in `ProjectSettings`, and removes only what it registered. Projects that prefer to declare the autoload explicitly in `project.godot` no longer collide with the plugin.

## Optional: Compile When Plugin Is Disabled

```gdscript
func toast_safe(msg: String, kind := "info", opts := {}, pos := "") -> void:
    var n := get_tree().root.get_node_or_null("/root/ToastManager")
    if n:
        n.call("show_toast", msg, kind, opts, pos)
    else:
        print("[toast]", kind, msg)
```

## Troubleshooting

- **"Identifier ToastManager not declared"**: Enable the plugin, or use the `toast_safe` wrapper below with `ToastManager` as the autoload name.
- **Toasts not visible**: Verify `/root/ToastManager` exists at runtime. Check CanvasLayer order; bump `ToastManager`'s layer if needed.
- **Background gray ignoring theme**: Confirm `Toast.tscn` has no `theme_override_styles/panel` lines. Your theme should style `ToastPanel` (preferred) or `PanelContainer/panel`.

## License

MIT
