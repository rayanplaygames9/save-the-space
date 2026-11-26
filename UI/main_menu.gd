extends Control

@onready var host_btn: Button = %HostBtn
@onready var h_separator: HSeparator = %HSeparator
@onready var code_input: LineEdit = %CodeInput
@onready var join_btn: Button = %JoinBtn
@onready var code_row: HBoxContainer = %CodeRow
@onready var code_label: Label = %CodeLabel
@onready var copy_btn: Button = %CopyBtn
@onready var status_label: Label = %StatusLabel
@onready var start_game_btn: Button = %StartGameBtn
@onready var play_offline_btn: Button = %PlayOfflineBtn
@onready var timer: Timer = $Timer
@onready var username_input: LineEdit = %UsernameInput

func _ready() -> void:
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	copy_btn.pressed.connect(_on_copy_pressed)
	play_offline_btn.pressed.connect(func(): Network.play_offline())
	code_input.text_submitted.connect(func(_t): _on_join_pressed())
	code_input.text_changed.connect(_on_code_changed)
	join_btn.disabled = true
	code_row.hide()
	status_label.text = ""
	start_game_btn.hide()
	start_game_btn.pressed.connect(func(): Network.start_game())
	multiplayer.peer_connected.connect(_on_peer_connected)
	timer.start()
	timer.timeout.connect(_hide_splash_screen)
	
	Network.status_changed.connect(func(m: String): status_label.text = m)
	Network.room_ready.connect(_on_room_ready)
	Network.join_failed.connect(_on_join_failed)
	Network.joined.connect(func(): status_label.text = "Connected!")

func _on_code_changed(new_text: String) -> void:
	join_btn.disabled = new_text.strip_edges().is_empty()

func _on_host_pressed() -> void:
	var username = username_input.text.strip_edges()
	if username.is_empty():
		print("You need to type a username!")
		return
	Global.player_username = username
	_set_busy(true, "Creating room...")
	Network.host()

func _on_join_pressed() -> void:
	var code = code_input.text.strip_edges()
	var username = username_input.text.strip_edges()
	if code.is_empty():
		return
	if username.is_empty():
		print("You need to type a username!")
		return
	Global.player_username = username
	_set_busy(true, "Connecting...")
	Network.join(code)
	
	

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(code_label.text.replace("Room code: ", ""))
	status_label.text = "Code copied!"

func _set_busy(busy: bool, message: String) -> void:
	host_btn.disabled = busy
	join_btn.disabled = busy or code_input.text.strip_edges().is_empty()
	code_input.editable = not busy
	status_label.text = message

func _on_room_ready(code: String) -> void:
	code_label.text = "Room code: " + code
	code_row.show()

func _on_join_failed(reason: String) -> void:
	_set_busy(false, reason)

func _on_peer_connected(_id: int) -> void:
	if multiplayer.is_server():
		start_game_btn.show()

func _hide_splash_screen() -> void:
	$SplashScreen.hide()
