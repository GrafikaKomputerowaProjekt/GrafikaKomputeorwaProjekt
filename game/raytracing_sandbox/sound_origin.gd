extends Node2D

## Creates sound events and casts sound rays 

## Number of rays to cast per sound event. Higher values improve spatial accuracy.
@export_range(1, 360, 1) var rays_per_source: int = 72

@export var sound_manager_path : NodePath
@onready var sound_manager = get_node(sound_manager_path)

## Sound raycasting
func generate_sound() -> void:
	var sound: SoundEvent = SoundEvent.new()
	var space_state = get_world_2d().direct_space_state
	
	# Calculate the angle step in radians
	var angle_step = TAU / rays_per_source
	var sound_range: float = 368.0
	for i in range(rays_per_source):
		var ray_direction = Vector2.RIGHT.rotated(angle_step * i)
		var target_pos = global_position + (ray_direction * sound_range)
		
		# Configure the physics query
		var query = PhysicsRayQueryParameters2D.create(global_position, target_pos)
		# Execute the raycast
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			var new_ray = SoundRay.new(global_position, sound)
			var distance = (global_position - result["position"]).length()
			new_ray.update_hit_data(result, distance)
			sound_manager.new_ray(new_ray)
			var collider = new_ray.hit_collider 
			if collider.has_method("on_ray_interaction"):
				collider.on_ray_interaction(new_ray)
