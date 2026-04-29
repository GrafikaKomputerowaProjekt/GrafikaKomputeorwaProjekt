extends StaticBody2D

## Handles sound detection and ray propagation.
## Filters multiple incoming signals to identify 
## the most relevant sound source in a given frame.

signal sound_heard(ray: SoundRay)

@export var soundManagerPath : NodePath
@onready var soundManager = get_node(soundManagerPath)

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
	var id = ray.event.id
	
	if not frame_rays.has(id) or ray.distance_acumulator < frame_rays[id].distance_acumulator:
		frame_rays[id] = ray
	propagate_ray(ray)
	
func propagate_ray(ray: SoundRay) -> void:
	var hit_pos: Vector2 = ray.hit_position
	
	# Pass the ray through
	var ray_dir: Vector2 = (hit_pos - ray.origin).normalized()
	
	# Prepare the next RayQuery
	var target_pos: Vector2 = hit_pos + ray_dir * 368.0
	var query = PhysicsRayQueryParameters2D.create(hit_pos, target_pos)
	query.exclude = [self.get_rid()]
	
	# Cast the ray to get the intersection
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(query)
	if not result.is_empty():
		var next_ray = SoundRay.create_reflection(ray)
		var distance = (ray.origin - result["position"]).length()
		next_ray.update_hit_data(result, distance)
		
		soundManager.new_ray(next_ray)
		var target_node = result["collider"]
		if target_node.has_method("on_ray_interaction"):
			target_node.on_ray_interaction(next_ray)
			
