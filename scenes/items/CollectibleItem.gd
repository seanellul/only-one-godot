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
	# Set up item appearance based on type
	setup_item_visual()
	
	# Connect pickup signal
	body_entered.connect(_on_body_entered)
	
	# Store original position for bobbing animation
	original_position = position
	
	# Set up collision detection
	collision_layer = 2 # Items layer
	collision_mask = 1 # Player layer

func setup_item_visual():
	# Get inventory system reference
	var inventory = get_node("/root/InventorySystem")
	if inventory:
		var color = inventory.get_item_color(item_type_index)
		sprite.color = color
		sprite.size = Vector2(24, 24)
		sprite.position = Vector2(-12, -12) # Center the sprite
	
	# Set up collision shape
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	collision.shape = shape

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
	if body.name == "Player" and not is_collected:
		collect_item(body)

func collect_item(_player):
	if is_collected:
		return
		
	is_collected = true
	
	# Add item to inventory
	var inventory_system = get_node("/root/InventorySystem")
	if inventory_system:
		inventory_system.add_item(item_type_index, 1)
	
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