extends Node2D

## Manages debug visualization for sound rays.
## Uses a Time-To-Live (TTL) buffer to fade out old ray segments.

@export var debug_draw: bool = true
@export var ray_lifetime: float = 0.05 # Duration in seconds before a ray disappears

## Stores ray segments: { "start": Vector2, "end": Vector2, "time_left": float }
var trace_buffer: Array[Dictionary] = []

## Adds a new ray segment to the visualization buffer.
func new_ray(ray: SoundRay) -> void:
	if not debug_draw:
		return
		
	trace_buffer.append({
		"start": to_local(ray.origin),
		"end": to_local(ray.hit_position),
		"time_left": ray_lifetime
	})
	queue_redraw()

func _physics_process(delta: float) -> void:
	if trace_buffer.is_empty():
		return

	# Iterate backwards to safely remove expired elements while decrementing TTL
	var i = trace_buffer.size() - 1
	while i >= 0:
		trace_buffer[i].time_left -= delta
		if trace_buffer[i].time_left <= 0:
			trace_buffer.remove_at(i)
		i -= 1
	
	queue_redraw()

func _draw() -> void:
	if not debug_draw or trace_buffer.is_empty():
		return
		
	for segment in trace_buffer:
		# Map remaining life to alpha for a smooth fade-out effect
		var alpha = (segment.time_left / ray_lifetime) * 0.2
		var color = Color(Color.ANTIQUE_WHITE, alpha)
		
		draw_line(segment.start, segment.end, color, 0.5, true)
		draw_circle(segment.end, 1.0, Color(Color.CRIMSON, alpha * 5.0))
