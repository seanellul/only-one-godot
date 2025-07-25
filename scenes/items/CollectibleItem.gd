extends Area2D

@export var item_type_index: int = 0 # 0=COIN, 1=KEY, 2=HEALTH_POTION, 3=SPEED_BOOST, 4=DASH_BOOST
@export var pickup_sound_enabled: bool = true

var item_type # Will be set from InventorySystem.ItemType

@onready var sprite: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_collected: bool = false
var bob_timer: float = 0.0
var original_position: Vector2

# Magnetism properties
var magnetism_radius: float = 80.0 # Distance at which items are attracted to player
var magnetism_strength: float = 150.0 # Speed of attraction
var is_magnetic: bool = false
var player_reference: CharacterBody2D = null

func _ready():
	print("CollectibleItem: Ready - item type ", item_type_index, " at position ", global_position)
	
	# Ensure item is in the collectible_items group
	add_to_group("collectible_items")
	
	# Set up item appearance based on type
	setup_item_visual()
	
	# Connect pickup signal
	body_entered.connect(_on_body_entered)
	
	# Store original position for bobbing animation
	original_position = global_position
	
	# Set up collision detection
	collision_layer = 16 # Items layer (separate from player)
	collision_mask = 2 # Player layer (matches player's collision_layer)
	
	# Ensure visibility
	z_index = 50
	visible = true
	
	print("CollectibleItem: Setup complete - collision layers: ", collision_layer, "/", collision_mask)

func setup_item_visual():
	print("CollectibleItem: Setting up visual for item type ", item_type_index)
	
	# Get inventory system reference
	var inventory = get_node_or_null("/root/InventorySystem")
	if inventory:
		var color = inventory.get_item_color(item_type_index)
		sprite.color = color
		print("CollectibleItem: Set color to ", color, " for item type ", item_type_index)
	else:
		# Fallback colors if no inventory system
		match item_type_index:
			0: sprite.color = Color.YELLOW # Coin
			1: sprite.color = Color.CYAN # Key
			2: sprite.color = Color.RED # Health Potion
			3: sprite.color = Color.GREEN # Speed Boost
			4: sprite.color = Color.MAGENTA # Dash Boost
			_: sprite.color = Color.WHITE # Default
		print("CollectibleItem: Using fallback color ", sprite.color, " for item type ", item_type_index)
	
	sprite.size = Vector2(28, 28) # Make slightly larger
	sprite.position = Vector2(-14, -14) # Center the sprite
	sprite.z_index = 1 # Ensure sprite is on top
	
	# Set up collision shape
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28) # Match sprite size
	collision.shape = shape
	
	print("CollectibleItem: Visual setup complete - size: ", sprite.size, " color: ", sprite.color)

func find_player():
	"""Find and cache player reference for magnetism"""
	player_reference = get_tree().get_first_node_in_group("player")
	if player_reference:
		print("CollectibleItem: Found player for magnetism")

func check_magnetism():
	"""Check if item should be attracted to player"""
	if not player_reference:
		return
		
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	# Apply different magnetism radii based on item type (priority system)
	var effective_radius = get_magnetism_radius_for_type()
	
	if distance_to_player <= effective_radius and not is_magnetic:
		# Start magnetism
		is_magnetic = true
		print("CollectibleItem: Starting magnetism for ", item_type_index)
		
		# Create attraction particle trail
		create_magnetism_trail()
		
	elif distance_to_player > effective_radius and is_magnetic:
		# Stop magnetism
		is_magnetic = false
		original_position = global_position # Update bobbing center

func get_magnetism_radius_for_type() -> float:
	"""Get magnetism radius based on item priority"""
	match item_type_index:
		0: return magnetism_radius * 1.2 # Coins - highest priority
		1: return magnetism_radius * 1.1 # Keys - high priority
		2: return magnetism_radius * 0.9 # Health potions - medium priority
		3: return magnetism_radius * 0.8 # Speed boosts - lower priority
		4: return magnetism_radius * 0.8 # Dash boosts - lower priority
		_: return magnetism_radius

