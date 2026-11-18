extends CharacterBody3D

@export var acceleration := 25.0

@onready var start_move_timer: Timer = %StartMoveTimer
@onready var stop_vel_timer: Timer = %StopVelTimer

## constant scenes
const GREEN_ROCK = preload("uid://b07qvnwfs8w1n")
const DANGEROUS_OBJECT = preload("uid://cts34uc3idrbh")

## constant variables
const MAX_GREEN_ROCKS := 100

## variables
var directions := [
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.FORWARD,
	Vector3.BACK
]

var speed: float = 5.0
var random_dir: Vector3
static var placed_rocks := 0
var player: Player
var green_rock_pool: Array[GreenRock] = []
var disabled := false
var is_dangerous_rain_triggered := false

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("Player")
	
	# Pre-instantiate Green Rocks and hide them
	for i in range(MAX_GREEN_ROCKS):
		var green_rock = GREEN_ROCK.instantiate() as GreenRock
		green_rock.visible = false
	
		# Disable collision shape on start
		green_rock.get_node("CollisionShape3D").disabled = true
		green_rock.get_node("HitboxComponent/CollisionShape3D").disabled = true
		
		# add pre-instantiated g_rocks to scene
		get_tree().current_scene.add_child(green_rock)
		# fill pool
		green_rock_pool.append(green_rock)

func _physics_process(delta: float) -> void:
	if not disabled:
		move_and_slide()

		# Only rotate if the alien is actually moving to avoid errors/snapping
		if velocity.length_squared() > .01:
			# Create a target point ahead of the alien, keeping Y flat so it doesn't tilt
			var look_target := global_position + Vector3(velocity.x, 0, velocity.z)
			look_at(look_target, Vector3.UP)
		if velocity != Vector3.ZERO:
			velocity = velocity.move_toward(random_dir * speed, acceleration * delta)

func _process(delta: float) -> void:
	if not disabled:
		check_rain_trigger()

		if placed_rocks >= 6:
			var player_danger_label = player.get_node_or_null("UI/SpaceDangerLabel")
			if player_danger_label:
				player_danger_label.show()
		else:
			var player_danger_label = player.get_node_or_null("UI/SpaceDangerLabel")
			if player_danger_label:
				player_danger_label.hide()

func place_rock() -> bool:
	if disabled:
		return false

	for g_rock in green_rock_pool:
		if not g_rock.visible:
			g_rock.position = position + Vector3(randf_range(-5.0, 5.5), 0, randf_range(-10.5, 2.0))
			g_rock.visible = true
			
			g_rock.get_node("CollisionShape3D").disabled = false
			g_rock.get_node("HitboxComponent/CollisionShape3D").disabled = false
				
			var health_comp: HealthComponent = g_rock.get_node_or_null("HealthComponent")
			if health_comp:
				health_comp.health = health_comp.MAX_HEALTH
				
			return true # Successfully placed a rock!
			
	# If the loop finishes without finding an inactive rock:
	print("Max green rocks reached! Alien cannot place more.")
	return false # Pool is full, nothing placed
			
func _on_start_move_timer_timeout() -> void:
	if not disabled:
		random_dir = directions.pick_random()
		velocity = speed * random_dir
		stop_vel_timer.start()

func _on_stop_vel_timer_timeout() -> void:
	if not disabled:
		velocity = Vector3.ZERO
		
		# Only increment and print if place_rock() actually succeeded!
		if place_rock():
			placed_rocks += 1
			print("Alien placed rocks: %s" % placed_rocks)
			
		start_move_timer.start()
		
func check_rain_trigger():
	if placed_rocks >= 10 and not is_dangerous_rain_triggered:
		is_dangerous_rain_triggered = true # Prevents it from running every frame!
		
		for i in range(50):
			var dangerous_object = DANGEROUS_OBJECT.instantiate()
			
			# Scatter them randomly around the sky above the alien
			var random_offset := Vector3(randf_range(-15.0, 15.0), randf_range(15.0, 20.0), randf_range(-15.0, 15.0))
			dangerous_object.position = Vector3(0, 15, 0) + random_offset
			
			get_tree().current_scene.add_child(dangerous_object)
			
			# This runs in the background and destroys this specific object after 5 seconds
			create_tween().tween_callback(dangerous_object.queue_free).set_delay(5.0)

		print("It's raining dangerous objects!")

func _on_rain_d_object_timer_timeout() -> void:
	if placed_rocks >= 10:
		for i in range(50):
			var dangerous_object = DANGEROUS_OBJECT.instantiate()
			
			# Scatter them randomly around the sky above the alien
			var random_offset := Vector3(randf_range(-150.0, 150.0), randf_range(15.0, 20.0), randf_range(-150.0, 150.0))
			dangerous_object.position = Vector3(0, 15, 0) + random_offset
			
			get_tree().current_scene.add_child(dangerous_object)
			
			# This runs in the background and destroys this specific object after 5 seconds
			create_tween().tween_callback(dangerous_object.queue_free).set_delay(5.0)
