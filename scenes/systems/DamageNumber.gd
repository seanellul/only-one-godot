extends Control

# Floating damage number display
class_name DamageNumber

@onready var label: Label
var damage_value: int
var is_critical: bool = false
var is_player_damage: bool = false

# Animation settings
var float_duration: float = 1.5
var float_distance: float = 60.0
var fade_start_time: float = 0.8

func _ready():
	# Create label if it doesn't exist
	if not label:
		setup_label()
	
	# Start animation
	animate_damage_number()

func setup_label():
	"""Create and configure the damage label"""
	label = Label.new()
	add_child(label)
	
	# Configure label properties
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	# Add outline for better visibility
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

func setup(damage: int, critical: bool = false, player_dmg: bool = false):
	"""Configure the damage number with given parameters"""
	damage_value = damage
	is_critical = critical
	is_player_damage = player_dmg
	
	# Ensure label exists
	if not label:
		setup_label()
	
	# Set text
	var text = str(damage)
	if is_critical:
		text = "CRIT! " + text + "!"
	
	label.text = text
	
	# Style based on damage type
	apply_damage_style()

func apply_damage_style():
	"""Apply visual styling based on damage type"""
	if not label:
		return
	
	if is_player_damage:
		# Player taking damage - red, larger
		label.add_theme_color_override("font_color", Color.RED)
		label.add_theme_font_size_override("font_size", 24)
		float_distance = 80.0
	elif is_critical:
		# Critical damage - bright yellow, largest
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_font_size_override("font_size", 28)
		float_distance = 100.0
		# Add slight glow effect
		label.add_theme_color_override("font_shadow_color", Color(1, 1, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)
	else:
		# Normal damage - white, standard size
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 20)
		float_distance = 60.0

func animate_damage_number():
	"""Animate the damage number floating upward and fading"""
	# Validate this node is still valid
	if not is_instance_valid(self):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "DamageNumber node invalid during animation setup")
		return
	
	# Get starting position
	var start_pos = position
	var end_pos = start_pos + Vector2(randf_range(-20, 20), -float_distance)
	
	# Create tween for animation with safety checks
	var tween = create_tween()
	if not tween or not is_instance_valid(tween):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create main tween for damage number")
		call_deferred("queue_free")
		return
	
	tween.set_parallel(true)
	
	# Validate self is still valid before each operation
	if not is_instance_valid(self):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "DamageNumber became invalid during tween setup")
		return
	
	# Float upward with slight random horizontal movement
	var movement_tween = tween.tween_method(animate_position, start_pos, end_pos, float_duration)
	if not movement_tween:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create movement tween for damage number")
		call_deferred("queue_free")
		return
	
	# Scale animation for impact (create a separate sequential tween)
	var scale_tween = create_tween()
	if not scale_tween or not is_instance_valid(scale_tween):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create scale tween for damage number")
		call_deferred("queue_free")
		return
	
	# Verify self is still valid before scale operations
	if not is_instance_valid(self):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "DamageNumber invalid before scale animation")
		return
	
	if is_critical:
		# Critical hits have bounce effect
		var scale_up = scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		if scale_up and is_instance_valid(self):
			var scale_down = scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
			if not scale_down:
				DebugManager.log_warning(DebugManager.DebugCategory.UI, "Scale down tween failed for critical damage")
		else:
			DebugManager.log_warning(DebugManager.DebugCategory.UI, "Scale up tween failed for critical damage")
	else:
		# Normal hits have simple scale-in
		var scale_up = scale_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		if scale_up and is_instance_valid(self):
			var scale_down = scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
			if not scale_down:
				DebugManager.log_warning(DebugManager.DebugCategory.UI, "Scale down tween failed for normal damage")
		else:
			DebugManager.log_warning(DebugManager.DebugCategory.UI, "Scale up tween failed for normal damage")
	
	# Fade out after delay - final validation
	if is_instance_valid(self) and is_instance_valid(tween):
		var fade_tween = tween.tween_property(self, "modulate:a", 0.0, float_duration - fade_start_time).set_delay(fade_start_time)
		if not fade_tween:
			DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create fade tween for damage number")
			call_deferred("queue_free")
			return
		
		# Clean up after animation with safety
		var cleanup_callback = tween.tween_callback(_safe_cleanup).set_delay(float_duration)
		if not cleanup_callback:
			DebugManager.log_warning(DebugManager.DebugCategory.UI, "Failed to create cleanup callback, using fallback")
			call_deferred("queue_free")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Node or tween became invalid before fade setup")
		call_deferred("queue_free")

func _safe_cleanup():
	"""Safely cleanup the damage number node"""
	if is_instance_valid(self):
		queue_free()
	else:
		DebugManager.log_warning(DebugManager.DebugCategory.UI, "DamageNumber already freed during cleanup")

func animate_position(pos: Vector2):
	"""Custom position animation with easing"""
	position = pos
	
	# Add slight wobble for critical hits
	if is_critical:
		var wobble = sin(Engine.get_process_frames() * 0.3) * 2
		position.x += wobble
