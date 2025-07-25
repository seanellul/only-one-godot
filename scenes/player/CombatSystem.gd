extends Node

# Combat stats
var max_health: int = 100
var current_health: int = 100
var damage: int = 25
var is_attacking: bool = false
var is_dead: bool = false
var attack_cooldown: float = 0.0
var attack_cooldown_time: float = 0.5

# Attack range and duration
var attack_range: float = 40.0
var attack_duration: float = 0.86 # 19 frames ÷ 22 FPS = ~0.86 seconds
var attack_timer: float = 0.0

# Signals for combat events
signal health_changed(new_health: int, max_health: int)
signal player_died()
signal attack_started()
signal attack_finished()
signal damage_dealt(target, damage_amount: int)

# References
var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var combat_feedback: CombatFeedback

func _ready():
	player = get_parent()
	animated_sprite = player.get_node("AnimatedSprite2D")
	
	# Debug: Check if we found the animated sprite
	if animated_sprite:
		print("Combat: Successfully found AnimatedSprite2D")
	else:
		print("Combat: ERROR - Could not find AnimatedSprite2D!")
	
	# Initialize combat feedback system
	combat_feedback = preload("res://scenes/systems/CombatFeedback.gd").new()
	add_child(combat_feedback)
	
	# Connect to health changes for UI updates
	health_changed.connect(_on_health_changed)
	player_died.connect(_on_player_died)

func _process(delta):
	# Handle attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Handle attack duration (backup timer in case animation signal fails)
	if is_attacking and attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			print("Combat: Attack timer expired - ending attack (backup)")
			end_attack()

func _input(event):
	if is_dead:
		return
		
	# Left click to attack
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if can_attack():
			start_attack()

func can_attack() -> bool:
	return not is_attacking and not is_dead and attack_cooldown <= 0

func start_attack():
	if not can_attack():
		return
		
	is_attacking = true
	
	# Calculate actual attack duration from animation
	if animated_sprite and animated_sprite.sprite_frames:
		var frame_count = animated_sprite.sprite_frames.get_frame_count("attack")
		var fps = animated_sprite.sprite_frames.get_animation_speed("attack")
		attack_duration = float(frame_count) / fps
		print("Combat: Calculated attack duration: ", attack_duration, "s (", frame_count, " frames ÷ ", fps, " FPS)")
	
	attack_timer = attack_duration
	attack_cooldown = attack_cooldown_time
	
	# Play attack animation
	if animated_sprite:
		print("Combat: Playing attack animation (", animated_sprite.sprite_frames.get_frame_count("attack"), " frames at ", animated_sprite.sprite_frames.get_animation_speed("attack"), " FPS)")
		animated_sprite.play("attack")
		# Disconnect any existing connection first, then connect fresh
		if animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)
		animated_sprite.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	else:
		print("Combat: Warning - No animated_sprite found!")
	
	# Create attack hitbox
	create_attack_hitbox()
	
	attack_started.emit()
	print("Combat: Player attack started - Damage: ", damage)

func end_attack():
	if not is_attacking:
		return # Already ended, don't call multiple times
		
	is_attacking = false
	attack_timer = 0.0
	
	# Return to appropriate animation
	if animated_sprite and not is_dead:
		if player.velocity.length() > 10:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")
	
	attack_finished.emit()
	print("Combat: Player attack finished")

func _on_attack_animation_finished():
	# Animation finished - end attack immediately for responsive feel
	if is_attacking:
		print("Combat: Attack animation finished - ending attack")
		end_attack()

func create_attack_hitbox():
	# Get attack direction (towards mouse or player facing direction)
	var attack_direction = get_attack_direction()
	
	# Calculate relative position from player center
	var relative_position = attack_direction * (attack_range * 0.5)
	
	# Create hitbox using the AttackHitbox scene
	var hitbox_scene = preload("res://scenes/combat/AttackHitbox.tscn")
	var hitbox = hitbox_scene.instantiate()
	
	# Add hitbox as child of player so it follows player movement
	player.add_child(hitbox)
	
	# Setup hitbox with relative position, size, damage, etc.
	hitbox.setup_hitbox_relative(relative_position, Vector2(attack_range, attack_range * 0.6), damage, attack_duration, "player")
	
	print("Combat: Created attack hitbox at relative position ", relative_position, " with damage ", damage)

func get_attack_direction() -> Vector2:
	# Get direction towards mouse position
	var mouse_pos = player.get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()
	
	# If no mouse movement, use sprite facing direction
	if direction.length() < 0.1:
		direction = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
	
	return direction

