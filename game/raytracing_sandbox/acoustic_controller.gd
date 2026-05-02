extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_sound_listener_sound_heard(ray: SoundRay) -> void:
	var source = ray.event.source_node
	pass # Replace with function body.
