extends Node3D
class_name HealthComponent

signal health_changed(new_health: float)

@export var MAX_HEALTH: float = 50.0
@export var health: float = 0.0:
	set(value):
		health = value
		health_changed.emit(health)

@onready var hitbox_component: HitboxComponent = $"../HitboxComponent"

func _ready() -> void:
	health = MAX_HEALTH

func damage(attack: Attack) -> void:
	if not multiplayer.is_server():
		return
	var new_health := health - attack.attack_damage
	if new_health <= 0.0:
		_die() # 0 health = dead
	else:
		_set_health.rpc(new_health) # damaged

func _die() -> void:
	var parent := get_parent()
	if parent is Player:
		_set_health.rpc(MAX_HEALTH) # respawn
		parent.respawn.rpc_id(parent.get_multiplayer_authority(), Vector3.ZERO)
	else:
		parent.queue_free()

@rpc("any_peer", "call_local", "reliable")
func _set_health(value: float) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return  # only the server (or a local call) may set health
	health = clampf(value, 0.0, MAX_HEALTH)
	health_changed.emit(health)
