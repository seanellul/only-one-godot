extends Area2D

# Hitbox properties
var damage: int = 0
var lifetime: float = 0.3
var attacker_type: String = "" # "player" or "enemy"
var hit_targets: Array = [] # Track what we've already hit
var debug_visible: bool = true

# Visual components
var debug_shape: ColorRect
var collision_shape: CollisionShape2D

# Signals
signal target_hit(target, damage_amount: int)

func _ready():
	# Add to hitbox group for debugging
	add_to_group("attack_hitboxes")
	
	# Connect collision detection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Set collision layers appropriately
	setup_collision_layers()
	
	# Auto-destroy after lifetime
	if lifetime > 0:
		var timer = Timer.new()
		timer.wait_time = lifetime
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		add_child(timer)
		timer.start()

func setup_hitbox(pos: Vector2, size: Vector2, dmg: int, life: float, attacker: String):
	"""Setup the hitbox with all necessary parameters using global position"""
	global_position = pos
	damage = dmg
	lifetime = life
	attacker_type = attacker
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Create debug visualization
	if debug_visible:
		create_debug_visual(size)
	
	print("AttackHitbox: Created ", attacker_type, " hitbox - Size: ", size, " Damage: ", damage)

func setup_hitbox_relative(pos: Vector2, size: Vector2, dmg: int, life: float, attacker: String):
	"""Setup the hitbox with all necessary parameters using local position (relative to parent)"""
	position = pos  # Use local position since this is a child of player
	damage = dmg
	lifetime = life
	attacker_type = attacker
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Create debug visualization
	if debug_visible:
		create_debug_visual(size)
	
	print("AttackHitbox: Created ", attacker_type, " hitbox (relative) - Size: ", size, " Damage: ", damage, " Local pos: ", pos)

func create_debug_visual(size: Vector2):
	"""Create debug visualization for the hitbox"""
	debug_shape = ColorRect.new()
	debug_shape.size = size
	debug_shape.position = - size / 2 # Center the rectangle
	
	# Different colors for different attackers
	match attacker_type:
		"player":
			debug_shape.color = Color(0, 1, 0, 0.3) # Green for player
		"enemy":
			debug_shape.color = Color(1, 0, 0, 0.3) # Red for enemy
		_:
			debug_shape.color = Color(1, 1, 0, 0.3) # Yellow for unknown
	
	add_child(debug_shape)
	
	# Create border for better visibility
	var border = ColorRect.new()
	border.size = size
	border.position = - size / 2
	border.color = Color.TRANSPARENT
	
	# Add border using a stylebox
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.TRANSPARENT
	style_box.border_color = debug_shape.color * 2 # Brighter border
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	
	var border_panel = Panel.new()
	border_panel.size = size
	border_panel.position = - size / 2
	border_panel.add_theme_stylebox_override("panel", style_box)
	add_child(border_panel)

func setup_collision_layers():
	"""Setup collision layers based on attacker type"""
	# Clear all layers first
	collision_layer = 0
	collision_mask = 0
	
	match attacker_type:
		"player":
			# Player attacks should hit enemies
			collision_layer = 4 # Attack layer
			collision_mask = 8 # Enemy layer
		"enemy":
			# Enemy attacks should hit player
			collision_layer = 8 # Enemy attack layer
			collision_mask = 2 # Player layer
		_:
			# Default: hit everything
			collision_mask = 0xFFFFFFFF

func _on_body_entered(body):
	"""Handle collision with CharacterBody2D nodes"""
	if should_hit_target(body):
		deal_damage_to_target(body)

func _on_area_entered(area):
	"""Handle collision with Area2D nodes (hitboxes, etc.)"""
	if should_hit_target(area):
		deal_damage_to_target(area)

func should_hit_target(target) -> bool:
	"""Check if we should hit this target"""
	# Don't hit the same target twice
	if target in hit_targets:
		return false
	
	# Don't hit targets of the same type (no friendly fire for now)
	if attacker_type == "player" and target.has_method("get_combat_system"):
		return false # Don't hit other players
	
	if attacker_type == "enemy" and target.has_method("get_enemy_type"):
		return false # Don't hit other enemies
	
	# Check if target can take damage
	if not target.has_method("take_damage") and not target.has_method("damage"):
		return false
	
	return true

func deal_damage_to_target(target):
	"""Deal damage to the target"""
	hit_targets.append(target)
	
	# Try different damage methods
	var damage_dealt = false
	
	# Method 1: Direct take_damage method
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		damage_dealt = true
	
	# Method 2: Combat system component
	elif target.has_method("get_combat_system"):
		var combat_system = target.get_combat_system()
		if combat_system and combat_system.has_method("take_damage"):
			combat_system.take_damage(damage, self)
			damage_dealt = true
	
	# Method 3: Damage method
	elif target.has_method("damage"):
		target.damage(damage)
		damage_dealt = true
	
	if damage_dealt:
		target_hit.emit(target, damage)
		print("AttackHitbox: Hit ", target.name, " for ", damage, " damage")
		
		# Visual feedback for hit
		create_hit_effect(target.global_position)
	else:
		print("AttackHitbox: Failed to damage ", target.name, " - no damage method found")

func create_hit_effect(pos: Vector2):
	"""Create blood splatter effect when hitting a target"""
	create_blood_splatter(pos)

func create_blood_splatter(pos: Vector2):
	"""Create blood splatter effect that properly cleans up"""
	var blood_container = Node2D.new()
	blood_container.global_position = pos
	get_tree().current_scene.add_child(blood_container)
	
	# Create multiple blood droplets for realistic effect
	for i in range(5):
		var droplet = ColorRect.new()
		droplet.size = Vector2(randi_range(8, 16), randi_range(8, 16))
		droplet.color = Color(0.8, 0.1, 0.1, 0.9)  # Dark red blood
		
		# Random position around impact point
		var offset = Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		droplet.position = offset - droplet.size / 2
		blood_container.add_child(droplet)
	
	# Create main blood splatter
	var main_splatter = ColorRect.new()
	main_splatter.size = Vector2(24, 24)
	main_splatter.color = Color(0.7, 0.0, 0.0, 0.8)  # Darker blood
	main_splatter.position = -main_splatter.size / 2
	blood_container.add_child(main_splatter)
	
	# Animate the blood effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out over time
	tween.tween_property(blood_container, "modulate:a", 0.0, 0.5)
	
	# Slight expansion
	tween.tween_property(blood_container, "scale", Vector2(1.3, 1.3), 0.2)
	
	# Ensure cleanup with timer as backup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 0.6  # Slightly longer than animation
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(blood_container.queue_free)
	blood_container.add_child(cleanup_timer)
	cleanup_timer.start()
	
	# Also connect tween finished as primary cleanup
	tween.finished.connect(func(): if is_instance_valid(blood_container): blood_container.queue_free())

func set_debug_visible(visible: bool):
	"""Toggle debug visualization"""
	debug_visible = visible
	if debug_shape:
		debug_shape.visible = visible

# Static function to create hitboxes easily
static func create_attack_hitbox(pos: Vector2, size: Vector2, dmg: int, life: float, attacker: String):
	var hitbox_scene = preload("res://scenes/combat/AttackHitbox.tscn")
	var hitbox = hitbox_scene.instantiate()
	hitbox.setup_hitbox(pos, size, dmg, life, attacker)
	return hitbox