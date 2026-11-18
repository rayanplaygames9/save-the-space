extends Area3D
class_name HitboxComponent

@export var health_component: HealthComponent

func damage(attack: Attack):
	if health_component:
		health_component.damage(attack)

func get_health_component() -> HealthComponent:
	if health_component:
		return health_component
	return get_node_or_null("../HealthComponent") as HealthComponent
