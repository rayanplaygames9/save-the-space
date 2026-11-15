extends CharacterBody3D

@export var acceleration := 25.0

@onready var start_move_timer: Timer = %StartMoveTimer
@onready var stop_vel_timer: Timer = %StopVelTimer

const GREEN_ROCK = preload("uid://b07qvnwfs8w1n")

var directions := [
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.FORWARD,
	Vector3.BACK
]

var speed: float = 5.0
var random_dir: Vector3
var placed_rocks := 0
var player: Player

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("Player")

func _physics_process(delta: float) -> void:
	move_and_slide()
	
	# Only rotate if the alien is actually moving to avoid errors/snapping
	if velocity.length_squared() > .01:
		# Create a target point ahead of the alien, keeping Y flat so it doesn't tilt
		var look_target := global_position + Vector3(velocity.x, 0, velocity.z)
		look_at(look_target, Vector3.UP)
	if velocity != Vector3.ZERO:
		velocity = velocity.move_toward(random_dir * speed, acceleration * delta)

func _process(delta: float) -> void:
	if placed_rocks >= 6:
		var player_danger_label = player.get_node_or_null("UI/SpaceDangerLabel")
		if player_danger_label:
			player_danger_label.show()
	else:
		var player_danger_label = player.get_node_or_null("UI/SpaceDangerLabel")
		if player_danger_label:
			player_danger_label.hide()

func place_rock():
	var green_rock = GREEN_ROCK.instantiate()
	green_rock.position = position + Vector3(randf_range(-5.0, 5.5), 0, randf_range(-10.5, 2.0))
	get_tree().current_scene.add_child(green_rock)
	
	if green_rock.position == position or global_position:
		green_rock.position = green_rock.global_position + Vector3(5.0, 0.0, 5.0)

func _on_start_move_timer_timeout() -> void:
	random_dir = directions.pick_random()
	velocity = speed * random_dir
	stop_vel_timer.start()

func _on_stop_vel_timer_timeout() -> void:
	velocity = Vector3.ZERO
	place_rock()
	placed_rocks += 1
	print("Alien placed rocks: %s" % placed_rocks)
	start_move_timer.start()
