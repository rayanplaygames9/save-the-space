extends Node3D

## constant scenes
const ROCK = preload("uid://cnrrhibhfrfxq")
const ALIEN = preload("uid://b242ndeq5lfjs")

## constant variables
const MAX_ROCKS := 100
const MAX_ALIENS := 15

## variables
var can_spawn_rock := true
var can_spawn_alien := true

func spawn_rock():
	var rock = ROCK.instantiate()
	
	# randomized position variables
	var rand_x = randf_range(-50.0, 50.0)
	var rand_y = randf_range(-5.0, 5.0)
	var rand_z = randf_range(-50.0, 50.0)
	
	rock.position = Vector3(rand_x, rand_y, rand_z)
	get_tree().current_scene.add_child(rock)

func spawn_alien():
	var alien = ALIEN.instantiate()
	
	# randomized position variables
	var rand_x = randf_range(-50.0, 50.0)
	var rand_y = randf_range(-5.0, 5.0)
	var rand_z = randf_range(-50.0, 50.0)
	
	alien.position = Vector3(rand_x, rand_y, rand_z)
	get_tree().current_scene.add_child(alien)

func _on_spawn_rock_timer_timeout() -> void:
	spawn_rock()

func _on_spawn_alien_timer_timeout() -> void:
	spawn_alien()
