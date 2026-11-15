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

@export_group("Idle Hover Settings")
@export var hover_speed := 2.0      # How fast the bobbing cycle goes
@export var hover_strength := 0.5   # How high/low the character bobs

@onready var head: Node3D = $Head
@onready var weapon_raycast: RayCast3D = $Head/Camera3D/WeaponRaycast
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var levelbar: ProgressBar = %Levelbar
@onready var maxlevelhit_label: Label = %MAXLEVELHITLabel

var hover_time := 0.0
var attack_damage := 10.0
var broke_rock := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	
	if Input.is_action_pressed("left_mouse") and not anim_player.is_playing():
		anim_player.play("hit_axe")
		
		# 👇 Calculate damage on the fly based on current level!
		attack_damage = 10.0 + (stats.level * 1.0) + (pow(stats.level, 1.3) * 0.4)
		
		#match stats.level:
			#0.0:
				#attack_damage = 10.0
			#1.0:
				#attack_damage = 10.2
			#2.0:
				#attack_damage = 10.4
			#3.0:
				#attack_damage = 10.8
			#4.0:
				#attack_damage = 12.0
			#5.0:
				#attack_damage = 12.5
			#6.0:
				#attack_damage = 12.9
			#7.0:
				#attack_damage = 14.2
			#8.0:
				#attack_damage = 14.8
			#9.0:
				#attack_damage = 15.1
			#10.0:
				#attack_damage = 15.6
			#11.0:
				#attack_damage = 15.9
			#12.0:
				#attack_damage = 16.5
			#13.0:
				#attack_damage = 17.0
			#14.0:
				#attack_damage = 20.0
			#15.0:
				#attack_damage = 22.6
			#16.0:
				#attack_damage = 24.0
			#17.0:
				#attack_damage = 24.5
			#18.0:
				#attack_damage = 28.0
			#19.0:
				#attack_damage = 30.2
			#20.0:
				#attack_damage = 30.6
			#21.0:
				#attack_damage = 31.21
			#22.0:
				#attack_damage = 33.0
			#23.0:
				#attack_damage = 33.1
			#24.0:
				#attack_damage = 33.6
			#25.0:
				#attack_damage = 33.8
			#26.0:
				#attack_damage = 34.2
			#27.0:
				#attack_damage = 34.6
			#28.0:
				#attack_damage = 35.0
			#29.0:
				#attack_damage = 35.2
			#30.0:
				#attack_damage = 35.6
			#31.0:
				#attack_damage = 35.9
			#32.0:
				#attack_damage = 36.1
			#33.0:
				#attack_damage = 37.23
			#34.0:
				#attack_damage = 37.63
			#35.0:
				#attack_damage = 38.81
			#36.0:
				#attack_damage = 40.05
			#37.0:
				#attack_damage = 40.51
			#38.0:
				#attack_damage = 41.2
			#39.0:
				#attack_damage = 41.52
			#40.0:
				#attack_damage = 45.83
			#41.0:
				#attack_damage = 46.0
			#42.0:
				#attack_damage = 48.57
			#43.0:
				#attack_damage = 48.64
			#44.0:
				#attack_damage = 49.12
			#45.0:
				#attack_damage = 49.19
			#46.0:
				#attack_damage = 50.19
			#47.0:
				#attack_damage = 51.31
			#48.0:
				#attack_damage = 54.51
			#49.0:
				#attack_damage = 56.89
			#50.0:
				#attack_damage = 60.15
			#_:
				#attack_damage = 70.0 # Level 5+ or fallback
				
		if weapon_raycast.is_colliding():
			var hit_rock = weapon_raycast.get_collider()
			if hit_rock :
				var ht_hitbox_component: HitboxComponent = hit_rock.get_node_or_null("HitboxComponent")
				if ht_hitbox_component:
					var attack = Attack.new()
					attack.attack_damage = attack_damage
					print("DEALT DAMAGE VALUE IS: ", attack.attack_damage) # <-- Add this line!
					ht_hitbox_component.damage(attack)
					if ht_hitbox_component.health_component.health <= 0.0 \
							and ht_hitbox_component.get_parent() is GreenRock:
						var alien = get_tree().current_scene.get_node_or_null("Alien")
						if alien:
							alien.placed_rocks -= 1
					if ht_hitbox_component.health_component.health <= 0.0 \
							and ht_hitbox_component.get_parent() is GreenRock \
							or ht_hitbox_component.health_component.health <= 0.0 \
							and ht_hitbox_component.get_parent() is NormalRock:
						broke_rock = true
				else:
					push_error("ht_hitbox_component not found!")
			else:
				push_error("hit_rock not found!")
				
	if broke_rock:
		stats.level += 1.0
		levelbar.value = stats.level
		broke_rock = false
		print("level up! %s" % stats.level)
		
	if stats.level == stats.MAX_LEVEL:
		maxlevelhit_label.show()
		await get_tree().create_timer(2.0).timeout
		maxlevelhit_label.hide()
	else:
		maxlevelhit_label.hide()
