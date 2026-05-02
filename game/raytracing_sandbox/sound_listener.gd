extends Area2D

## Handles sound detection and ray propagation.
## Filters multiple incoming signals to identify 
## the most relevant sound source in a given frame.

signal sound_heard(ray: SoundRay)

# Stores the best ray per event_id
# key: event_id | value: SoundRay
var frame_rays: Dictionary = {} 

func _process(_delta: float) -> void:
	flush_detected_sounds()

func flush_detected_sounds() -> void:
	for event_id in frame_rays:
		var best_ray = frame_rays[event_id]
		on_sound_detected(best_ray)
	frame_rays.clear()
	
func on_sound_detected(ray: SoundRay) -> void:
	sound_heard.emit(ray)

func on_ray_interaction(ray: SoundRay) -> void:
	ray_hit(ray)

func ray_hit(ray: SoundRay) -> void:
	var id = ray.event.id
	
	if not frame_rays.has(id) or ray.distance_acumulator < frame_rays[id].distance_acumulator:
		frame_rays[id] = ray
	pass
