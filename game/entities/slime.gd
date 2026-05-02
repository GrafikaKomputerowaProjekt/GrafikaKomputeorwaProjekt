extends CharacterBody2D

@export var movement_speed: float = 40.0
@export var step_interval: float = 15.0 # Distance between "jumps" or sounds

@onready var info_label : Label = $InfoLabel
@onready var sound_listener: Area2D = $SoundListener
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var player: Node2D
@export var view_distance: float = 100.0
@export var view_angle: float = 60.0

@export var patrol_points: Array[Node2D] = []
@export var patrol_wait_time: float = 1.0

@export var forget_player_time: float = 2.0


var event_history: Array[String] = []
const MAX_EVENTS: int = 4

# Bresenham-like movement variables
var error: Vector2 = Vector2.ZERO
var distance_walked: float = 0.0

var last_look_dir: Vector2 = Vector2.DOWN
var chasing_player: bool = false

var patrol_index: int = 0
var patrol_wait_timer: float = 0.0

var forget_player_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if can_see_player():
		chasing_player = true
		forget_player_timer = 0.0
	else:
		if chasing_player:
			forget_player_timer += delta

			if forget_player_timer >= forget_player_time:
				chasing_player = false
				forget_player_timer = 0.0
				
				if patrol_points.size() > 0:
					set_movement_target(patrol_points[patrol_index].global_position)

	if chasing_player and player != null:
		set_movement_target(player.global_position)
	else:
		handle_patrol(delta)
		
	if navigation_agent.is_navigation_finished():
		return
	
	# 1. Get direction from NavigationAgent
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var dir: Vector2 = global_position.direction_to(next_path_position)
	
	if dir != Vector2.ZERO:
		last_look_dir = dir.normalized()
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


func can_see_player() -> bool:
	if player == null: 
		return false
	var to_player: Vector2 =player.global_position -global_position
	var distance:= to_player.length()
		
	if distance > view_distance:
		return false
		
	var direction_to_player := to_player.normalized()
	var angle_to_player := rad_to_deg(last_look_dir.angle_to(direction_to_player))

	if abs(angle_to_player) > view_angle / 2.0:
		return false
		
	var space_state := get_world_2d().direct_space_state
	
	var query :=PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)
	query.exclude = [self]

	var result :=space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	
	return result.collider == player
		
		
func _ready() -> void:
	if patrol_points.size() > 0:
		set_movement_target(patrol_points[patrol_index].global_position)
		
		
func handle_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		return

	if navigation_agent.is_navigation_finished():
		patrol_wait_timer += delta

		if patrol_wait_timer >= patrol_wait_time:
			patrol_wait_timer = 0.0
			patrol_index += 1

			if patrol_index >= patrol_points.size():
				patrol_index = 0

			set_movement_target(patrol_points[patrol_index].global_position)
		
func is_hit() -> void:
	
	print ("HIT")
	set_physics_process(false)
	set_process(false)
	
	if has_node("Sprite2D"):
		$Sprite2D.visible =false
	queue_free()
	
#func _input(event):
#	if event.is_action_pressed("ui_accept"): #funkcja testująca czy hit działa 
#		is_hit()
	
