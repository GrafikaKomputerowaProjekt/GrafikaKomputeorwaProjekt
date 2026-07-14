extends CharacterBody2D


@export var walk_speed: float = 86.0
@export var run_speed: float = 116.0
var speed: float = walk_speed
var error := Vector2.ZERO  # accumulator

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sounds_source: Node2D = $SoundSource
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer
@onready var projectile_spawn = $ProjectileSpawn
@onready var attack_hitbox: Area2D = $AttackHitbox

@export var projectile_scene : PackedScene
@export var sound_manager: NodePath
@export var walk_sounds: Array[AudioStream] = []
@export var run_sounds: Array[AudioStream] = []
@export_range(0.0, 1.0) var walk_loudness: float = 0.5
@export_range(0.0, 1.0) var run_loudness: float = 0.5

@export var step_interval: float = 0.4
var distance_walked: float = 0.0

@onready var walk_particles: GPUParticles2D = $WalkParticles

# Audio bus assigned to the player
var my_bus_name : String

# Player state-machine states
enum PlayerState {
	MOVE,
	CHARGE_ATTACK,
	ATTACKING
}

var state: PlayerState = PlayerState.MOVE

enum WeaponType {
	HAMMER,
	GUN
}

@export var current_weapon := WeaponType.HAMMER

var facing_direction := Vector2.DOWN
var attack_direction := Vector2.DOWN

@export var attack_charge_time := 0.2
@export var attack_duration := 0.15
@export var attack_windup_movement_speed_multiplier := 0.3

@export var hammer_cooldown := 0.25
@export var gun_cooldown := 0.6

var can_attack := true

var already_hit := []

@onready var attack_burst_particles: GPUParticles2D = $AttackBurstParticles

func _ready():
	if sound_manager:
		sounds_source.sound_manager = get_node(sound_manager)
	var unique_id = str(get_instance_id())
	my_bus_name = AudioManager.create_bus(unique_id)
	
	sfx_player.bus = my_bus_name
	
func _exit_tree() -> void:
	AudioManager.remove_bus(my_bus_name)

var direction_map := {
	Vector2i.ZERO: "idle",
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.UP: "up",
	Vector2i.DOWN: "down",
}

func update_animation(input_dir: Vector2) -> void:
	#if input_dir == Vector2.ZERO:
		#return # idle state

	var grid_dir = Vector2i(
		roundi(input_dir.normalized().x),
		roundi(input_dir.normalized().y)
	)

	if direction_map.has(grid_dir):
		var anim_name = direction_map[grid_dir]
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			
func get_input() -> Vector2:
	var x_input = Input.get_axis("move_left", "move_right")
	var y_input = Input.get_axis("move_up", "move_down")
	var input_dir = Vector2(x_input, y_input)

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir.normalized()

	return input_dir


func get_direction_name(dir: Vector2) -> String:
	var grid_dir = Vector2i(
		roundi(dir.normalized().x),
		roundi(dir.normalized().y)
	)

	return direction_map.get(grid_dir, "down")

func start_attack() -> void:
	if !can_attack:
		return

	can_attack = false

	state = PlayerState.CHARGE_ATTACK
	attack_direction = facing_direction

	await get_tree().create_timer(attack_charge_time).timeout

	if state != PlayerState.CHARGE_ATTACK:
		return

	match current_weapon:
		WeaponType.HAMMER:
			await perform_melee_attack()

		WeaponType.GUN:
			await perform_ranged_attack()

	var cooldown := hammer_cooldown if current_weapon == WeaponType.HAMMER else gun_cooldown
	await get_tree().create_timer(cooldown).timeout

	can_attack = true
	
func update_attack_hitbox():
	attack_hitbox.position = facing_direction * 12
	attack_hitbox.rotation = facing_direction.angle()

func perform_melee_attack():
	already_hit.clear()
	update_attack_hitbox()
	
	state = PlayerState.ATTACKING
	attack_hitbox.monitoring = true

	var dir_name = get_direction_name(facing_direction)

	var anim_name = "atak_"
	match dir_name:
		"up":
			anim_name += "back"
		"down":
			anim_name += "front"
		_:
			anim_name += dir_name


	animation_player.play(anim_name)
	await animation_player.animation_finished

	attack_burst_particles.global_position = attack_hitbox.global_position
	attack_burst_particles.restart()

	state = PlayerState.MOVE
	attack_hitbox.monitoring = false
	
	return
	
	state = PlayerState.MOVE

	update_animation(facing_direction)
	
