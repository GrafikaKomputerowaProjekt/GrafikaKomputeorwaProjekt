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
@export var hammer_sound: AudioStream
@export_range(0.0, 1.0) var walk_loudness: float = 0.5
@export_range(0.0, 1.0) var run_loudness: float = 0.5
@export_range(0.0, 1.0) var hammer_loudness: float = 0.5

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

# ==========================================
# EMERGENCY HEALTH SYSTEM VARIABLES
# ==========================================
var has_shield: bool = true
var is_dead: bool = false
var ui_label: Label

func _ready():
	# Rejestracja gracza w grupie do łatwej identyfikacji dla przeciwników
	add_to_group("Player")
	print("[PLAYER SYSTEM] Player initialized and registered in 'Player' group.")
	
	_setup_emergency_ui()

	if sound_manager:
		sounds_source.sound_manager = get_node(sound_manager)
		print("[PLAYER AUDIO] Sound manager connected via NodePath: ", sound_manager)
		
	var unique_id = str(get_instance_id())
	my_bus_name = AudioManager.create_bus(unique_id)
	sfx_player.bus = my_bus_name
	print("[PLAYER AUDIO] Dynamic audio bus created: ", my_bus_name)
	
func _exit_tree() -> void:
	AudioManager.remove_bus(my_bus_name)
	print("[PLAYER AUDIO] Cleaned up audio bus: ", my_bus_name)

var direction_map := {
	Vector2i.ZERO: "idle",
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.UP: "up",
	Vector2i.DOWN: "down",
}

func update_animation(input_dir: Vector2) -> void:
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
		print("[PLAYER WEAPON] Attack requested, but weapon is on cooldown!")
		return

	can_attack = false
	state = PlayerState.CHARGE_ATTACK
	attack_direction = facing_direction
	
	var weapon_name = "HAMMER" if current_weapon == WeaponType.HAMMER else "GUN"
	print("[PLAYER WEAPON] Starting attack windup with: ", weapon_name, " | Dir: ", attack_direction)

	await get_tree().create_timer(attack_charge_time).timeout

	if state != PlayerState.CHARGE_ATTACK:
		print("[PLAYER WEAPON] Attack cancelled during windup (state changed).")
		return

	match current_weapon:
		WeaponType.HAMMER:
			await perform_melee_attack()
		WeaponType.GUN:
			await perform_ranged_attack()

	var cooldown := hammer_cooldown if current_weapon == WeaponType.HAMMER else gun_cooldown
	await get_tree().create_timer(cooldown).timeout

	can_attack = true
	print("[PLAYER WEAPON] Cooldown finished. Ready to attack again.")
	
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

	print("[PLAYER MELEE] Triggering hammer swing. Animation: ", anim_name, " | Hitbox active.")
	animation_player.play(anim_name)
	await animation_player.animation_finished
	
	play_hammer()
	sounds_source.generate_sound(hammer_loudness)
	attack_burst_particles.global_position = attack_hitbox.global_position
	attack_burst_particles.restart()

	state = PlayerState.MOVE
	attack_hitbox.monitoring = false
	print("[PLAYER MELEE] Hammer strike complete. Hitbox inactive. State reverted to MOVE.")
	
	update_animation(facing_direction)
	
func perform_ranged_attack() -> void:
	already_hit.clear()
	state = PlayerState.ATTACKING

	if projectile_scene == null:
		print("[PLAYER RANGED] CRITICAL ERROR: projectile_scene is not assigned!")
		state = PlayerState.MOVE
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = projectile_spawn.global_position
	projectile.direction = facing_direction

	get_tree().current_scene.add_child(projectile)
	print("[PLAYER RANGED] Gun fired. Projectile spawned at: ", projectile.global_position, " | Dir: ", facing_direction)

	state = PlayerState.MOVE

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body in already_hit:
		return
		
	already_hit.append(body)
	print("[PLAYER MELEE] Collision detected on swing! Hit: ", body.name, " (Type: ", body.get_class(), ")")
	
	if body.has_method(&"hit_by_projectile"):
		print("[PLAYER MELEE] Executing 'hit_by_projectile(2)' on target: ", body.name)
		body.hit_by_projectile(2)
	elif body.has_method(&"is_hit"):
		print("[PLAYER MELEE] Target has no health logic, executing fallback 'is_hit()' on: ", body.name)
		body.is_hit()
	else:
		print("[PLAYER MELEE] Target has no damage-receiving methods. Ignoring.")

func _physics_process(delta: float) -> void:
	if is_dead:
		if Input.is_key_pressed(KEY_R):
			print("[PLAYER SYSTEM] Restart key pressed. Reloading scene...")
			get_tree().paused = false
			get_tree().reload_current_scene()
		return

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
		var weapon_name = "GUN" if current_weapon == WeaponType.GUN else "HAMMER"
		print("[PLAYER WEAPON] Swapped weapon! Current equipped: ", weapon_name)
		
	var current_speed := speed

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
		update_animation(input_dir)
	
	var vel: Vector2 = input_dir.normalized() * current_speed
	var motion: Vector2 = vel * delta

	error += motion

	var step := Vector2(
		int(error.x),
		int(error.y)
	)

	error -= step

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


func _move_and_collide_safe(delta_vec: Vector2) -> void:
	if delta_vec == Vector2.ZERO:
		return
	
	var collision = move_and_collide(delta_vec)
	if collision:
		var collider = collision.get_collider()
		if is_instance_valid(collider) and collider.name.begins_with("Slime"):
			print("[PLAYER DETECTOR] Physical collision with enemy: ", collider.name)
			take_damage()

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

func play_hammer():
	sfx_player.stream = hammer_sound
	sfx_player.volume_linear = hammer_loudness
	sfx_player.play()

# ==========================================
# EMERGENCY HEALTH & DAMAGE SYSTEM
# ==========================================

func _setup_emergency_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	
	ui_label = Label.new()
	ui_label.position = Vector2(8, 8)
	ui_label.scale = Vector2(0.6, 0.6)
	canvas.add_child(ui_label)
	_update_ui_text()

func _update_ui_text() -> void:
	if is_dead:
		ui_label.text = "HP: DEAD"
	elif has_shield:
		ui_label.text = "SHIELD: ACTIVE"
	else:
		ui_label.text = "SHIELD: BROKEN"

func take_damage() -> void:
	if is_dead:
		return
		
	if has_shield:
		has_shield = false
		print("[PLAYER HEALTH] Shield broken! HP remaining: 1.")
		_update_ui_text()
		_trigger_shield_break_visuals()
		play_random_run() 
	else:
		trigger_death()

func _trigger_shield_break_visuals() -> void:
	modulate = Color(10, 0, 0, 1)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1, 1)

func trigger_death() -> void:
	is_dead = true
	print("[PLAYER HEALTH] Player is dead. Game over triggered.")
	_update_ui_text()
	
	scale = Vector2(1.5, 0.1)
	modulate = Color(0.2, 0.2, 0.2, 1)
	
	get_tree().paused = true
	
	var canvas = ui_label.get_parent()
	var go_label := Label.new()
	go_label.text = "GAME OVER\nPress R to Restart"
	go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	go_label.position = Vector2(80, 60)
	canvas.add_child(go_label)
