extends StaticBody2D

@export var soundManagerPath : NodePath
@onready var soundManager = get_node(soundManagerPath)
const MAX_TRACE_HISTORY: int = 100
var trace_buffer: Array[Dictionary] = []

func reflect_sound(ray: TestRay) -> void:
	# implement a rolling window by removing the oldest segment when full
	if trace_buffer.size() >= MAX_TRACE_HISTORY:
		trace_buffer.remove_at(0)

	# capture the incoming path in local space for persistent rendering
	trace_buffer.append({
		"start": to_local(ray.origin),
		"end": to_local(ray.hit_position),
		"intensity": ray.intensity
	})
	queue_redraw()

	# preserve the current collision state for reflection calculations
	var current_origin: Vector2 = ray.origin
	var current_hit: Vector2 = ray.hit_position
	
	# terminate recursion if signal is too weak or bounce limit is met
	if ray.reflection_count >= 2:
		return

	# calculate direction vectors for the reflection formula
	var incident_dir: Vector2 = (current_hit - current_origin).normalized()
	var normal: Vector2 = ray.hit_normal
	
	# prevent calculation failure if the surface normal is invalid
	if normal.is_zero_approx():
		normal = -incident_dir
		
	# calculate the outgoing vector using the law of reflection
	var reflect_dir: Vector2 = (incident_dir - 2.0 * incident_dir.dot(normal) * normal).normalized()

	# prepare the physics query for the next segment
	var space_state = get_world_2d().direct_space_state
	
	var start_pos: Vector2 = current_hit
	var target_pos: Vector2 = start_pos + reflect_dir * 320.0

	var query = PhysicsRayQueryParameters2D.create(start_pos, target_pos)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	# pass the modified ray data to the next object in the collision path
	if not result.is_empty():
		var next_ray = TestRay.create_reflection(ray)
		next_ray.reflection_count += 1
		next_ray.update_hit_data(result)
		
		soundManager.new_ray(next_ray)
		var target_node = result["collider"]
		if target_node.has_method("reflect_sound"):
			target_node.reflect_sound(next_ray)

func _draw() -> void:
	# visualize the stored history with transparency mapped to signal strength
	for segment in trace_buffer:
		var alpha = clamp(segment.intensity / 100.0, 0.2, 1.0)
		var color = Color(Color.ANTIQUE_WHITE, alpha)
		
		draw_line(segment.start, segment.end, color, 1.0)
		draw_circle(segment.end, 2.0, Color(Color.CRIMSON, alpha))
