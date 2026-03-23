extends CharacterBody2D

@export var SPEED: float = 50

func _physics_process(_delta: float) -> void:
	var x_input := Input.get_axis("move_left", "move_right")
	var y_input := Input.get_axis("move_up", "move_down")
	
	velocity.x = x_input * SPEED
	velocity.y = y_input * SPEED
	
	move_and_slide()
