extends Node2D

var collision_points: Array[Dictionary] = []
const SPEED: float = 120.0

func _ready() -> void:
	collision_points.resize(100)

func get_input() -> Vector2:
	var x_input = Input.get_axis("move_left", "move_right")
	var y_input = Input.get_axis("move_up", "move_down")
	return Vector2(x_input, y_input)

func _physics_process(delta):
	# ---- Character movement -----
	var direction: Vector2 = get_input()
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		position += direction * SPEED * delta
	
	# ---- Sound ray casting ----
	collision_points.clear()
	var space_state = get_world_2d().direct_space_state
	const ray = Vector2(300, 0)
	for i in range(180):
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + ray.rotated(deg_to_rad(2*i)))
		var result = space_state.intersect_ray(query)
		collision_points.push_back(result)
		if result.is_empty():
			continue
		var test_ray = TestRay.new(position, 100)
		test_ray.update_hit_data(result)
		if result.get("collider").has_method("reflect_sound"):
			result.get("collider").call("reflect_sound", test_ray)
	queue_redraw()
	
func _draw() -> void:
	for point in collision_points:
		if (point):
			draw_line(Vector2(0,0), point.get("position") - position, Color.ANTIQUE_WHITE, 2.0)
