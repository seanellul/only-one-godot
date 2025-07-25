extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var title_label = $VBoxContainer/Title
@onready var settings_button = $VBoxContainer/SettingsButton

var audio_settings: AudioSettings

func _ready():
	# Check if save file exists to enable/disable continue button
	update_continue_button()
	
	# Style the title
	var title_font_size = 32
	title_label.add_theme_font_size_override("font_size", title_font_size)
	
	# Create audio settings
	audio_settings = preload("res://scenes/ui/AudioSettings.gd").new()
	add_child(audio_settings)

func update_continue_button():
	"""Enable/disable continue button based on save file existence"""
	continue_button.disabled = not SaveSystem.has_save_file()

func _on_new_game_pressed():
	"""Start a new game"""
	print("MainMenu: Starting new game...")
	SaveSystem.delete_save() # Clear any existing save
	GameManager.start_new_game()

func _on_continue_pressed():
	"""Continue from saved game"""
	if SaveSystem.has_save_file():
		print("MainMenu: Loading saved game...")
		GameManager.load_game()
	else:
		print("MainMenu: No save file found!")

func _on_settings_pressed():
	"""Show audio settings"""
	if audio_settings:
		audio_settings.show_settings()

func _on_quit_pressed():
	"""Quit the game"""
	print("MainMenu: Quitting game...")
	get_tree().quit()