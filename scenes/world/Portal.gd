extends Area2D

# Portal for traveling between zones
class_name Portal

# Portal configuration
var destination_zone: int # WorldSystemManager.ZoneType
var destination_level: int = 1
var keys_required: int = 0
var is_activated: bool = false

# Visual elements
var portal_visual: Node2D
var key_indicator: Label
var interaction_prompt: Label

# Portal states
var player_in_range: bool = false
var can_use: bool = false

signal portal_activated(destination_zone: int, destination_level: int)

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create visual elements
	create_portal_visual()
	create_ui_elements()
	
	# Set collision layer
	collision_layer = 0
	collision_mask = 2 # Player layer

func setup_portal(dest_zone: int, dest_level: int, required_keys: int):
	"""Configure the portal destination and requirements"""
	destination_zone = dest_zone
	destination_level = dest_level
	keys_required = required_keys
	
	# Update visual based on requirements
	update_portal_visual()
	update_key_indicator()
	
	print("Portal: Set up portal to zone ", dest_zone, " level ", dest_level, " (keys: ", required_keys, ")")

func create_portal_visual():
	"""Create the visual representation of the portal"""
	portal_visual = Node2D.new()
	add_child(portal_visual)
	
	# Create portal base
	var base = ColorRect.new()
	base.size = Vector2(64, 64)
	base.color = Color(0.2, 0.2, 0.8, 0.8) # Blue portal
	base.position = Vector2(-32, -32)
	portal_visual.add_child(base)
	
	# Create portal effect (inner glow)
	var glow = ColorRect.new()
	glow.size = Vector2(48, 48)
	glow.color = Color(0.4, 0.4, 1.0, 0.6) # Lighter blue
	glow.position = Vector2(-24, -24)
	portal_visual.add_child(glow)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Start portal animation
	animate_portal()

func create_ui_elements():
	"""Create UI elements for portal interaction"""
	# Key requirement indicator
	key_indicator = Label.new()
	key_indicator.position = Vector2(-30, -60)
	key_indicator.add_theme_color_override("font_color", Color.YELLOW)
	add_child(key_indicator)
	
	# Interaction prompt
	interaction_prompt = Label.new()
	interaction_prompt.text = "Press F to enter portal"
	interaction_prompt.position = Vector2(-60, 40)
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.visible = false
	add_child(interaction_prompt)

func update_portal_visual():
	"""Update portal appearance based on destination"""
	if not portal_visual:
		return
	
	var base_color = Color.BLUE
	var glow_color = Color.CYAN
	
	# Different colors for different zone types
	match destination_zone:
		0: # TOWN
			base_color = Color.GREEN
			glow_color = Color.LIME
		1: # DANGER_ZONE
			base_color = Color.RED
			glow_color = Color.ORANGE
		2: # BOSS_ARENA
			base_color = Color.PURPLE
			glow_color = Color.MAGENTA
		3: # SECRET_AREA
			base_color = Color.GOLD
			glow_color = Color.YELLOW
	
	# Update colors
	if portal_visual.get_child_count() >= 2:
		portal_visual.get_child(0).color = base_color + Color(0, 0, 0, -0.2)
		portal_visual.get_child(1).color = glow_color + Color(0, 0, 0, -0.4)

func update_key_indicator():
	"""Update the key requirement display"""
	if not key_indicator:
		return
	
	if keys_required > 0:
		key_indicator.text = "Keys: " + str(keys_required)
		key_indicator.visible = true
	else:
		key_indicator.visible = false

func animate_portal():
	"""Create portal animation effect"""
	if not portal_visual:
		return
	
	# Create scaling animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(portal_visual, "scale", Vector2(1.1, 1.1), 1.0)
	tween.tween_property(portal_visual, "scale", Vector2(1.0, 1.0), 1.0)

func _input(event):
	"""Handle portal activation input"""
	if not player_in_range:
		return
	
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		attempt_portal_use()

func attempt_portal_use():
	"""Try to use the portal"""
	if not can_use:
		show_insufficient_keys_message()
		return
	
	# Check if player has enough keys
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		print("Portal: No inventory system found")
		return
	
	var player_keys = inventory_system.get_item_count(1) # Keys are item type 1
	
	if player_keys < keys_required:
		show_insufficient_keys_message()
		return
	
	# Consume keys
	if keys_required > 0:
		inventory_system.remove_item(1, keys_required)
		print("Portal: Used ", keys_required, " keys")
	
	# Activate portal
	activate_portal()

func show_insufficient_keys_message():
	"""Show message when player doesn't have enough keys"""
	var needed = keys_required
	var inventory_system = get_node_or_null("/root/InventorySystem")
	var have = inventory_system.get_item_count(1) if inventory_system else 0
	
	# Create temporary message
	var message = Label.new()
	message.text = "Need " + str(needed) + " keys (have " + str(have) + ")"
	message.position = Vector2(-60, -80)
	message.add_theme_color_override("font_color", Color.RED)
	add_child(message)
	
	# Remove message after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(message):
		message.queue_free()

func activate_portal():
	"""Activate the portal and travel to destination"""
	print("Portal: Activating portal to zone ", destination_zone, " level ", destination_level)
	
	# Portal activation effect
	create_activation_effect()
	
	# Emit signal to travel
	portal_activated.emit(destination_zone, destination_level)

func create_activation_effect():
	"""Create visual effect when portal activates"""
	if not portal_visual:
		return
	
	# Flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property(portal_visual, "modulate", Color.WHITE, 0.2)
	flash_tween.tween_property(portal_visual, "modulate", Color(1, 1, 1, 0.5), 0.2)
	flash_tween.tween_property(portal_visual, "modulate", Color.WHITE, 0.2)

func _on_body_entered(body):
	"""Handle player entering portal area"""
	if body.is_in_group("player"):
		player_in_range = true
		
		# Check if player can use portal
		update_can_use_status()
		
		# Show interaction prompt
		if interaction_prompt:
			interaction_prompt.visible = true
		
		print("Portal: Player entered portal range")

func _on_body_exited(body):
	"""Handle player leaving portal area"""
	if body.is_in_group("player"):
		player_in_range = false
		can_use = false
		
		# Hide interaction prompt
		if interaction_prompt:
			interaction_prompt.visible = false
		
		print("Portal: Player left portal range")

func update_can_use_status():
	"""Update whether the player can use this portal"""
	if keys_required == 0:
		can_use = true
		return
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		can_use = false
		return
	
	var player_keys = inventory_system.get_item_count(1)
	can_use = player_keys >= keys_required
	
	# Update visual feedback
	if interaction_prompt:
		if can_use:
			interaction_prompt.add_theme_color_override("font_color", Color.GREEN)
			interaction_prompt.text = "Press F to enter portal"
		else:
			interaction_prompt.add_theme_color_override("font_color", Color.RED)
			interaction_prompt.text = "Need " + str(keys_required) + " keys"

func get_portal_info() -> Dictionary:
	"""Get information about this portal"""
	return {
		"destination_zone": destination_zone,
		"destination_level": destination_level,
		"keys_required": keys_required,
		"can_use": can_use,
		"player_in_range": player_in_range
	}
