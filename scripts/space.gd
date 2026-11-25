extends Node3D

## constant scenes
const ROCK = preload("uid://cnrrhibhfrfxq")
const ALIEN = preload("uid://b242ndeq5lfjs")

## constant variables
const MAX_ALIENS := 2
const MAX_ROCKS := 100

## variables
var can_spawn_alien := true
var rocks: Array = []
var aliens: Array = []
var player: Player

## export variables
@export var player_scene: PackedScene

## onready variables
@onready var players_container: Node3D = $Players
@onready var rocks_container: Node3D = $Rocks
@onready var backto_menu_btn: Button = %BacktoMenuBtn

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player(1)
	else:
		_client_loaded.rpc_id(1) # tell the host "I'm ready"

	player = Network.get_local_player()
	
	backto_menu_btn.pressed.connect(func():
		print("Back to menu!")
		Network.leave_game()
	)
	
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_options"):
		$UI.visible = not $UI.visible
		if $UI.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	for alien in aliens:
		if alien:
			if alien.placed_rocks == 8:
				player = Network.get_local_player()
				player.get_node("UI/DangerRainLabel").show()
				$DangerSFX.play()
				await get_tree().create_timer(3.0).timeout
				$DangerSFX.stop()
				player.get_node("UI/DangerRainLabel").hide()

func spawn_rock() -> void:
	if not multiplayer.is_server():
		return  # only the host spawns; clients receive them automatically

	if rocks_container.get_child_count() >= MAX_ROCKS:
		print("Max rocks reached (%d). Cannot spawn any more." % MAX_ROCKS)
		return

	var rock := ROCK.instantiate() as NormalRock
	rock.position = Vector3(
		randf_range(-50.0, 50.0),
		randf_range(-20.0, 20.0),
		randf_range(-50.0, 50.0)
	)
	rocks_container.add_child(rock, true)

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

@rpc("any_peer", "reliable")
func _client_loaded() -> void:
	if multiplayer.is_server():
		_add_player(multiplayer.get_remote_sender_id())

func _add_player(id: int) -> void:
	var p := player_scene.instantiate()
	p.name = str(id)  # the name is the owner's peer id
	players_container.add_child(p, true)

func _remove_player(id: int) -> void:
	var p := players_container.get_node(str(id))
	if p:
		p.queue_free()
