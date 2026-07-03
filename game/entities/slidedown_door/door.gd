extends Node2D
@export var openable_player: bool = true
@export var door_id: String = ""

@onready var door_closed_sprites = $Door_closed_sprites
@onready var solid_collision = $StaticBody2D/CollisionShape2D
var is_open = false
var player_in_range = false

func _process(delta):
	if openable_player and player_in_range and Input.is_action_just_pressed("interact"):
		toggle_door()
		
func toggle_door():
	is_open = !is_open
	if is_open:
		door_closed_sprites.visible = false
		solid_collision.set_deferred("disabled", true)
	else:
		door_closed_sprites.visible = true
		solid_collision.set_deferred("disabled", false)
		
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		
func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
