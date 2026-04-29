extends Area2D

## Recieves and reflects sound rays

@export var sound_manager_path : NodePath
@onready var sound_manager = get_node(sound_manager_path)

func on_ray_interaction(ray: SoundRay) -> void:
	# preserve the current collision state for reflection calculations
	var current_origin: Vector2 = ray.origin
	var current_hit: Vector2 = ray.hit_position
	 
	# terminate recursion if bounce limit is met
	if ray.reflection_count >= 1:
		return

	# Calculate direction vectors for the reflection formula
	var incident_dir: Vector2 = (current_hit - current_origin).normalized()
	var normal: Vector2 = ray.hit_normal
	
	# Prevent calculation failure if the surface normal is invalid
	if normal.is_zero_approx():
		normal = -incident_dir
		
	# Calculate the outgoing vector using the law of reflection
	# In vector form:
	# reflection = incident - 2 * (incident ⋅ normal) * normal
	var reflect_dir: Vector2 = (incident_dir - 2.0 * incident_dir.dot(normal) * normal).normalized()

	# Prepare the physics query for the next segment
	var start_pos: Vector2 = current_hit
	var target_pos: Vector2 = start_pos + reflect_dir * 368.0

	var query = PhysicsRayQueryParameters2D.create(start_pos, target_pos)
	query.exclude = [self.get_rid()]
	
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	# Pass the modified ray data to the next object in the collision path
	if not result.is_empty():
		var next_ray = SoundRay.create_reflection(ray)
		next_ray.reflection_count += 1
		var distance = (ray.origin - result["position"]).length()
		next_ray.update_hit_data(result, distance)
		
		sound_manager.new_ray(next_ray)
		var target_node = result["collider"]
		if target_node.has_method("on_ray_interaction"):
			target_node.on_ray_interaction(next_ray)
