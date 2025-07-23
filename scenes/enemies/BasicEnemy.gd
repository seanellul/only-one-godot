extends CharacterBody2D

# Enemy stats
var max_health: int = 50
var current_health: int = 50
var damage: int = 15
var speed: float = 80.0
var detection_range: float = 100.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0

# AI states
enum AIState {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}

var current_state: AIState = AIState.IDLE
var target_player: CharacterBody2D = null
var is_dead: bool = false

# Visual components
var visual_body: ColorRect
var health_bar: ProgressBar

# Signals
signal enemy_died(enemy)
signal enemy_attacked(target, damage_amount)

func _ready():
	# Set up collision layers
	collision_layer = 8 # Enemy layer
	collision_mask = 1 # World layer (walls)
	
	# Ensure enemy is rendered on top
	z_index = 100
	
	# Create visual representation (red box)
	create_visual_body()
	
	# Create health bar
	create_health_bar()
	
	# Set up collision shape
	create_collision_shape()
	
	# Find player reference
	call_deferred("find_player")
	
	print("BasicEnemy: Spawned with ", current_health, " health and ", damage, " damage at position ", global_position)

func create_visual_body():
	"""Create the red box visual representation"""
	print("BasicEnemy: Creating visual body...")
	
	# Create a simple red ColorRect for visibility
	visual_body = ColorRect.new()
	visual_body.size = Vector2(32, 32) # Make it bigger to be more visible
	visual_body.position = Vector2(-16, -16) # Center the rectangle
	visual_body.color = Color(1.0, 0.0, 0.0, 1.0) # Pure bright red
	
	# Make sure it's visible and on top
	visual_body.z_index = 10
	visual_body.visible = true
	
	add_child(visual_body)
	
	print("BasicEnemy: Created visual body at ", visual_body.position, " with size ", visual_body.size)
	print("BasicEnemy: Visual body color: ", visual_body.color, " visible: ", visual_body.visible)
	
	# Create an additional large colored square as backup
	var backup_visual = ColorRect.new()
	backup_visual.size = Vector2(48, 48)
	backup_visual.position = Vector2(-24, -24)
	backup_visual.color = Color(0.0, 1.0, 0.0, 0.8) # Bright green with transparency
	backup_visual.z_index = 5
	add_child(backup_visual)
	
	print("BasicEnemy: Added backup green visual at ", backup_visual.position)

func create_health_bar():
	"""Create a small health bar above the enemy"""
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(30, 4)
	health_bar.position = Vector2(-15, -20)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	# Style the health bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	add_child(health_bar)

func create_collision_shape():
	"""Create collision shape for the enemy"""
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(24, 24)
	collision_shape.shape = rect_shape
	add_child(collision_shape)

func find_player():
	"""Find the player node in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		print("BasicEnemy: Found player at ", target_player.global_position)
	else:
		# Try alternative search
		target_player = get_tree().get_first_node_in_group("player")
		if not target_player:
			# Last resort - find by name
			target_player = get_tree().current_scene.get_node_or_null("Player")
		
		if target_player:
			print("BasicEnemy: Found player (alternative search) at ", target_player.global_position)
		else:
			print("BasicEnemy: Could not find player!")

func _physics_process(delta):
	if is_dead:
		return
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# AI state machine
	update_ai_state()
	
	# Execute current state behavior
	match current_state:
		AIState.IDLE:
			idle_behavior()
		AIState.CHASING:
			chase_behavior(delta)
		AIState.ATTACKING:
			attack_behavior()
		AIState.DEAD:
			pass # Do nothing when dead

func update_ai_state():
	"""Update AI state based on conditions"""
	if not target_player or is_dead:
		current_state = AIState.DEAD if is_dead else AIState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	var old_state = current_state
	
	match current_state:
		AIState.IDLE:
			if distance_to_player <= detection_range:
				current_state = AIState.CHASING
		
		AIState.CHASING:
			if distance_to_player <= attack_range and attack_timer <= 0:
				current_state = AIState.ATTACKING
			elif distance_to_player > detection_range * 1.2: # Slight hysteresis
				current_state = AIState.IDLE
		
		AIState.ATTACKING:
			if distance_to_player > attack_range:
				current_state = AIState.CHASING
	
	# Debug state changes
	if old_state != current_state:
		print("BasicEnemy: State changed from ", AIState.keys()[old_state], " to ", AIState.keys()[current_state], " (distance: ", distance_to_player, ")")

func idle_behavior():
	"""Behavior when idling"""
	velocity = Vector2.ZERO

func chase_behavior(_delta):
	"""Behavior when chasing the player"""
	if not target_player:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Apply movement
	move_and_slide()

func attack_behavior():
	"""Behavior when attacking"""
	velocity = Vector2.ZERO
	
	if attack_timer <= 0 and target_player:
		perform_attack()
		attack_timer = attack_cooldown

func perform_attack():
	"""Execute an attack"""
	if not target_player:
		return
	
	# Create attack hitbox
	var attack_direction = (target_player.global_position - global_position).normalized()
	var attack_position = global_position + attack_direction * (attack_range * 0.5)
	
	# Create hitbox using the AttackHitbox scene
	var hitbox_scene = preload("res://scenes/combat/AttackHitbox.tscn")
	var hitbox = hitbox_scene.instantiate()
	hitbox.setup_hitbox(attack_position, Vector2(attack_range, attack_range), damage, 0.2, "enemy")
	
	# Add to world
	get_tree().current_scene.add_child(hitbox)
	
	enemy_attacked.emit(target_player, damage)
	print("BasicEnemy: Attacked player for ", damage, " damage")

func take_damage(amount: int, _source = null):
	"""Take damage and handle death"""
	if is_dead:
		return
	
	current_health = max(0, current_health - amount)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	print("BasicEnemy: Took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Flash red when taking damage
	flash_damage()
	
	# Check for death
	if current_health <= 0:
		die()

func flash_damage():
	"""Visual feedback when taking damage"""
	if visual_body:
		var original_color = visual_body.color
		visual_body.color = Color.WHITE
		
		var tween = create_tween()
		tween.tween_property(visual_body, "color", original_color, 0.1)

func die():
	"""Handle enemy death"""
	if is_dead:
		return
	
	is_dead = true
	current_state = AIState.DEAD
	
	# Visual death effect
	if visual_body:
		visual_body.color = Color(0.4, 0.1, 0.1, 0.6) # Darker, more transparent
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	enemy_died.emit(self)
	print("BasicEnemy: Died")
	
	# Remove after a short delay
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func get_enemy_type() -> String:
	"""Return enemy type for identification"""
	return "basic"

# Debug function to get enemy state
func get_debug_info() -> Dictionary:
	return {
		"health": str(current_health) + "/" + str(max_health),
		"state": AIState.keys()[current_state],
		"target": target_player.name if target_player else "None",
		"distance": global_position.distance_to(target_player.global_position) if target_player else 0
	}
