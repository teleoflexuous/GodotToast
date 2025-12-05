extends Control

@onready var grid_container: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/GridContainer

func _ready() -> void:
	# Note: This requires the 'ToastManager' autoload to be enabled in Project Settings.
	# The plugin script handles adding it, but if you are running this scene alone 
	# without the plugin enabled, it might fail.
	
	_create_button("Info Toast", func(): ToastManager.show_toast("This is an info message.", "info"))
	_create_button("Success Toast", func(): ToastManager.show_toast("Operation completed successfully!", "success"))
	_create_button("Warning Toast", func(): ToastManager.show_toast("Disk space is running low.", "warning"))
	_create_button("Error Toast", func(): ToastManager.show_toast("Failed to connect to server.", "error"))
	
	_create_button("Toast with Action", func(): 
		ToastManager.show_toast("File deleted.", "info", {
			"action": { "text": "Undo", "name": "undo" },
			"display_sec": 5.0
		}))
		
	_create_button("Persistent Toast", func():
		ToastManager.show_toast("I will stay until dismissed.", "info", {
			"persistent": true
		}))

	_create_button("Top Left", func(): ToastManager.show_toast("Hello from Top Left", "info", {}, "TL"))
	_create_button("Top Center", func(): ToastManager.show_toast("Hello from Top Center", "success", {}, "T"))
	_create_button("Bottom Left", func(): ToastManager.show_toast("Hello from Bottom Left", "warning", {}, "BL"))
	
	_create_button("Flood Queue", func():
		for i in range(5):
			ToastManager.show_toast("Queued Message %d" % i, "info")
	)
	
	_create_button("Clear All", func(): ToastManager.clear_all())

func _create_button(text: String, callable: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callable)
	grid_container.add_child(btn)
