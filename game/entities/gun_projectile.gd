extends Area2D

@export var speed := 250.0
@export var damage := 1

var direction := Vector2.RIGHT

func _physics_process(delta):
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body):
	print("[PROJECTILE] Collision detected with: ", body.name, " | Layer: ", body.collision_layer)
	
	if body.is_in_group("Player"):
		print("[PROJECTILE] Hit player, ignoring!")
		return
		
	if body.has_method("hit_by_projectile"):
		print("[PROJECTILE] Hit enemy! Calling hit_by_projectile.")
		body.hit_by_projectile(damage)
	elif body.has_method("take_damage"):
		print("[PROJECTILE] Hit target, calling take_damage.")
		body.take_damage(damage)
	else:
		print("[PROJECTILE] Hit something without damage methods: ", body.name)

	queue_free()

	# Pocisk ulega zniszczeniu po trafieniu w cokolwiek (ścianę lub wroga)
	queue_free()
