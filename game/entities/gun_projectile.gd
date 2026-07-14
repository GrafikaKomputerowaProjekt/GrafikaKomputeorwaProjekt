extends Area2D

@export var speed := 250.0
@export var damage := 1

var direction := Vector2.RIGHT

func _physics_process(delta):
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
