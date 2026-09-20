extends CharacterBody2D

@export var max_health = 4
@export var charge_speed: float = 150.0
@onready var anim_player = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("Player")

var current_health = max_health
var state = "idle"
var charge_dir = Vector2.ZERO
var last_direction = "front"
var state_timer = 3.0

func _physics_process(delta):
	state_timer -= delta
	
	if state == "idle":
		velocity = Vector2.ZERO
		update_animation(false)
		if state_timer <= 0:
			start_telegraph()
			
	elif state == "telegraph":
		modulate = Color(1, 0, 0) if int(state_timer * 10) % 2 == 0 else Color(1, 1, 1)
		if state_timer <= 0:
			start_charge()
			
	elif state == "charge":
		velocity = charge_dir * charge_speed
		update_animation(true)
		var collision = move_and_collide(velocity * delta)
		
		if collision:
			handle_impact(collision.get_collider())
		elif state_timer <= 0:
			state = "idle"
			state_timer = 2.0
			anim_player.speed_scale = 1.0
			
			
			
func start_telegraph():
	state = "telegraph"
	state_timer = 1.5
	velocity = Vector2.ZERO
	if player:
		charge_dir = global_position.direction_to(player.global_position).normalized()
		update_facing_direction(charge_dir)

func start_charge():
	state = "charge"
	state_timer = 2.0
	modulate = Color(1, 1, 1)
	anim_player.speed_scale = 3.0

func handle_impact(collider):
	state = "idle"
	state_timer = 2.0
	anim_player.speed_scale = 1.0
	
	if collider.has_method("break_pillar"):
		if collider.break_pillar():
			take_damage()

func take_damage():
	current_health -= 1
	
	var health_bar = get_tree().get_first_node_in_group("boss_health")
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0:
		queue_free()

func update_facing_direction(dir):
	if abs(dir.x) > abs(dir.y):
		last_direction = "left" if dir.x < 0 else "right"
	else:
		last_direction = "back" if dir.y < 0 else "front"

func update_animation(is_walking):
	var anim_name = "walk_" + last_direction if is_walking else "stand_" + last_direction
	anim_player.play(anim_name)
