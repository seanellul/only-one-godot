extends CharacterBody2D

const SPEED = 200.0
const DASH_SPEED = 600.0
const FAST_DASH_SPEED = 800.0
const SLOW_DASH_SPEED = 400.0
const DASH_DURATION = 0.5
const FAST_DASH_DURATION = 0.3
const SLOW_DASH_DURATION = 0.8
const DASH_COOLDOWN = 1.0

# Roll animation has 14 frames - we'll calculate speed to match dash duration
const ROLL_ANIMATION_FRAMES = 14

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var last_direction = Vector2.RIGHT # Default facing direction
var current_dash_speed = DASH_SPEED

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Update timers
	if dash_timer > 0:
		dash_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Check if dash has ended
	if is_dashing and dash_timer <= 0:
		is_dashing = false
	
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
	
	# Move the player
	move_and_slide()
	
	# Update animations
	update_animation(direction)

func update_animation(direction: Vector2):
	# Handle sprite direction (flip when moving left)
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
	
	# Play appropriate animation
	if is_dashing:
		if animated_sprite.animation != "roll":
			# Calculate animation speed to match dash duration
			var roll_speed = ROLL_ANIMATION_FRAMES / dash_timer
			animated_sprite.speed_scale = roll_speed / 12.0 # 12.0 is the base speed in the scene
			animated_sprite.play("roll")
	elif direction.length() > 0:
		# Reset speed scale for normal animations
		animated_sprite.speed_scale = 1.0
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		# Reset speed scale for normal animations
		animated_sprite.speed_scale = 1.0
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func start_dash(input_direction: Vector2, speed: float = DASH_SPEED, duration: float = DASH_DURATION):
	is_dashing = true
	dash_timer = duration
	dash_cooldown_timer = DASH_COOLDOWN
	
	# Use input direction if moving, otherwise use last direction
	if input_direction.length() > 0:
		dash_direction = input_direction
	else:
		dash_direction = last_direction
	
	# Store current dash speed for velocity calculation
	current_dash_speed = speed