func take_damage(amount: int, _source = null):
	if is_dead:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	print("Combat: Player took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Combat feedback for player damage
	if combat_feedback:
		combat_feedback.player_hit(amount, player.global_position + Vector2(0, -20))
	
	# Check for death
	if current_health <= 0:
		die()

func heal(amount: int):
	if is_dead:
		return
		
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	
	print("Combat: Player healed ", amount, " health. Health: ", current_health, "/", max_health)

func die():
	if is_dead:
		return
		
	is_dead = true
	is_attacking = false
	
	print("Combat: Player died - starting death sequence")
	
	# Play death sound effect (safely check if AudioManager exists)
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_method("play_death_sound"):
		audio_manager.play_death_sound()
	else:
		print("CombatSystem: AudioManager not available for death sound (disabled for crash testing)")
	
	# Disable player input
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Play death animation
	if animated_sprite:
		print("Combat: Playing death animation")
		animated_sprite.play("death")
		# Connect to animation finished to trigger game over screen
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
	else:
		# If no animation, show game over immediately
		call_deferred("show_game_over_screen")
	
	player_died.emit()

func _on_death_animation_finished():
	"""Called when death animation finishes"""
	print("Combat: Death animation finished - showing game over")
	show_game_over_screen()

func show_game_over_screen():
	"""Show the game over screen"""
	var game_over_screen = get_tree().get_first_node_in_group("game_over_screen")
	
	if not game_over_screen:
		# Create game over screen if it doesn't exist
		var game_over_scene = preload("res://scenes/ui/GameOverScreen.tscn")
		game_over_screen = game_over_scene.instantiate()
		game_over_screen.add_to_group("game_over_screen")
		
		# Connect restart signal
		game_over_screen.restart_game.connect(_on_restart_game)
		game_over_screen.quit_game.connect(_on_quit_game)
		
		# Add to UI layer
		var ui_layer = get_tree().get_first_node_in_group("ui_layer")
		if ui_layer:
			ui_layer.add_child(game_over_screen)
		else:
			# Fallback: add to current scene
			get_tree().current_scene.add_child(game_over_screen)
	
	# Show the game over screen
	game_over_screen.show_game_over()

func _on_restart_game():
	"""Handle game restart"""
	print("Combat: Restarting game...")
	
	# Revive player
	revive(true) # Full health
	
	# Re-enable player
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	
	# Return to town (safe area)
	var world_manager = get_tree().current_scene.get_node_or_null("WorldSystemManager")
	if world_manager and world_manager.has_method("debug_return_to_town"):
		world_manager.debug_return_to_town()
	
	print("Combat: Game restarted")

func _on_quit_game():
	"""Handle quit to menu"""
	print("Combat: Quitting to menu...")
	
	# For now, just restart the scene
	# In a full game, this would return to a main menu
	get_tree().reload_current_scene()

func revive(full_health: bool = false):
	is_dead = false
	current_health = max_health if full_health else max(1, max_health / 4.0)
	
	# Return to idle animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	health_changed.emit(current_health, max_health)
	print("Combat: Player revived with ", current_health, " health")

func _on_health_changed(_new_health: int, _max_hp: int):
	# This can be connected to UI elements
	pass

func _on_player_died():
	# Handle death effects (could disable input, show death screen, etc.)
	pass

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func get_combat_stats() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"damage": damage,
		"is_attacking": is_attacking,
		"is_dead": is_dead,
		"can_attack": can_attack()
	}

# Save/Load functionality for SaveSystem
func get_save_data() -> Dictionary:
	"""Get data for saving"""
	return {
		"current_health": current_health,
		"max_health": max_health,
		"damage": damage
	}

func load_save_data(data: Dictionary):
	"""Load data from save"""
	current_health = data.get("current_health", 100)
	max_health = data.get("max_health", 100)
	damage = data.get("damage", 25)
	is_dead = false # Always alive when loading
	
	# Update UI
	health_changed.emit(current_health, max_health)
	print("Combat: Loaded save data - Health: ", current_health, "/", max_health)

func set_health(new_health: int):
	"""Set health (used by SaveSystem)"""
	current_health = clamp(new_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func set_max_health(new_max_health: int):
	"""Set max health (used by SaveSystem)"""
	max_health = new_max_health
	if current_health > max_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)

func set_damage(new_damage: int):
	"""Set damage (used by SaveSystem)"""
	damage = new_damage
	print("Combat: Damage set to ", damage)
