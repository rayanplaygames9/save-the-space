extends Area3D

@export var fall_gravity := -11.0

var attack_damage := 10.0

func _physics_process(delta: float) -> void:
	position.y += fall_gravity * delta

func _on_area_entered(area: Area3D) -> void:
	if area is HitboxComponent and area.get_parent() is Player:
		var hitbox: HitboxComponent = area
		
		var attack = Attack.new()
		attack.attack_damage = attack_damage
		attack.attack_position = global_position
		
		hitbox.damage(attack)
		
