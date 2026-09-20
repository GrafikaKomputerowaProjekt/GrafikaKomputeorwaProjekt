extends CharacterBody2D

@export var max_health = 4
@export var charge_speed: float = 150.0
@export var walk_speed: float = 40.0
@export var activation_distance: float = 200.0
@export var charge_distance: float = 120.0
@export var blood_scene: PackedScene

@onready var anim_player = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var charge_particles = $CPUParticles2D

var current_health = max_health
var state = "inactive"
var charge_dir = Vector2.ZERO
var last_direction = "front"
var state_timer = 0.0

func _physics_process(delta):
	state_timer -= delta
	
	if not player:
		return
		
	var dist_to_player = global_position.distance_to(player.global_position)
	
	if state == "inactive":
		velocity = Vector2.ZERO
		update_animation(false)
		if dist_to_player <= activation_distance:
			state = "chase"
			state_timer = 1.0
			
	elif state == "chase":
		var dir = global_position.direction_to(player.global_position).normalized()
		velocity = dir * walk_speed
		update_facing_direction(dir)
		update_animation(true)
		move_and_slide()
		
		if dist_to_player <= charge_distance and state_timer <= 0:
			start_telegraph()
			
	elif state == "telegraph":
		modulate = Color(1, 0, 0) if int(state_timer * 10) % 2 == 0 else Color(1, 1, 1)
		
		charge_dir = global_position.direction_to(player.global_position).normalized()
		update_facing_direction(charge_dir)
		update_animation(false)
		
		if state_timer <= 0:
			start_charge()
			
	elif state == "charge":
		velocity = charge_dir * charge_speed
		update_animation(true)
		var collision = move_and_collide(velocity * delta)
		
		if collision:
			var col_node = collision.get_collider()
			if col_node and col_node.is_in_group("Player") and col_node.has_method("take_damage"):
				col_node.take_damage()
			handle_impact(col_node)
		elif state_timer <= 0:
			state = "chase"
			state_timer = 1.0
			anim_player.speed_scale = 1.0
			charge_particles.emitting = false
			
	elif state == "stun":
		velocity = Vector2.ZERO
		update_animation(false)
		if state_timer <= 0:
			state = "chase"
			state_timer = 1.0

func start_telegraph():
	state = "telegraph"
	state_timer = 1.5
	velocity = Vector2.ZERO

func start_charge():
	state = "charge"
	state_timer = 2.0
	modulate = Color(1, 1, 1)
	anim_player.speed_scale = 3.0
	charge_particles.emitting = true

func handle_impact(collider):
	state = "stun"
	state_timer = 2.0
	anim_player.speed_scale = 1.0
	charge_particles.emitting = false
	
	if collider and collider.has_method("break_pillar"):
		if collider.break_pillar():
			take_damage()

func take_damage():
	current_health -= 1
	
	var health_bar = get_tree().get_first_node_in_group("boss_health")
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0:
		var doors = get_tree().get_nodes_in_group("Doors")
		for door in doors:
			if door.has_method("open_door"):
				door.open_door()
				
		GameManager.is_power_on = true
		
		if blood_scene:
			var blood = blood_scene.instantiate()
			get_parent().add_child(blood)
			blood.global_position = global_position
			
		queue_free()

func update_facing_direction(dir):
	if abs(dir.x) > abs(dir.y):
		last_direction = "left" if dir.x < 0 else "right"
	else:
		last_direction = "back" if dir.y < 0 else "front"

func update_animation(is_walking):
	var anim_name = "walk_" + last_direction if is_walking else "stand_" + last_direction
	anim_player.play(anim_name)
