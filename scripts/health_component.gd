extends Node3D
class_name HealthComponent

@export var MAX_HEALTH: float = 50.0
var health: float

@onready var hitbox_component: HitboxComponent = $"../HitboxComponent"

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
		# Instead of destroying it, hide it and disable it for the pool!
		get_parent().visible = false
		get_parent().set_physics_process(false)
		get_parent().set_process(false)
		
		# If your rock has a CollisionShape3D or Area3D/RigidBody3D, 
		# make sure to disable its collision so the player can't hit an invisible rock:
		hitbox_component.get_node("CollisionShape3D").disabled = true
		get_parent().get_node_or_null("CollisionShape3D").disabled = true
		
