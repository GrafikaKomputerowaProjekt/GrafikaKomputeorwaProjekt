extends Node2D

@export var openable: bool = true

@onready var sprite = $Sprite2D
@onready var solid_collision = $StaticBody2D/CollisionShape2D

var is_open = false
var player_in_range = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	if player_in_range:
#		if Input.is_action_just_pressed("interact"):
#			toggle_door()	
#	pass

func toggle_door():
	is_open = !is_open
	if is_open:
		solid_collision.set_deferred("disabled", true)
		pass
	else:
		solid_collision.set_deferred("disabled", false)
		pass

func _on_area_entered(body):
		if body.is_in_group("Player"):
			player_in_range = true

func _on_area_exited(body):
		if body.is_in_group("Player"):
				player_in_range = false


func _process(delta):
	
	if openable and player_in_range and Input.is_action_just_pressed("interact"):
		print("The E key was pressed while in range!")
		toggle_door()

func _on_area_2d_body_entered(body):
	print("An object touched the door: ", body.name)
	if body.is_in_group("Player"):
		print("The door recognized the Player group!")
		player_in_range = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		print("The Player left the door area.")
		player_in_range = false
