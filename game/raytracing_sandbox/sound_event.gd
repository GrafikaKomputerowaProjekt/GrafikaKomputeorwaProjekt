extends RefCounted
class_name SoundEvent

var source_node: Node2D
static var id_counter: int = 0
var intensity: float = 1
var id

func _init(source : Node2D, p_intensity : float) -> void:
	source_node = source
	id = id_counter
	id_counter += 1
	intensity = p_intensity
