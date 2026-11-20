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

@onready var hotbar_ui: HBoxContainer = %HotbarUI
@onready var healthbar: ProgressBar = %Healthbar
@onready var head: Node3D = $Head
@onready var axe_raycast: RayCast3D = $Head/Camera3D/AxeRaycast
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var levelbar: ProgressBar = %Levelbar
@onready var maxlevelhit_label: Label = %MAXLEVELHITLabel
@onready var touch_controls: Control = %TouchControls
@onready var shop_ui: CanvasLayer = $UI/ShopUI
@onready var d_45_raycast: RayCast3D = $Head/Camera3D/D45Raycast

var hover_time := 0.0
var broke_rock := false
var max_popup_triggered := false
var current_hotbar_index := 0

func _ready() -> void:
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
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if event.is_action_pressed("toggle_shop"):
		toggle_shop()

func _physics_process(delta: float) -> void:
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
	if Input.is_action_just_pressed("hotbar_1"):
		if weapons_manager.weapons_disabled.get(d45_node, true) == false \
				and weapons_manager.weapons_disabled.get(axe_node, true) == true:
			current_hotbar_index = 0
			d45_node.visible = false
			axe_node.visible = true
			weapons_manager.weapons_disabled[d45_node] = true
			weapons_manager.weapons_disabled[axe_node] = false
			print("Equipped axe | Hotbar index: " + str(current_hotbar_index))
	
	# hotbar 2 (d-45)
	if Input.is_action_just_pressed("hotbar_2"):
		if weapons_manager.weapons_disabled.get(d45_node, true) == true \
				and weapons_manager.weapons_disabled.get(axe_node, true) == false:
			current_hotbar_index = 1
			d45_node.visible = true
			axe_node.visible = false
			weapons_manager.weapons_disabled[d45_node] = false
			weapons_manager.weapons_disabled[axe_node] = true
			print("Equipped d45 | Hotbar index: " + str(current_hotbar_index))
			
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

	if broke_rock:
		handle_levelup()
		broke_rock = false

func _hit_with_axe():
	anim_player.play("hit_axe")

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

	var attack = Attack.new()
	attack.attack_damage = attack_damage
	print("DEALT DAMAGE VALUE IS: ", attack.attack_damage) # <-- Add this line!
	ht_hitbox_component.damage(attack)
	
	var health = ht_hitbox_component.health_component.health
	var rock_parent = ht_hitbox_component.get_parent()
	
	if health <= 0.0 and rock_parent is GreenRock:
		var alien = get_tree().current_scene.get_node("Alien")
		if alien:
			alien.placed_rocks -= 1
			
	if health <= 0.0 and (rock_parent is GreenRock or rock_parent is NormalRock):
		broke_rock = true
		
func _hit_with_d45():
	anim_player.play("hit_d45")
	
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

	var attack = Attack.new()
	attack.attack_damage = attack_damage
	print("DEALT DAMAGE VALUE IS: ", attack.attack_damage) # <-- Add this line!
	ht_hitbox_component.damage(attack)
	
	var health = ht_hitbox_component.health_component.health
	var rock_parent = ht_hitbox_component.get_parent()
	
	if health <= 0.0 and rock_parent is GreenRock:
		var alien = get_tree().current_scene.get_node("Alien")
		if alien:
			alien.placed_rocks -= 1
			
	if health <= 0.0 and (rock_parent is GreenRock or rock_parent is NormalRock):
		broke_rock = true

func handle_levelup():
	# If we are already maxed out, don't try to level up further
	if stats.level >= stats.MAX_LEVEL:
		return
	
	stats.level += 1.0
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if stats:
			stats.save()
		get_tree().quit()

func toggle_shop():
	shop_ui.visible = not shop_ui.visible
	if shop_ui.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
