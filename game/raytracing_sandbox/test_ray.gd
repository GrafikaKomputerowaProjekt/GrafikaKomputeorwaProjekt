extends RefCounted
class_name TestRay

var origin: Vector2
var intensity: float
var reflection_count: int = 0

var hit_position: Vector2
var hit_normal: Vector2
var hit_collider: Object

func _init(p_origin: Vector2, p_intensity: float) -> void:
	origin = p_origin
	intensity = p_intensity

# POPRAWKA: Metoda statyczna musi pobrać hit_position starego promienia 
# i uczynić go nowym originem.
static func create_reflection(old_ray: TestRay) -> TestRay:
	# Nowy promień startuje tam, gdzie stary uderzył!
	var ray = TestRay.new(old_ray.hit_position, old_ray.intensity)
	
	# Przenosimy licznik odbić
	ray.reflection_count = old_ray.reflection_count
	return ray

func update_hit_data(result: Dictionary) -> void:
	if result.is_empty():
		return
		
	hit_position = result["position"]
	hit_normal = result["normal"]
	hit_collider = result["collider"]
