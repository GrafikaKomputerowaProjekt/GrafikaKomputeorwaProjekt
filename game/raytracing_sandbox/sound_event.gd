extends RefCounted
class_name SoundEvent

static var id_counter: int = 0

var id

func _init() -> void:
	id = id_counter
	id_counter += 1
