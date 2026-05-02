extends CharacterBody2D

@export var movement_speed: float = 40.0
@export var step_interval: float = 15.0 # Distance between "jumps" or sounds

@onready var info_label : Label = $InfoLabel
@onready var sound_listener: Area2D = $SoundListener
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var event_history: Array[String] = []
const MAX_EVENTS: int = 4

# Bresenham-like movement variables
var error: Vector2 = Vector2.ZERO
var distance_walked: float = 0.0

func _physics_process(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		return

	# 1. Get direction from NavigationAgent
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var dir: Vector2 = global_position.direction_to(next_path_position)
	
	# 2. Calculate desired velocity
	var vel: Vector2 = dir * movement_speed
	var motion: Vector2 = vel * delta

	# 3. Accumulate fractional movement (Bresenham logic)
	error += motion

	# 4. Extract integer steps
	var step := Vector2(
		int(error.x),
		int(error.y)
	)

	# 5. Keep the remainder
	error -= step

	# 6. Apply discrete movement
	if step != Vector2.ZERO:
		_move_pixelwise(step)
		
		# Track distance for sounds/animations
		distance_walked += step.length()
		if distance_walked > step_interval:
			play_slime_jump_sound()
			distance_walked = 0.0

func _move_pixelwise(step: Vector2) -> void:
	var steps := int(max(abs(step.x), abs(step.y)))

	if steps == 0:
		return

	var step_dir := Vector2(
		sign(step.x),
		sign(step.y)
	)

	var remaining := step.abs()

	# Distribute steps evenly (Bresenham-style)
	var err := 0.0
	var dx := remaining.x
	var dy := remaining.y

	if dx > dy:
		var slope := dy / dx if dx != 0 else 0.0
		for i in dx:
			_move_and_collide_safe(Vector2(step_dir.x, 0))
			err += slope
			if err >= 1.0:
				_move_and_collide_safe(Vector2(0, step_dir.y))
				err -= 1.0
	else:
		var slope := dx / dy if dy != 0 else 0.0
		for i in dy:
			_move_and_collide_safe(Vector2(0, step_dir.y))
			err += slope
			if err >= 1.0:
				_move_and_collide_safe(Vector2(step_dir.x, 0))
				err -= 1.0


func _move_and_collide_safe(delta: Vector2) -> void:
	if delta == Vector2.ZERO:
		return
	
	var collision = move_and_collide(delta)
	if collision:
		# Stop movement along that axis if collision occurs
		# (simple behavior; can be expanded)
		pass

func set_movement_target(target_point: Vector2):
	navigation_agent.target_position = target_point

func play_slime_jump_sound():
	# Sound logic here
	pass

func _on_sound_listener_sound_heard(ray: SoundRay) -> void:
	set_movement_target(ray.origin)
	
	var dist = var_to_str(snappedf(ray.distance_acumulator, 0.1)).left(5)
	var intensity = var_to_str(snapped(ray.event.intensity, 0.01)).left(4)
	var source_name = ray.event.source_node.name
	
	var new_entry = "%s | Int: %s | Ref: %d | %s" % [dist, intensity, ray.reflection_count, source_name]
	
	event_history.push_front(new_entry)
	if event_history.size() > MAX_EVENTS:
		event_history.pop_back()
	
	info_label.text = "\n".join(event_history)
