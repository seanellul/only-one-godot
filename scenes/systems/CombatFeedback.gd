extends Node

# Combat feedback system for enhanced player experience
class_name CombatFeedback

# Screen shake settings
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_frequency: float = 30.0
var original_camera_position: Vector2

# Hit-stop settings
var hitstop_duration: float = 0.0
var original_time_scale: float = 1.0

# Damage number settings
var damage_number_scene = preload("res://scenes/systems/DamageNumber.tscn")

# References
var camera: Camera2D
var main_scene_tree: SceneTree

func _ready():
	# Get references
	main_scene_tree = get_tree()
	
	# Find camera (will be set when player is available)
	call_deferred("find_camera")

func find_camera():
	"""Find the main camera in the scene"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node_or_null("Camera2D")
		if camera:
			original_camera_position = camera.position
			print("CombatFeedback: Camera found and ready")

func _process(delta):
	# Handle screen shake
	if shake_duration > 0:
		process_screen_shake(delta)
	
	# Handle hit-stop
	if hitstop_duration > 0:
		process_hit_stop(delta)

func process_screen_shake(delta):
	"""Process screen shake effect"""
	if not camera:
		find_camera()
		return
		
	shake_duration -= delta
	
	if shake_duration <= 0:
		# End shake
		camera.position = original_camera_position
		shake_intensity = 0
	else:
		# Calculate shake offset
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		camera.position = original_camera_position + shake_offset

func process_hit_stop(delta):
	"""Process hit-stop (time freeze) effect"""
	hitstop_duration -= delta
	
	if hitstop_duration <= 0:
		# Restore normal time
		Engine.time_scale = original_time_scale
		print("CombatFeedback: Hit-stop ended")

func create_damage_number(position: Vector2, damage: int, is_critical: bool = false, is_player_damage: bool = false):
	"""Create floating damage number at specified position"""
	if not damage_number_scene:
		print("CombatFeedback: No damage number scene available")
		return
		
	var damage_number = damage_number_scene.instantiate()
	
	# Configure damage number
	if damage_number.has_method("setup"):
		damage_number.setup(damage, is_critical, is_player_damage)
	
	# Add to scene
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(damage_number)
		damage_number.global_position = position
		print("CombatFeedback: Damage number created: ", damage, " at ", position)

func screen_shake(intensity: float, duration: float, frequency: float = 30.0):
	"""Trigger screen shake effect"""
	if not camera:
		find_camera()
		if not camera:
			return
			
	shake_intensity = intensity
	shake_duration = duration
	shake_frequency = frequency
	original_camera_position = camera.position
	
	print("CombatFeedback: Screen shake - Intensity: ", intensity, " Duration: ", duration)

func hit_stop(duration: float):
	"""Trigger hit-stop (brief time freeze) effect"""
	if duration <= 0:
		return
		
	hitstop_duration = duration
	original_time_scale = Engine.time_scale
	Engine.time_scale = 0.05 # Very slow motion effect
	
	print("CombatFeedback: Hit-stop triggered for ", duration, " seconds")

func create_hit_particles(position: Vector2, direction: Vector2, intensity: float = 1.0):
	"""Create impact particles at hit location"""
	var particles = create_particle_system()
	
	# Configure particles
	particles.position = position
	particles.amount = int(20 * intensity)
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	
	# Set emission direction based on hit direction
	particles.process_material.direction = Vector3(direction.x, direction.y, 0)
	particles.process_material.initial_velocity_min = 50.0 * intensity
	particles.process_material.initial_velocity_max = 100.0 * intensity
	
	# Add to scene
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(particles)
		particles.emitting = true
		
		# Auto-remove after emission
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(particles.queue_free)
		particles.add_child(timer)
		timer.start()

func create_particle_system() -> CPUParticles2D:
	"""Create a configured particle system for combat effects"""
	var particles = CPUParticles2D.new()
	
	# Basic settings
	particles.emitting = false
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	
	# Appearance
	particles.texture = create_particle_texture()
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	
	# Movement
	particles.direction = Vector2(1, 0)
	particles.spread = 45.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2(0, 98)
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	
	# Color animation
	particles.color = Color.WHITE
	particles.color_ramp = create_color_ramp()
	
	return particles

func create_particle_texture() -> ImageTexture:
	"""Create a simple circular texture for particles"""
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	# Draw a white circle
	for x in range(8):
		for y in range(8):
			var distance = Vector2(x - 4, y - 4).length()
			if distance <= 3:
				var alpha = 1.0 - (distance / 3.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	return texture

func create_color_ramp() -> Gradient:
	"""Create color gradient for particle fade effect"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.8, 1)) # Bright start
	gradient.add_point(0.7, Color(1, 0.5, 0.2, 0.8)) # Orange middle
	gradient.add_point(1.0, Color(0.5, 0.2, 0.2, 0)) # Dark fade
	return gradient

# Convenience methods for common effects
func player_hit(damage: int, hit_position: Vector2):
	"""Player takes damage - strong feedback"""
	screen_shake(8.0, 0.3)
	hit_stop(0.1)
	create_damage_number(hit_position, damage, false, true)
	create_hit_particles(hit_position, Vector2.UP, 1.5)

func enemy_hit(damage: int, hit_position: Vector2, is_critical: bool = false):
	"""Enemy takes damage - moderate feedback"""
	var shake_intensity = 3.0 if not is_critical else 5.0
	var stop_duration = 0.05 if not is_critical else 0.08
	
	screen_shake(shake_intensity, 0.15)
	hit_stop(stop_duration)
	create_damage_number(hit_position, damage, is_critical, false)
	create_hit_particles(hit_position, Vector2.DOWN, 1.0)

func light_hit(damage: int, hit_position: Vector2):
	"""Light attack - subtle feedback"""
	screen_shake(1.5, 0.1)
	create_damage_number(hit_position, damage, false, false)
	create_hit_particles(hit_position, Vector2.RIGHT, 0.7)
