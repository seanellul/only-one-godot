extends CharacterBody2D

# Combat system reference
var combat_system: Node

# Base stats - these can be modified by upgrades
var SPEED = 200.0
var DASH_SPEED = 600.0
var FAST_DASH_SPEED = 800.0
var SLOW_DASH_SPEED = 400.0
var DASH_DURATION = 0.3
var FAST_DASH_DURATION = 0.3
var SLOW_DASH_DURATION = 0.8
var DASH_COOLDOWN = 1.0

# Roll animation has 14 frames - we'll calculate speed to match dash duration
const ROLL_ANIMATION_FRAMES = 14

# Smooth collision settings
const WALL_SLIDE_THRESHOLD = 0.1

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var last_direction = Vector2.RIGHT # Default facing direction
var current_dash_speed = DASH_SPEED
var animation_just_changed = false
var roll_end_transition = false

# Sprite offset compensation for different animation centers
var animation_offsets = {
	"idle": Vector2.ZERO,
	"run": Vector2.ZERO,
	"roll": Vector2(8, 0) # Roll sprites are slightly offset
}
var current_offset = Vector2.ZERO
var target_offset = Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Add to player group for enemy targeting
	add_to_group("player")
	
	# Configure smooth wall sliding
	wall_min_slide_angle = 0.0 # Allow sliding at any angle
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_snap_length = 0
	
	# Add combat system
	combat_system = preload("res://scenes/player/CombatSystem.gd").new()
	add_child(combat_system)
	
	# Set up collision layer for combat
	collision_layer = 2 # Player layer
	collision_mask = 1 # World layer (walls, etc.)
	
	# Connect animation finished signal for smooth transitions
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Initialize sprite offset system
	current_offset = animation_offsets.get(animated_sprite.animation, Vector2.ZERO)
	target_offset = current_offset

func get_combat_system():
	"""Return the combat system for external access"""
	return combat_system

func take_damage(amount: int, _source = null):
	"""Delegate damage to combat system"""
	if combat_system:
		combat_system.take_damage(amount, _source)
	
func _physics_process(delta):
	# Update timers
	if dash_timer > 0:
		dash_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Check if dash has ended
	if is_dashing and dash_timer <= 0:
		is_dashing = false
		# Mark for smooth transition from roll to next animation
		if animated_sprite.animation == "roll":
			roll_end_transition = true
	
	# Get input direction
	var direction = Vector2()
	
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1
	
	# Normalize diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()
		last_direction = direction # Remember last movement direction
	
	# Handle dash input with different types
	if not is_dashing and dash_cooldown_timer <= 0:
		if Input.is_action_just_pressed("ui_select"):
			if Input.is_key_pressed(KEY_SHIFT):
				# Fast dash (Space + Shift)
				start_dash(direction, FAST_DASH_SPEED, FAST_DASH_DURATION)
			elif Input.is_key_pressed(KEY_CTRL):
				# Slow dash (Space + Ctrl)
				start_dash(direction, SLOW_DASH_SPEED, SLOW_DASH_DURATION)
			else:
				# Normal dash (Space only)
				start_dash(direction, DASH_SPEED, DASH_DURATION)
	
	# Set velocity based on current state
	if is_dashing:
		velocity = dash_direction * current_dash_speed
	else:
		if direction.length() > 0:
			velocity = direction * SPEED
		else:
			velocity = Vector2.ZERO
	
	# Move the player with smooth wall sliding
	move_and_slide()
	
	# Apply smooth collision correction for small overlaps
	smooth_wall_collision(direction)
	
	# Update animations
	update_animation(direction)
	
	# Smooth sprite offset interpolation
	update_sprite_offset(delta)

func smooth_wall_collision(input_direction: Vector2):
	# Handle small collision overlaps by applying gentle sliding force
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collision_normal = collision.get_normal()
			
			# If we're trying to move into a wall but only slightly overlapping
			if input_direction.length() > 0:
				var dot_product = input_direction.normalized().dot(-collision_normal)
				
				# If we're moving roughly towards the wall (small angle)
				if dot_product > WALL_SLIDE_THRESHOLD:
					# Calculate slide direction along the wall
					var slide_direction = input_direction.slide(collision_normal)
					
					# Apply a small sliding force to help glide along walls
					if slide_direction.length() > 0:
						var slide_force = slide_direction.normalized() * 50 * get_physics_process_delta_time()
						position += slide_force

func update_sprite_offset(delta: float):
	# Smooth interpolation between sprite offsets to prevent snapping
	var lerp_speed = 15.0 # How fast to transition between offsets
	
	# Get target offset for current animation
	var animation_name = animated_sprite.animation
	if animation_name in animation_offsets:
		target_offset = animation_offsets[animation_name]
	else:
		target_offset = Vector2.ZERO
	
	# Smoothly interpolate to target offset
	current_offset = current_offset.lerp(target_offset, lerp_speed * delta)
	
	# Apply the offset to the sprite
	animated_sprite.position = current_offset

func update_animation(direction: Vector2):
	# Handle sprite direction (flip when moving left)
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
	
	# Don't override attack animations - let combat system handle those
	if combat_system and combat_system.is_attacking:
		return
	
	# Don't override death animations - let combat system handle those
	if combat_system and combat_system.is_dead:
		return
	
	# Handle roll ending transition
	if roll_end_transition and not is_dashing:
		roll_end_transition = false
		# Force transition to appropriate animation
		if direction.length() > 0:
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("run")
		else:
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("idle")
		return
	
	# Play appropriate animation
	if is_dashing:
		if animated_sprite.animation != "roll":
			# Calculate precise animation speed to match dash duration exactly
			var precise_roll_speed = ROLL_ANIMATION_FRAMES / dash_timer
			animated_sprite.speed_scale = precise_roll_speed / 9.0 # 9.0 is the base speed in scene
			animated_sprite.play("roll")
			animation_just_changed = true
		# If roll animation finished but dash is still active, hold last frame
		elif not animated_sprite.is_playing():
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("roll") - 1
	elif direction.length() > 0:
		# Reset speed scale for normal animations
		animated_sprite.speed_scale = 1.0
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
			animation_just_changed = true
	else:
		# Reset speed scale for normal animations
		animated_sprite.speed_scale = 1.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
			animation_just_changed = true

func _on_animation_finished():
	# Handle smooth transitions when animations complete
	if animated_sprite.animation == "roll":
		# If dash is still active, hold on the last frame
		if is_dashing:
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("roll") - 1
		else:
			# Dash is done, prepare for clean transition
			roll_end_transition = true
			# Sprite position is now handled by offset system, no manual reset needed

func start_dash(input_direction: Vector2, speed: float = DASH_SPEED, duration: float = DASH_DURATION):
	is_dashing = true
	dash_timer = duration
	dash_cooldown_timer = DASH_COOLDOWN
	roll_end_transition = false # Reset transition flag
	
	# Use input direction if moving, otherwise use last direction
	if input_direction.length() > 0:
		dash_direction = input_direction
	else:
		dash_direction = last_direction
	
	# Store current dash speed for velocity calculation
	current_dash_speed = speed