func perform_ranged_attack():
	already_hit.clear()
	state = PlayerState.ATTACKING

	var projectile = projectile_scene.instantiate()

	projectile.global_position = projectile_spawn.global_position
	projectile.direction = facing_direction

	get_tree().current_scene.add_child(projectile)

	#animation_player.play("fire") # ???

	#await animation_player.animation_finished

	state = PlayerState.MOVE

func _on_attack_hitbox_body_entered(body):
	
	if body in already_hit:
		return
		
	already_hit.append(body)
	
	if body.has_method("is_hit"):
		body.is_hit(1)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):

		if state == PlayerState.MOVE:
			start_attack()
	
	if Input.is_action_pressed("run"):
		speed = run_speed
	else:
		speed = walk_speed
		
	
	if Input.is_action_just_pressed("swap_weapon"):
		current_weapon = (
		WeaponType.GUN 
		if current_weapon == WeaponType.HAMMER
		else WeaponType.HAMMER
	)	
		
	var current_speed := speed

	# its not called switch for some reason :/
	match state:
		PlayerState.CHARGE_ATTACK:
			current_speed *= attack_windup_movement_speed_multiplier

		PlayerState.ATTACKING:
			current_speed = 0.0

	var input_dir = get_input()
	
	if input_dir != Vector2.ZERO and state == PlayerState.MOVE:
		walk_particles.emitting = true
	else:
		walk_particles.emitting = false
	
	if state == PlayerState.MOVE:
		update_animation(input_dir) # Aktualizacja animacji
	
	var vel: Vector2 = input_dir.normalized() * current_speed
	
	# Convert velocity (px/sec) into movement this frame
	var motion: Vector2 = vel * delta

	# Accumulate fractional movement
	error += motion

	# Extract integer steps (this is the Bresenham-like part)
	var step := Vector2(
		int(error.x),
		int(error.y)
	)

	# Remove used movement, keep remainder
	error -= step

	# Move in discrete pixel step/s (important for collisions)
	_move_pixelwise(step)
	if step.length() > 0.1:
		distance_walked += step.length() * delta
		
		if distance_walked > step_interval:
			if Input.is_action_pressed("run"):
				play_random_run()
				sounds_source.generate_sound(run_loudness)
			else:
				play_random_walk()
				sounds_source.generate_sound(walk_loudness)
			distance_walked = 0.0

func _move_pixelwise(step: Vector2) -> void:
	var steps := int(max(abs(step.x), abs(step.y)))

	if steps == 0:
		return

	var step_dir := Vector2(
		sign(step.x),
		sign(step.y)
	)

	var remaining := step.abs()

	# Distribute steps evenly (Bresenham-style)
	var err := 0.0
	var dx := remaining.x
	var dy := remaining.y

	if dx > dy:
		var slope := dy / dx if dx != 0 else 0.0
		for i in dx:
			_move_and_collide_safe(Vector2(step_dir.x, 0))
			err += slope
			if err >= 1.0:
				_move_and_collide_safe(Vector2(0, step_dir.y))
				err -= 1.0
	else:
		var slope := dx / dy if dy != 0 else 0.0
		for i in dy:
			_move_and_collide_safe(Vector2(0, step_dir.y))
			err += slope
			if err >= 1.0:
				_move_and_collide_safe(Vector2(step_dir.x, 0))
				err -= 1.0


func _move_and_collide_safe(delta: Vector2) -> void:
	if delta == Vector2.ZERO:
		return
	
	var collision = move_and_collide(delta)
	if collision:
		# Stop movement along that axis if collision occurs
		# (simple behavior; can be expanded)
		pass

func play_random_walk():
	if walk_sounds.size() > 0:
		var random_index = randi() % walk_sounds.size()
		sfx_player.stream = walk_sounds[random_index]
		sfx_player.volume_linear = walk_loudness
		sfx_player.play()

func play_random_run():
	if run_sounds.size() > 0:
		var random_index = randi() % run_sounds.size()
		sfx_player.stream = run_sounds[random_index]
		sfx_player.volume_linear = run_loudness
		sfx_player.play()
