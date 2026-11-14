extends Node3D
class_name HealthComponent

@export var MAX_HEALTH: float = 50.0
var health: float

func _ready() -> void:
	health = MAX_HEALTH
	
func damage(attack: Attack):
	health -= attack.attack_damage
	
	if health <= 0.0:
		respawn()
			
func respawn():
	if get_parent() is Player:
		get_tree().reload_current_scene()
	else:
		get_parent().queue_free()
