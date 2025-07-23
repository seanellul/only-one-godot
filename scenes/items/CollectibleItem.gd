extends Area2D

@export var item_type_index: int = 0 # 0=COIN, 1=KEY, 2=HEALTH_POTION, 3=SPEED_BOOST, 4=DASH_BOOST
@export var pickup_sound_enabled: bool = true

var item_type # Will be set from InventorySystem.ItemType

@onready var sprite: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_collected: bool = false
var bob_timer: float = 0.0
var original_position: Vector2

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

func _physics_process(delta):
	if not is_collected:
		# Gentle bobbing animation
		bob_timer += delta * 3.0
		var bob_offset = sin(bob_timer) * 2.0
		position = original_position + Vector2(0, bob_offset)
		
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