extends CharacterBody3D
class_name Alien

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
var disabled := false
var is_dangerous_rain_triggered := false

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

func _process(_delta: float) -> void:
	if not disabled:
		check_rain_trigger()
		
		var local_player := Network.get_local_player()
		if local_player == null:
			return
		var label := local_player.get_node_or_null("UI/SpaceDangerLabel")
		if label:
			label.visible = placed_rocks >= 6

func place_rock() -> bool:
	if disabled or not multiplayer.is_server():
		return false

	var green_rocks_container = get_tree().current_scene.get_node("GreenRocks")

	if green_rocks_container.get_child_count() >= MAX_GREEN_ROCKS:
		print("Max rocks reached (%d). Cannot spawn any more." % MAX_GREEN_ROCKS)
		return false

	var green_rock := GREEN_ROCK.instantiate() as GreenRock
	green_rock.position = Vector3(
		randf_range(-50.0, 50.0),
		randf_range(-20.0, 20.0),
		randf_range(-50.0, 50.0)
	)
	green_rocks_container.add_child(green_rock, true)
	return true

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
		
func check_rain_trigger() -> void:
	if not multiplayer.is_server():
		return
	if placed_rocks >= 10 and not is_dangerous_rain_triggered:
		is_dangerous_rain_triggered = true
		_spawn_dangerous_object(15.0)
		print("It's raining dangerous objects!")


func _on_rain_d_object_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	if placed_rocks >= 10:
		for i in range(50):
			_spawn_dangerous_object(150.0)
			print("It's raining dangerous objects!")

func _spawn_dangerous_object(spread: float) -> void:
	var container := get_tree().current_scene.get_node("DangerousObjects")
	var obj := DANGEROUS_OBJECT.instantiate() as Node3D
	var random_offset := Vector3(
		randf_range(-spread, spread),
		randf_range(15.0, 20.0),
		randf_range(-spread, spread)
	)
	obj.position = Vector3(0, 15, 0) + random_offset
	container.add_child(obj, true)  # spawner copies it to clients
	create_tween().tween_callback(obj.queue_free).set_delay(5.0)  # host frees it, clients follow
