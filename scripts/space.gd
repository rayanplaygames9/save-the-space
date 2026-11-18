extends Node3D

## constant scenes
const ROCK = preload("uid://cnrrhibhfrfxq")
const ALIEN = preload("uid://b242ndeq5lfjs")

## constant variables
const TOTAL_ROCKS := 100
const MAX_ALIENS := 2

## variables
var can_spawn_alien := true
var alien_count := 0
var rocks: Array = []
var aliens: Array = []

func _ready() -> void:
	for i in range(TOTAL_ROCKS):
		var rock = ROCK.instantiate()
		rock.visible = false
		get_tree().current_scene.add_child(rock)
		
		rock.get_node("HitboxComponent/CollisionShape3D").disabled = true
		rock.get_node("CollisionShape3D").disabled = true
		
		# Add each pre-instantiated rock into your array pool
		rocks.append(rock)
		
	for i in range(MAX_ALIENS):
		var alien = ALIEN.instantiate()
		alien.visible = false
		alien.set_physics_process(false)
		alien.set_process(false)
		alien.disabled = true
		
		get_tree().current_scene.add_child(alien)
		
		alien.get_node("CollisionShape3D").disabled = true
		alien.get_node("HitboxComponent/CollisionShape3D").disabled = true
		
		aliens.append(alien)

func spawn_rock():
	var spawned := false
	
	# Loop through the pool to find an available (hidden) rock
	for rock in rocks:
		if not rock.visible:
			rock.visible = true
			
			# Re-enable collision if you disabled it on death
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
			
			# Re-enable collision if you disabled it on death
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
