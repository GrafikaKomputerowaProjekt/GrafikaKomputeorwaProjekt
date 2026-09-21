extends Area2D

@export var speed := 250.0
@export var damage := 1

var direction := Vector2.RIGHT

func _ready():
	# Automatyczne podłączenie obu sygnałów dla pewności
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(delta):
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area):
	print("[PROJECTILE] Area collision detected with: ", area.name, " | Layer: ", area.collision_layer)
	_handle_hit(area)

func _on_body_entered(body):
	print("[PROJECTILE] Body collision detected with: ", body.name, " | Layer: ", body.collision_layer)
	_handle_hit(body)

func _handle_hit(target):
	if target.is_in_group("Player"):
		print("[PROJECTILE] Hit player, ignoring!")
		return
		
	if target.has_method("hit_by_projectile"):
		print("[PROJECTILE] Hit target! Calling hit_by_projectile.")
		target.hit_by_projectile(damage)
	elif target.has_method("take_damage"):
		print("[PROJECTILE] Hit target, calling take_damage.")
		target.take_damage(damage)
	else:
		print("[PROJECTILE] Hit something without damage methods: ", target.name)

	queue_free()
