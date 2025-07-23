extends Control

@onready var debug_panel = get_node_or_null("DebugPanel")
@onready var debug_log = get_node_or_null("DebugPanel/VBox/ScrollContainer/DebugLog")
@onready var command_input = get_node_or_null("DebugPanel/VBox/CommandInput")

var is_debug_open = false
var command_history: Array[String] = []
var history_index = -1

func _ready():
	visible = false
	
	# Allow processing when paused so debug console can work
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure we're in the UI layer for proper rendering
	call_deferred("move_to_ui_layer")
	
	if command_input:
		command_input.text_submitted.connect(_on_command_submitted)


func move_to_ui_layer():
	# Try to find the UI CanvasLayer and move there if we're not already
	var ui_layer = get_node_or_null("../UI")
	if ui_layer and ui_layer is CanvasLayer:
		var current_parent = get_parent()
		if current_parent != ui_layer:
			current_parent.remove_child(self)
			ui_layer.add_child(self)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1: # Toggle debug console
				toggle_debug_console()
			KEY_BACKSLASH:
				toggle_debug_console()
			KEY_F2: # Quick spawn coins
				if is_debug_open:
					execute_command("give coin 10")
			KEY_F3: # Quick spawn all items
				if is_debug_open:
					execute_command("give all 5")
			KEY_F4: # Clear inventory
				if is_debug_open:
					execute_command("clear")
			KEY_ESCAPE: # Close debug console
				if is_debug_open:
					toggle_debug_console()

func toggle_debug_console():
	is_debug_open = !is_debug_open
	visible = is_debug_open
	
	if is_debug_open:
		# Ensure we're on top
		if get_parent():
			get_parent().move_child(self, -1) # Move to end (top layer)
		
		get_tree().paused = true
		if command_input:
			command_input.grab_focus()
		log_message("Debug Console Opened - Type 'help' for commands", Color.CYAN)
	else:
		# Only unpause if inventory is not open
		var inventory_ui = get_node_or_null("/root/Room/InventoryUI")
		if not inventory_ui or not inventory_ui.is_open:
			get_tree().paused = false
		if command_input:
			command_input.release_focus()

func _on_command_submitted(command: String):
	if command.strip_edges() != "":
		command_history.append(command)
		history_index = command_history.size()
		execute_command(command)
		command_input.text = ""

func execute_command(command: String):
	var parts = command.strip_edges().split(" ")
	var cmd = parts[0].to_lower()
	
	log_message("> " + command, Color.WHITE)
	
	match cmd:
		"help":
			show_help()
		"give":
			handle_give_command(parts)
		"clear":
			handle_clear_command()
		"status":
			handle_status_command()
		"spawn":
			handle_spawn_command(parts)
		"teleport", "tp":
			handle_teleport_command(parts)
		"speed":
			handle_speed_command(parts)
		"debug":
			handle_debug_command(parts)
		"test":
			handle_test_command(parts)
		"save":
			handle_save_command()
		"load":
			handle_load_command()
		_:
			log_message("Unknown command: " + cmd + ". Type 'help' for available commands.", Color.RED)

func show_help():
	var help_text = """
=== DEBUG CONSOLE COMMANDS ===

INVENTORY:
  give <item> <amount>    - Add items (coin, key, potion, speed, dash)
  give all <amount>       - Give amount of all items
  clear                   - Clear entire inventory
  status                  - Show inventory status

WORLD:
  spawn <item> <x> <y>    - Spawn item at coordinates
  teleport <x> <y>        - Teleport player to coordinates

PLAYER:
  speed <value>           - Set player speed
  upgrade <type>          - Apply upgrade (speed/dash)

DEBUG:
  debug collision         - Toggle collision debug
  debug pickup           - Toggle pickup radius debug
  test performance       - Run performance test
  test collection        - Test collection mechanics

SAVE/LOAD:
  save                   - Save current game state
  load                   - Load saved game state

HOTKEYS:
  F1 - Toggle Console    F2 - Give 10 coins
  F3 - Give 5 of all     F4 - Clear inventory
"""
	log_message(help_text, Color.YELLOW)

