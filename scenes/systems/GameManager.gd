extends Node

signal player_died
signal game_saved
signal game_loaded

const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"
const GAME_SCENE = "res://scenes/rooms/Room.tscn"
const INTRO_CUTSCENE_SCENE = "res://scenes/cutscenes/IntroductionCutscene.tscn"

var current_scene: Node
var is_in_main_menu: bool = true
var game_paused: bool = false

func _ready():
	# Connect to tree change events
	get_tree().node_added.connect(_on_node_added)
	
	# Handle input for ESC key
	set_process_input(true)

func _input(event):
	"""Handle global input events"""
	if event.is_action_pressed("ui_cancel"): # ESC key
		handle_escape_key()

func handle_escape_key():
	"""Handle ESC key press based on current state"""
	if is_in_main_menu:
		# In main menu, quit game
		get_tree().quit()
	else:
		# In game, save and return to main menu
		print("GameManager: ESC pressed - saving and returning to main menu")
		save_and_return_to_menu()

func start_new_game():
	"""Start a new game session with intro cutscene"""
	print("GameManager: Starting new game with intro cutscene...")
	is_in_main_menu = false
	
	# Clear any existing save
	SaveSystem.delete_save()
	
	# Show intro cutscene first
	show_intro_cutscene()

func show_intro_cutscene():
	"""Show the introduction cutscene"""
	print("GameManager: Loading intro cutscene...")
	change_scene_to_file(INTRO_CUTSCENE_SCENE)

func start_game_after_cutscene():
	"""Start the actual game after cutscene completion"""
	print("GameManager: Cutscene finished, starting game...")
	change_scene_to_file(GAME_SCENE)

func load_game():
	"""Load an existing game session"""
	print("GameManager: Loading game...")
	is_in_main_menu = false
	
	# Load save data
	var save_data = SaveSystem.load_game()
	if save_data.is_empty():
		print("GameManager: Failed to load save data, starting new game")
		start_new_game()
		return
	
	# Load game scene
	change_scene_to_file(GAME_SCENE)
	
	# Apply save data after scene loads
	await get_tree().process_frame
	await get_tree().process_frame # Wait two frames to ensure scene is ready
	SaveSystem.apply_game_state(save_data)
	
	game_loaded.emit()

func save_and_return_to_menu():
	"""Save current game state and return to main menu"""
	print("GameManager: Saving game and returning to menu...")
	
	# Save game state
	if SaveSystem.save_game():
		game_saved.emit()
	
	# Return to main menu
	return_to_main_menu()

func return_to_main_menu():
	"""Return to main menu without saving"""
	print("GameManager: Returning to main menu...")
	is_in_main_menu = true
	change_scene_to_file(MAIN_MENU_SCENE)

func handle_player_death():
	"""Handle player death - delete save and return to menu"""
	print("GameManager: Player died - deleting save and returning to menu")
	
	# Delete save file
	SaveSystem.delete_save()
	
	# Return to main menu
	return_to_main_menu()
	
	player_died.emit()

func change_scene_to_file(scene_path: String):
	"""Change to a new scene"""
	print("GameManager: Changing scene to ", scene_path)
	
	# Call deferred to avoid issues with current frame
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String):
	"""Deferred scene change to avoid frame issues"""
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("GameManager: Failed to change scene to ", scene_path)

func _on_node_added(node: Node):
	"""Handle when nodes are added to the scene tree"""
	# Check if player was added and connect to death signal
	if node.name == "Player" or node.is_in_group("player"):
		connect_player_signals(node)
	
	# Check if intro cutscene was added and connect to its signal
	elif node.name == "IntroductionCutscene":
		connect_cutscene_signals(node)

func connect_player_signals(player: Node):
	"""Connect to player signals for death detection"""
	# Try different signal names that might indicate death
	var death_signals = ["died", "death", "player_died", "health_depleted"]
	
	for signal_name in death_signals:
		if player.has_signal(signal_name):
			if not player.is_connected(signal_name, handle_player_death):
				player.connect(signal_name, handle_player_death)
				print("GameManager: Connected to player death signal: ", signal_name)
			break

func connect_cutscene_signals(cutscene: Node):
	"""Connect to cutscene signals"""
	if cutscene.has_signal("intro_finished"):
		if not cutscene.is_connected("intro_finished", _on_intro_cutscene_finished):
			cutscene.connect("intro_finished", _on_intro_cutscene_finished)
			print("GameManager: Connected to cutscene intro_finished signal")

func _on_intro_cutscene_finished():
	"""Handle when the intro cutscene finishes"""
	print("GameManager: Intro cutscene finished, starting game...")
	start_game_after_cutscene()

func quit_game():
	"""Quit the entire application"""
	print("GameManager: Quitting game...")
	
	# Save if currently in game
	if not is_in_main_menu:
		SaveSystem.save_game()
	
	get_tree().quit()

func auto_save():
	"""Perform an automatic save"""
	if not is_in_main_menu:
		print("GameManager: Auto-saving...")
		SaveSystem.save_game()

# Called when the application is about to quit
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Auto-save before quitting if in game
		if not is_in_main_menu:
			SaveSystem.save_game()
		get_tree().quit()
