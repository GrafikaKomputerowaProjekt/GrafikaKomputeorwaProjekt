extends CharacterBody2D

@export var speed = 50.0
@onready var anim_player = $AnimationPlayer

var direction = Vector2.ZERO
var last_direction = "front"
var is_walking = false

func _physics_process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		is_walking = true
		velocity = direction * speed
		update_facing_direction()
	else:
		is_walking = false
		velocity = Vector2.ZERO

	update_animation()
	move_and_slide()

func update_facing_direction():
	if abs(direction.x) > abs(direction.y):
		if direction.x < 0:
			last_direction = "left"
		else:
			last_direction = "right"
	else:
		if direction.y < 0:
			last_direction = "back"
		else:
			last_direction = "front"

func update_animation():
	var anim_name = ""
	if is_walking:
		anim_name = "walk_" + last_direction
	else:
		anim_name = "stand_" + last_direction
	
	anim_player.play(anim_name)
