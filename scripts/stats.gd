extends Resource
class_name Stats

@export var MAX_LEVEL: float = 10.0
@export var level: float = 0.0:
	set(value):
		level = clamp(value, 0.0, MAX_LEVEL)
