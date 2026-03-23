extends CharacterBody2D

@export var speed: float = 86.0

var error := Vector2.ZERO  # accumulator

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var direction_map := {
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.UP: "up",
	Vector2i.DOWN: "down",
	Vector2i(1, 1): "down_right",
	Vector2i(-1, 1): "down_left",
	Vector2i(1, -1): "up_right",
	Vector2i(-1, -1): "up_left"
}

func update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return # idle state

	var grid_dir = Vector2i(
		roundi(input_dir.normalized().x),
		roundi(input_dir.normalized().y)
	)

	if direction_map.has(grid_dir):
		var anim_name = direction_map[grid_dir]
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			
func get_input() -> Vector2:
	var x_input = Input.get_axis("move_left", "move_right")
	var y_input = Input.get_axis("move_up", "move_down")
	return Vector2(x_input, y_input)


func _physics_process(delta: float) -> void:
	var vel: Vector2 = get_input().normalized() * speed
	update_animation(get_input()) # Aktualizacja animacji
	# Convert velocity (px/sec) into movement this frame
	var motion: Vector2 = vel * delta

	# Accumulate fractional movement
	error += motion

	# Extract integer steps (this is the Bresenham-like part)
	var step := Vector2(
		int(error.x),
		int(error.y)
	)

	# Remove used movement, keep remainder
	error -= step

	# Move in discrete pixel steps (important for collisions)
	_move_pixelwise(step)


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
