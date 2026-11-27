extends CharacterBody3D
class_name Player

@export var speed := 10.0
@export var acceleration := 15.0
@export var deceleration := 10.0
@export var down_strength := 10.0
@export var vertical_accel := 20.0
@export var gravity := 9.8
@export var mouse_sensitivity := .005
@export var stats: Stats
@export var health_component: HealthComponent
@export var attack_damage := 10.0
@export var weapons_manager: WeaponsManager
@export var d45_node: Node3D
@export var axe_node: Node3D

@export_group("Idle Hover Settings")
@export var hover_speed := 2.0      # How fast the bobbing cycle goes
@export var hover_strength := 0.5   # How high/low the character bobs
@export var username := "":
	set(value):
		username = value
		if is_node_ready():
			nametag.text = value

@onready var hotbar_ui: HBoxContainer = %HotbarUI
@onready var healthbar: ProgressBar = %Healthbar
@onready var head: Node3D = $Head
@onready var axe_raycast: RayCast3D = $Head/Camera3D/AxeRaycast
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var levelbar: ProgressBar = %Levelbar
@onready var maxlevelhit_label: Label = %MAXLEVELHITLabel
@onready var touch_controls: Control = %TouchControls
@onready var d_45_raycast: RayCast3D = $Head/Camera3D/D45Raycast
@onready var d_45_sfx: AudioStreamPlayer3D = $d45sfx
@onready var axe_sfx: AudioStreamPlayer3D = $AxeSFX
@onready var nametag: Label3D = %Nametag

var hover_time := 0.0
var max_popup_triggered := false
var current_hotbar_index := 0

func _enter_tree() -> void:
	var id := name.to_int()
	set_multiplayer_authority(id, false) # false = only this node, not children
	# the position synchronizer should still come from the owning client:
	$MultiplayerSynchronizer.set_multiplayer_authority(id)  # use your node's real name

func _ready() -> void:
	if not is_multiplayer_authority():
		$UI.hide()
		$Head/Camera3D.current = false  # remote players must never take over your view
		return
	
	$Head/Camera3D.current = true
	nametag.text = username
	username = Global.player_username
	nametag.visible = not is_multiplayer_authority()
	
	stats = Stats.load_stats()
	print("Loaded player level: ", stats.level)
	
	levelbar.value = stats.level
	
	if OS.has_feature("pc"):
		touch_controls.hide()
	if OS.has_feature("mobile"):
		touch_controls.show()
		
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_component.health_changed.connect(_on_health_comp_health_changed)
	
	current_hotbar_index = 1
	d45_node.visible = true
	axe_node.visible = false
	weapons_manager.weapons_disabled[d45_node] = false
	weapons_manager.weapons_disabled[axe_node] = true
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Track elapsed time for the smooth sine wave
	hover_time += delta * hover_speed
	
	# 1. Get horizontal and vertical input
	var _input_dir := Input.get_vector("left", "right", "forward", "backward")
	var vertical_dir := Input.get_axis("down_crouch", "jump")
	
	# 2. Combine into a 3D movement direction
	var direction := (transform.basis * Vector3(_input_dir.x, vertical_dir, _input_dir.y)).normalized()
	
	# 3. Accelerate when moving, or glide into a smooth idle hover when stopped
	if direction != Vector3.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		# Calculate gentle up-and-down bobbing velocity
		var hover_velocity := Vector3(0, sin(hover_time) * hover_strength, 0)
		velocity = velocity.move_toward(hover_velocity, deceleration * delta)

	move_and_slide()
	
	# -- HOTBAR SWITCHING --
	# 1. EQUIPPING WEAPONS (it runs only when pressing 1 or 2)
	# hotbar 1 (axe)
	if Input.is_action_just_pressed("hotbar_1") and current_hotbar_index != 0:
		_equip.rpc(0)
	
	# hotbar 2 (d-45)
	if Input.is_action_just_pressed("hotbar_2") and current_hotbar_index != 1:
		_equip.rpc(1)
			
	# hotbar 3
	# its empty so well just do nothing
	# 2 hotbars is good
	
	# 2. USE CURRENTLY EQUIPPED WEAPON (runs whenever left_mouse is pressed)
	
	if current_hotbar_index == 0:
		hotbar_ui.get_node("Slot1").modulate = Color(1, 1, 1, 1.0)
		hotbar_ui.get_node("Slot2").modulate = Color(1, 1, 1, 0.5)
		if Input.is_action_pressed("left_mouse") and not anim_player.is_playing():
			print("hit with axe")
			_hit_with_axe()

	elif current_hotbar_index == 1:
		hotbar_ui.get_node("Slot1").modulate = Color(1, 1, 1, 0.5)
		hotbar_ui.get_node("Slot2").modulate = Color(1, 1, 1, 1.0)
		if Input.is_action_just_pressed("left_mouse"):
			print("hit with d45")
			_hit_with_d45()

	else:
		hotbar_ui.get_node("Slot1").modulate = Color(1, 1, 1, 0.5)
		hotbar_ui.get_node("Slot2").modulate = Color(1, 1, 1, 0.5)

