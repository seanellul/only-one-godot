extends Area2D

@export var pickup_radius: float = 50.0
@export var magnet_strength: float = 200.0
@export var auto_pickup_distance: float = 20.0

var nearby_items: Array[Area2D] = []

func _ready():
	# Set up detection area
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = pickup_radius
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	
	# Set up collision layers
	collision_layer = 0 # Don't collide with anything
	collision_mask = 2 # Detect items layer
	
	# Connect signals
	area_entered.connect(_on_item_entered_range)
	area_exited.connect(_on_item_exited_range)

func _physics_process(delta):
	# Update item magnetism
	for item in nearby_items:
		if is_instance_valid(item):
			apply_magnetism(item, delta)
		else:
			nearby_items.erase(item)

func _on_item_entered_range(area: Area2D):
	if area.name.begins_with("CollectibleItem") and area not in nearby_items:
		nearby_items.append(area)

func _on_item_exited_range(area: Area2D):
	if area in nearby_items:
		nearby_items.erase(area)

func apply_magnetism(item: Area2D, delta: float):
	if not is_instance_valid(item):
		return
	
	var distance_to_player = global_position.distance_to(item.global_position)
	
	# Auto-pickup if very close
	if distance_to_player <= auto_pickup_distance:
		if item.has_method("collect_item"):
			item.collect_item()
		return
	
	# Apply magnetic force
	var direction = (global_position - item.global_position).normalized()
	var force = direction * magnet_strength * delta
	
	# Stronger magnetism when closer
	var distance_factor = 1.0 - (distance_to_player / pickup_radius)
	force *= distance_factor
	
	# Apply the force
	item.global_position += force

func set_pickup_radius(new_radius: float):
	pickup_radius = new_radius
	# Update collision shape
	var collision_shape = get_child(0) as CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = pickup_radius

# Debug visualization
func _draw():
	if Engine.is_editor_hint() or get_tree().debug_collisions_hint:
		# Draw pickup radius
		draw_circle(Vector2.ZERO, pickup_radius, Color(0, 1, 0, 0.2))
		draw_arc(Vector2.ZERO, pickup_radius, 0, TAU, 32, Color(0, 1, 0, 0.8), 2.0)
		
		# Draw auto-pickup zone
		draw_circle(Vector2.ZERO, auto_pickup_distance, Color(1, 1, 0, 0.3))
		draw_arc(Vector2.ZERO, auto_pickup_distance, 0, TAU, 16, Color(1, 1, 0, 1.0), 2.0)