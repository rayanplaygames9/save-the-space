extends Node3D

## constant scenes
const ROCK = preload("uid://cnrrhibhfrfxq")
const ALIEN = preload("uid://b242ndeq5lfjs")

## constant variables
const TOTAL_ROCKS := 100
const MAX_ALIENS := 2

## variables
var can_spawn_alien := true
var rocks: Array = []
var aliens: Array = []
var player: Player

func _ready() -> void:
	player = get_tree().current_scene.get_node("Player")

	for i in range(TOTAL_ROCKS):
		var rock = ROCK.instantiate()
		rock.visible = false
		add_child(rock)

		rock.get_node("HitboxComponent/CollisionShape3D").disabled = true
		rock.get_node("CollisionShape3D").disabled = true

		# Add each pre-instantiated rock into the array pool
		rocks.append(rock)

	for i in range(MAX_ALIENS):
		var alien = ALIEN.instantiate()
		alien.visible = false
		alien.set_physics_process(false)
		alien.set_process(false)
		alien.disabled = true

		add_child(alien)

		alien.get_node("CollisionShape3D").disabled = true
		alien.get_node("HitboxComponent/CollisionShape3D").disabled = true

		aliens.append(alien)

func _process(_delta: float) -> void:
	for alien in aliens:
		if alien:
			if alien.placed_rocks == 8:
				player.get_node("UI/DangerRainLabel").show()
				$DangerSFX.play()
				await get_tree().create_timer(3.0).timeout
				$DangerSFX.stop()
				player.get_node("UI/DangerRainLabel").hide()

func spawn_rock():
	var spawned := false

	# Loop through the pool to find an available (hidden) rock
	for rock in rocks:
		if not rock.visible:
			rock.visible = true
			rock.get_node("SelfSFX").play()

			# Re-enable collision if its disabled it on death
			rock.get_node("HitboxComponent/CollisionShape3D").disabled = false
			rock.get_node_or_null("CollisionShape3D").disabled = false

			# Reset health if needed via health component reference
			var health_component: HealthComponent = rock.get_node_or_null("HealthComponent")
			if health_component: health_component.health = health_component.MAX_HEALTH

			# Randomized position variables
			var rand_x := randf_range(-50.0, 50.0)
			var rand_y := randf_range(-20.0, 20.0)
			var rand_z := randf_range(-50.0, 50.0)

			rock.position = Vector3(rand_x, rand_y, rand_z)

			spawned = true
			break # Found one, stop searching!

	# If all 100 rocks are currently visible, 'spawned' stays false and nothing happens
	if not spawned:
		print("Max rocks reached (100). Cannot spawn any more.")

func spawn_alien():
	var spawned := false
	
	for alien in aliens:
		if not alien.visible:
			alien.visible = true
			alien.get_node("ArrivalSFX").play()

			# Re-enable collision if its disabled it on death
			alien.get_node("HitboxComponent/CollisionShape3D").disabled = false
			alien.get_node_or_null("CollisionShape3D").disabled = false

			alien.set_physics_process(true)
			alien.set_process(true)

			alien.disabled = false

			# Reset health if needed via health component reference
			var health_component: HealthComponent = alien.get_node_or_null("HealthComponent")
			if health_component: health_component.health = health_component.MAX_HEALTH

			# randomized position variables
			var rand_x = randf_range(-50.0, 50.0)
			var rand_y = randf_range(-5.0, 5.0)
			var rand_z = randf_range(-50.0, 50.0)

			alien.position = Vector3(rand_x, rand_y, rand_z)

			alien.get_node("StartMoveTimer").start()

			spawned = true
			break # Found one, stop searching!

	# If all 100 rocks are currently visible, 'spawned' stays false and nothing happens
	if not spawned:
		print("Max aliens reached (2). Cannot spawn any more.")

func _on_spawn_rock_timer_timeout() -> void:
	spawn_rock()

func _on_spawn_alien_timer_timeout() -> void:
	spawn_alien()