func _hit_with_axe():
	_play_attack.rpc("hit_axe")

	# 👇 Calculate damage on the fly based on current level!
	# Gentle curve that grows slowly and hits 50+ damage around level 45-48
	attack_damage = 10.0 + (stats.level * 0.6) + (pow(stats.level, 1.1) * 0.2)
	
	if not axe_raycast.is_colliding():
		return

	var hit_rock = axe_raycast.get_collider()
	if not hit_rock:
		push_error("hit rock not found")
		return

	var ht_hitbox_component: HitboxComponent = hit_rock.get_node_or_null("HitboxComponent")
	if not ht_hitbox_component:
		push_error("ht_hitbox_component not found!")
		return

	_deal_damage(hit_rock, attack_damage)
	
	if hit_rock is GreenRock or hit_rock is NormalRock:
		hit_rock.get_node("SelfSFX").play()

func _hit_with_d45():
	_play_attack.rpc("hit_d45")

	attack_damage = 100.0
	
	if not d_45_raycast.is_colliding():
		return

	var hit_rock = d_45_raycast.get_collider()
	if not hit_rock:
		push_error("hit rock not found")
		return

	var ht_hitbox_component: HitboxComponent = hit_rock.get_node_or_null("HitboxComponent")
	if not ht_hitbox_component:
		push_error("ht_hitbox_component not found!")
		return

	_deal_damage(hit_rock, attack_damage)
		
	if hit_rock is GreenRock or hit_rock is NormalRock:
		hit_rock.get_node("SelfSFX").play()

func handle_levelup():
	print("[handle_levelup func] this func is being called")
	# If we are already maxed out, don't try to level up further
	if stats.level >= stats.MAX_LEVEL:
		return
	
	stats.level += 1.0
	print("leveld up")
	stats.save()
	levelbar.value = stats.level
	print("level up %s" % stats.level)
	
	# Check if this exact level-up hit max level FOR THE FIRST TIME
	if stats.level >= stats.MAX_LEVEL and not max_popup_triggered:
		max_popup_triggered = true
		show_max_level_popup()
		
func show_max_level_popup():
	maxlevelhit_label.show()
	await get_tree().create_timer(2.0).timeout
	maxlevelhit_label.hide()

func _on_health_comp_health_changed(new_health: float):
	healthbar.value = new_health

@rpc("any_peer", "call_local", "reliable")
func respawn(pos: Vector3) -> void:
	var sender = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return  # ignore anyone but the host
	global_position = pos
	velocity = Vector3.ZERO

# Called by both weapons after a raycast hit (raycast stays on the client).
func _deal_damage(target: Node, dmg: float) -> void:
	if multiplayer.is_server():
		print("applying _server_damage")
		_server_apply_damage(target.get_path(), dmg)
		print("applyed _server_damage")
	else:
		print("requesting _request_damage")
		_request_damage.rpc_id(1, target.get_path(), dmg)
		print("requested _request_damage")

# Client -> host. "authority" works because the sender owns this Player node.
@rpc("authority", "call_remote", "reliable")
func _request_damage(target_path: NodePath, dmg: float) -> void:
	print("[_request_damage] this func is being called")
	_server_apply_damage(target_path, dmg)
	print("[_request_damage] applyed _server_damage")

# Runs on the host only.
func _server_apply_damage(target_path: NodePath, dmg: float) -> void:
	var target := get_node_or_null(target_path)
	if target == null:
		return # already destroyed
	var hitbox: HitboxComponent = target.get_node_or_null("HitboxComponent")
	if hitbox == null:
		return

	var attack := Attack.new()
	attack.attack_damage = dmg

	var rock_parent := hitbox.get_parent()
	var killed := hitbox.damage(attack)   # only ONE call

	if not killed:
		return

	if rock_parent is GreenRock:
		var alien = Global.get_alien()
		if alien:
			alien.placed_rocks -= 1

	if rock_parent is GreenRock or rock_parent is NormalRock:
		if get_multiplayer_authority() == multiplayer.get_unique_id():
			handle_levelup()
		else:
			_rock_broken.rpc_id(get_multiplayer_authority())

# Host -> owning client.
@rpc("any_peer", "call_remote", "reliable")
func _rock_broken() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return # only the host can tell us
	handle_levelup()

@rpc("authority", "call_local", "reliable")
func _equip(index: int) -> void:
	current_hotbar_index = index
	axe_node.visible = (index == 0)
	d45_node.visible = (index == 1)
	weapons_manager.weapons_disabled[axe_node] = (index != 0)
	weapons_manager.weapons_disabled[d45_node] = (index != 1)

@rpc("authority", "call_local", "reliable")
func _play_attack(anim_name: String) -> void:
	anim_player.play(anim_name)
	if anim_name == "hit_axe":
		axe_sfx.play()
	else:
		d_45_sfx.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if stats:
			stats.save()
		get_tree().quit()
