extends CharacterBody3D
class_name Player

@export var speed := 10.0
@export var acceleration := 15.0
@export var deceleration := 10.0
@export var down_strength := 10.0
@export var vertical_accel := 20.0
@export var gravity := 9.8
@export var mouse_sensitivity := .005

@export_group("Idle Hover Settings")
@export var hover_speed := 2.0      # How fast the bobbing cycle goes
@export var hover_strength := 0.5   # How high/low the character bobs

@onready var head: Node3D = $Head
@onready var weapon_raycast: RayCast3D = $Head/Camera3D/WeaponRaycast
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var hover_time := 0.0
var attack_damage := 10.0

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
		if weapon_raycast.is_colliding():
			var hit_rock = weapon_raycast.get_collider()
			if hit_rock :
				var ht_hitbox_component: HitboxComponent = hit_rock.get_node_or_null("HitboxComponent")
				if ht_hitbox_component:
					var attack = Attack.new()
					attack.attack_damage = attack_damage
					ht_hitbox_component.damage(attack)
					if ht_hitbox_component.health_component.health <= 0.0 \
						and ht_hitbox_component.get_parent() is GreenRock:
						var alien = get_tree().current_scene.get_node_or_null("Alien")
						if alien:
							alien.placed_rocks -= 1
				else:
					push_error("ht_hitbox_component not found!")
			else:
				push_error("hit_rock not found!")
