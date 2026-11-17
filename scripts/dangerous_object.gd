extends Area3D

@export var fall_gravity := 11.0

func _physics_process(delta: float) -> void:
	position.y += fall_gravity
