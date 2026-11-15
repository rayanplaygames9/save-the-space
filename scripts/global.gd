extends Node

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _ready() -> void:
	if OS.has_feature("pc"):
		get_tree().current_scene.get_node_or_null("Player").get_node_or_null("UI/TouchControls").hide()
	if OS.has_feature("mobile"):
		get_tree().current_scene.get_node_or_null("Player").get_node_or_null("UI/TouchControls").show()
