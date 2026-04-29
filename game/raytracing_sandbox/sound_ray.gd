extends RefCounted
class_name SoundRay

## Data container for sound propagation segments.
## Tracks distance, origin, and event metadata across multiple bounces.

var event: SoundEvent
var origin: Vector2
var distance_acumulator: float = 0.0

var reflection_count: int = 0
var hit_position: Vector2
var hit_normal: Vector2
var hit_collider: Object

func _init(p_origin: Vector2, p_event: SoundEvent) -> void:
	origin = p_origin
	event = p_event

## Factory method to create a new ray segment based on an existing one.
## Ensures continuity of the distance accumulator and event metadata.
static func create_reflection(old_ray: SoundRay) -> SoundRay:
	var ray = SoundRay.new(old_ray.hit_position, old_ray.event)
	ray.reflection_count = old_ray.reflection_count
	ray.distance_acumulator = old_ray.distance_acumulator
	return ray

## Updates the ray state with new collision data and increments the total distance.
func update_hit_data(result: Dictionary, distance: float) -> void:
	if result.is_empty():
		return
	distance_acumulator += distance
	hit_position = result["position"]
	hit_normal = result["normal"]
	hit_collider = result["collider"]
