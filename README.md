ProperUI Toast (Godot 4.x)
Lightweight, theme-friendly toast notifications with stacking, queueing, and 9 anchor positions. Inherits your project Theme; only border color changes per “kind”.

Features
- 9 positions: TL, T, TR, ML, C, MR, BL, B, BR
- Stacking with per-position max_active and queued promotion
- Hover pauses auto-dismiss; persistent mode; reduced motion option
- CanvasLayer so it renders above game UI
- Theme-first: inherits PanelContainer/panel style and your fonts
- Minimal runtime override (border_color per kind)

Install
- Copy addons/properUI_toast into your project.
- Project > Project Settings > Plugins → enable “ProperUI Toast”.
  - Enabling registers the autoload singleton /root/ProperUIToast (ToastManager.gd).
  - We do not remove the autoload on disable so references don’t break; remove it manually if needed.

Quick start
- Show a toast anywhere:
  ProperUIToast.show_toast("Saved!", "success")
  ProperUIToast.show_toast("Heads up", "warning", {"display_sec": 5.0}, "TR")

- Kinds: "success" | "info" | "warning" | "error"
- Positions: TL, T, TR, ML, C, MR, BL, B, BR
- Options (opts):
  - display_sec: float (default 3.0)
  - fade_sec: float (default 0.20)
  - slide_px: float (default 56.0)
  - reduced_motion: bool (default false, also available globally on manager)
  - persistent: bool (default false)

Manager properties (exported)
- default_position (String, default "BR")
- spacing_px (float)
- reduced_motion (bool)
- toast_widths (Dictionary per position)
- max_active (Dictionary per position)
- stack_boxes (Insets per position, converted to offsets based on anchors)

Scene tree
- The manager creates a CanvasLayer (default layer = 100) and 9 stack roots (Control).
- If your UI renders above layer 100, increase the manager layer in ToastManager.gd.

Theming
- Toast.tscn has no theme overrides; it inherits your project theme.
- Toast.gd duplicates the theme StyleBoxFlat from PanelContainer/panel and only adjusts border_color per kind (and optionally reduces alpha slightly).
- If your theme does not provide StyleBoxFlat for PanelContainer, the addon leaves the style untouched and uses your theme as-is.

Optional: compile when plugin is disabled
If you need your game to compile without the plugin enabled, wrap calls:
  func toast_safe(msg: String, kind := "info", opts := {}, pos := "") -> void:
    var n := get_tree().root.get_node_or_null("/root/ProperUIToast")
    if n:
      n.call("show_toast", msg, kind, opts, pos)
    else:
      print("[toast]", kind, msg)

Troubleshooting
- “Identifier ProperUIToast not declared”: Enable the plugin. Or use toast_safe wrapper for optional dependency.
- Toasts not visible:
  - Verify /root/ProperUIToast exists at runtime (print(get_tree().root.has_node("/root/ProperUIToast"))).
  - Check CanvasLayer order; bump ToastManager’s layer if needed.
  - Ensure you aren’t calling clear_all immediately after show_toast.
- Background gray ignoring theme:
  - Confirm Toast.tscn has no theme_override_styles/panel lines.
  - Your theme should style PanelContainer/panel. If not, the addon keeps defaults.

Contributing
- Keep warnings at zero.
- Respect project theme; avoid hardcoded colors beyond “kind” accents.

License
- MIT

Changelog
- 1.0.0: Initial release
