extends Control

# Game Over Screen with death animation and restart functionality
class_name GameOverScreen

# UI Elements
var background_overlay: ColorRect
var game_over_label: Label
var death_message: Label
var restart_button: Button
var quit_button: Button
var death_timer: Timer

# Animation control
var is_showing: bool = false
var blackout_tween: Tween

signal restart_game()
signal quit_game()

func _ready():
	# Set up as fullscreen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	
	# Ensure this is on top
	process_mode = Node.PROCESS_MODE_ALWAYS # Continue processing when game is paused
	
	create_ui_elements()
	connect_signals()

func create_ui_elements():
	"""Create all the UI elements for the game over screen"""
	
	# Background overlay (starts transparent)
	background_overlay = ColorRect.new()
	background_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_overlay.color = Color(0, 0, 0, 0) # Start transparent
	add_child(background_overlay)
	
	# Game Over title
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 72)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_label.size = Vector2(600, 100)
	game_over_label.position = Vector2(-300, -150)
	game_over_label.modulate.a = 0 # Start invisible
	add_child(game_over_label)
	
	# Death message
	death_message = Label.new()
	death_message.text = "You have fallen in battle..."
	death_message.add_theme_font_size_override("font_size", 24)
	death_message.add_theme_color_override("font_color", Color.WHITE)
	death_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	death_message.size = Vector2(400, 50)
	death_message.position = Vector2(-200, -50)
	death_message.modulate.a = 0 # Start invisible
	add_child(death_message)
	
	# Restart button
	restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.add_theme_font_size_override("font_size", 20)
	restart_button.size = Vector2(200, 50)
	restart_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	restart_button.position = Vector2(-100, 50)
	restart_button.modulate.a = 0 # Start invisible
	add_child(restart_button)
	
	# Quit button
	quit_button = Button.new()
	quit_button.text = "Quit to Menu"
	quit_button.add_theme_font_size_override("font_size", 20)
	quit_button.size = Vector2(200, 50)
	quit_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	quit_button.position = Vector2(-100, 120)
	quit_button.modulate.a = 0 # Start invisible
	add_child(quit_button)

func connect_signals():
	"""Connect button signals"""
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_game_over():
	"""Show the game over screen with full animation sequence"""
	if is_showing:
		return
	
	is_showing = true
	visible = true
	
	print("GameOverScreen: Starting death sequence...")
	
	# Pause the game
	get_tree().paused = true
	
	# Start the death animation sequence
	start_death_sequence()

func start_death_sequence():
	"""Start the complete death animation sequence"""
	
	# Phase 1: Wait for death animation to play (2 seconds)
	await get_tree().create_timer(1.5).timeout
	
	# Phase 2: Begin blackout
	print("GameOverScreen: Beginning blackout...")
	blackout_tween = create_tween()
	blackout_tween.tween_property(background_overlay, "color:a", 1.0, 1.5) # Fade to black
	await blackout_tween.finished
	
	# Phase 3: Show "GAME OVER" text
	print("GameOverScreen: Showing Game Over text...")
	var title_tween = create_tween()
	title_tween.tween_property(game_over_label, "modulate:a", 1.0, 1.0)
	await title_tween.finished
	
	# Phase 4: Show death message
	await get_tree().create_timer(0.5).timeout
	var message_tween = create_tween()
	message_tween.tween_property(death_message, "modulate:a", 1.0, 0.8)
	await message_tween.finished
	
	# Phase 5: Show buttons
	await get_tree().create_timer(0.5).timeout
	var button_tween = create_tween()
	button_tween.set_parallel(true)
	button_tween.tween_property(restart_button, "modulate:a", 1.0, 0.6)
	button_tween.tween_property(quit_button, "modulate:a", 1.0, 0.6)
	
	# Enable input
	restart_button.disabled = false
	quit_button.disabled = false
	
	print("GameOverScreen: Death sequence complete")

func _on_restart_pressed():
	"""Handle restart button press"""
	print("GameOverScreen: Restart button pressed")
	hide_game_over()
	restart_game.emit()

func _on_quit_pressed():
	"""Handle quit button press"""
	print("GameOverScreen: Quit button pressed")
	hide_game_over()
	quit_game.emit()

func hide_game_over():
	"""Hide the game over screen and reset state"""
	is_showing = false
	visible = false
	
	# Reset all elements to invisible
	background_overlay.color.a = 0
	game_over_label.modulate.a = 0
	death_message.modulate.a = 0
	restart_button.modulate.a = 0
	quit_button.modulate.a = 0
	
	# Disable buttons
	restart_button.disabled = true
	quit_button.disabled = true
	
	# Unpause the game
	get_tree().paused = false
	
	print("GameOverScreen: Hidden and reset")

func _input(event):
	"""Handle input during game over screen"""
	if not is_showing:
		return
	
	# Allow restart with Enter/Space
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if not restart_button.disabled:
			_on_restart_pressed()
	
	# Allow quit with Escape
	if event.is_action_pressed("ui_cancel"):
		if not quit_button.disabled:
			_on_quit_pressed()

func set_death_message(message: String):
	"""Set a custom death message"""
	if death_message:
		death_message.text = message

func get_death_stats() -> Dictionary:
	"""Get statistics about the player's death for display"""
	# This could be expanded to show stats like enemies killed, time survived, etc.
	return {
		"enemies_killed": 0, # TODO: Track this
		"time_survived": 0, # TODO: Track this
		"gold_collected": 0 # TODO: Track this
	}