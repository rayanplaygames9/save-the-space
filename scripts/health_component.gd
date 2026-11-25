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
	
func damage(attack: Attack):
	if not multiplayer.is_server():
		return
	health -= attack.attack_damage

	if health <= 0.0:
		die_or_respawn()
			
func die_or_respawn():
	var parent := get_parent()
	if parent is Player:
		health = MAX_HEALTH
		var player: Player = parent
		player.respawn.rpc_id(parent.get_multiplayer_authority(), Vector3.ZERO)
	else:
		parent.queue_free()