func handle_give_command(parts: Array):
	if parts.size() < 3:
		log_message("Usage: give <item> <amount> or give all <amount>", Color.RED)
		return
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	var item_name = parts[1].to_lower()
	var amount = parts[2].to_int()
	
	if amount <= 0:
		log_message("Amount must be positive!", Color.RED)
		return
	
	if item_name == "all":
		for i in range(5):
			inventory_system.add_item(i, amount)
		log_message("Added " + str(amount) + " of all items!", Color.GREEN)
	else:
		var item_types = {
			"coin": 0, "coins": 0,
			"key": 1, "keys": 1,
			"potion": 2, "potions": 2, "health": 2,
			"speed": 3, "speedboost": 3,
			"dash": 4, "dashboost": 4
		}
		
		if item_name in item_types:
			var item_type = item_types[item_name]
			inventory_system.add_item(item_type, amount)
			log_message("Added " + str(amount) + " " + item_name + "(s)!", Color.GREEN)
		else:
			log_message("Unknown item: " + item_name, Color.RED)

func handle_clear_command():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	# Clear all items
	for i in range(5):
		var count = inventory_system.get_item_count(i)
		if count > 0:
			inventory_system.remove_item(i, count)
	
	log_message("Inventory cleared!", Color.GREEN)

func handle_status_command():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	var status_text = """
=== INVENTORY STATUS ===
Gold Coins: %d
Ancient Keys: %d
Health Potions: %d
Speed Boosts: %d
Dash Boosts: %d
Total Value: %d gold
""" % [
		inventory_system.get_item_count(0),
		inventory_system.get_item_count(1),
		inventory_system.get_item_count(2),
		inventory_system.get_item_count(3),
		inventory_system.get_item_count(4),
		inventory_system.get_total_value()
	]
	
	log_message(status_text, Color.CYAN)

func handle_spawn_command(parts: Array):
	if parts.size() < 4:
		log_message("Usage: spawn <item> <x> <y>", Color.RED)
		return
	
	var world_generator = get_node_or_null("../../WorldGenerator")
	if not world_generator:
		log_message("World generator not found!", Color.RED)
		return
	
	var item_name = parts[1].to_lower()
	var x = parts[2].to_int()
	var y = parts[3].to_int()
	
	# Spawn item at coordinates
	world_generator.create_collectible_item(x, y)
	log_message("Spawned " + item_name + " at (" + str(x) + ", " + str(y) + ")", Color.GREEN)

func handle_teleport_command(parts: Array):
	if parts.size() < 3:
		log_message("Usage: teleport <x> <y>", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	var x = parts[1].to_float()
	var y = parts[2].to_float()
	
	player.global_position = Vector2(x, y)
	log_message("Teleported to (" + str(x) + ", " + str(y) + ")", Color.GREEN)

func handle_speed_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: speed <value>", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	var new_speed = parts[1].to_float()
	if "SPEED" in player:
		player.SPEED = new_speed
		log_message("Player speed set to: " + str(new_speed), Color.GREEN)
	else:
		log_message("Cannot modify player speed!", Color.RED)

func handle_debug_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: debug <collision|pickup>", Color.RED)
		return
	
	var debug_type = parts[1].to_lower()
	
	match debug_type:
		"collision":
			get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint
			log_message("Collision debug: " + ("ON" if get_tree().debug_collisions_hint else "OFF"), Color.GREEN)
		"pickup":
			# Toggle pickup radius visualization
			log_message("Pickup radius debug toggled", Color.GREEN)
		_:
			log_message("Unknown debug type: " + debug_type, Color.RED)

func handle_test_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: test <performance|collection>", Color.RED)
		return
	
	var test_type = parts[1].to_lower()
	
	match test_type:
		"performance":
			run_performance_test()
		"collection":
			run_collection_test()
		_:
			log_message("Unknown test type: " + test_type, Color.RED)

func run_performance_test():
	log_message("Running performance test...", Color.YELLOW)
	
	# Simulate rapid item collection
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		for i in range(100):
			inventory_system.add_item(0, 1) # Add 100 coins
	
	log_message("Performance test completed - Added 100 items", Color.GREEN)

func run_collection_test():
	log_message("Running collection test...", Color.YELLOW)
	
	# Test all item types
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		for i in range(5):
			inventory_system.add_item(i, 1)
		log_message("Collection test completed - Added 1 of each item type", Color.GREEN)

func handle_save_command():
	# Simple save functionality
	log_message("Save functionality not implemented yet", Color.YELLOW)

func handle_load_command():
	# Simple load functionality
	log_message("Load functionality not implemented yet", Color.YELLOW)

func log_message(message: String, color: Color = Color.WHITE):
	if not debug_log:
		return
	
	var label = RichTextLabel.new()
	label.fit_content = true
	label.bbcode_enabled = true
	label.append_text("[color=" + color.to_html() + "]" + message + "[/color]")
	debug_log.add_child(label)
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll_container = debug_log.get_parent()
	if scroll_container is ScrollContainer:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
