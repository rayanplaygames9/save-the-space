extends Area3D

@export var fall_gravity := -11.0
@export var attack_damage := 10.0

func _physics_process(delta: float) -> void:
	position.y += fall_gravity * delta

func _on_area_entered(area: Area3D) -> void:
	if not multiplayer.is_server(): return

	if area is HitboxComponent and area.get_parent() is Player:
		print("[dangerous object] hit =", get_parent().name)
		var hitbox: HitboxComponent = area
		
		var attack = Attack.new()
		attack.attack_damage = attack_damage
		attack.attack_position = global_position
		
		hitbox.damage(attack)
		
