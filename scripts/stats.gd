extends Resource
class_name Stats

@export var MAX_LEVEL: float = 50.0
@export var level: float = 0.0:
	set(value):
		level = clamp(value, 0.0, MAX_LEVEL)

const SAVE_PATH := "user://player_stats.tres"

func save() -> void:
	ResourceSaver.save(self, SAVE_PATH)

static func load_stats() -> Stats:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded_stats = ResourceLoader.load(SAVE_PATH) as Stats
		if loaded_stats:
			return loaded_stats
	
	# Fallback: if no save exists, return a fresh default Stats object
	return Stats.new()