func apply_magnetism(delta: float):
	"""Apply magnetic attraction toward player"""
	if not player_reference:
		return
		
	var direction_to_player = (player_reference.global_position - global_position).normalized()
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	# Increase speed as we get closer (feels more responsive)
	var speed_multiplier = 1.0 + (1.0 - min(distance_to_player / get_magnetism_radius_for_type(), 1.0))
	var movement_speed = magnetism_strength * speed_multiplier
	
	# Move toward player
	global_position += direction_to_player * movement_speed * delta
	
	# Add gentle bobbing even during magnetism for visual appeal
	bob_timer += delta * 2.0
	var bob_offset = sin(bob_timer) * 1.0 # Reduced bobbing during magnetism
	global_position += Vector2(0, bob_offset * delta * 10)

func apply_bobbing_animation(delta: float):
	"""Apply normal bobbing animation when not magnetic"""
	bob_timer += delta * 3.0
	var bob_offset = sin(bob_timer) * 2.0
	position = original_position + Vector2(0, bob_offset)

func create_magnetism_trail():
	"""Create visual trail effect when magnetism starts"""
	# Simple particle effect for magnetism
	var trail_particles = CPUParticles2D.new()
	add_child(trail_particles)
	
	# Configure particles
	trail_particles.emitting = true
	trail_particles.amount = 15
	trail_particles.lifetime = 0.5
	trail_particles.direction = Vector2(0, -1)
	trail_particles.spread = 30.0
	trail_particles.initial_velocity_min = 20.0
	trail_particles.initial_velocity_max = 40.0
	trail_particles.scale_amount_min = 0.3
	trail_particles.scale_amount_max = 0.7
	
	# Use item color for particles
	trail_particles.color = sprite.color
	trail_particles.color.a = 0.7
	
	# Auto-cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(trail_particles.queue_free)
	trail_particles.add_child(cleanup_timer)
	cleanup_timer.start()

func _physics_process(delta):
	if not is_collected:
		# Update player reference if needed
		if not player_reference:
			find_player()
		
		# Check for magnetism
		if player_reference:
			check_magnetism()
		
		# Apply movement (either magnetism or bobbing)
		if is_magnetic and player_reference:
			apply_magnetism(delta)
		else:
			apply_bobbing_animation(delta)
		
		# Gentle color pulsing
		var pulse = (sin(bob_timer * 2.0) * 0.1) + 0.9
		sprite.modulate = Color(pulse, pulse, pulse, 1.0)

func _on_body_entered(body):
	print("CollectibleItem: Body entered - ", body.name, " (is_player: ", body.is_in_group("player"), ")")
	if (body.name == "Player" or body.is_in_group("player")) and not is_collected:
		print("CollectibleItem: Collecting item type ", item_type_index)
		collect_item(body)

func collect_item(_player):
	if is_collected:
		print("CollectibleItem: Already collected!")
		return
		
	is_collected = true
	print("CollectibleItem: Item collected! Type: ", item_type_index)
	
	# Add item to inventory
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.add_item(item_type_index, 1)
		print("CollectibleItem: Added to inventory system")
	else:
		print("CollectibleItem: Warning - no inventory system found!")
	
	# Play pickup animation
	play_pickup_animation()

func play_pickup_animation():
	# Create pickup tween animation
	var tween = create_tween()
	tween.set_parallel(true) # Allow multiple animations
	
	# Scale up and fade out
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Move up slightly
	tween.tween_property(self, "position", position + Vector2(0, -20), 0.3)
	
	# Remove after animation
	tween.tween_callback(queue_free).set_delay(0.3)

func set_item_type(new_type):
	item_type_index = new_type
	item_type = new_type # Keep both for compatibility
	if is_inside_tree():
		setup_item_visual()