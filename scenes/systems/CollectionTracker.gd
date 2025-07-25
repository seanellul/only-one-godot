extends Node

# Collection statistics
var total_items_collected = 0
var items_by_type = {}
var collection_milestones = [10, 25, 50, 100, 200, 500]
var milestones_reached = []

# Achievement tracking
var achievements = {
	"first_coin": {"name": "First Gold", "desc": "Collect your first coin", "unlocked": false},
	"coin_collector": {"name": "Coin Collector", "desc": "Collect 50 coins", "unlocked": false},
	"key_master": {"name": "Key Master", "desc": "Collect 10 keys", "unlocked": false},
	"speed_demon": {"name": "Speed Demon", "desc": "Use 5 speed boosts", "unlocked": false},
	"dash_expert": {"name": "Dash Expert", "desc": "Use 5 dash boosts", "unlocked": false},
	"completionist": {"name": "Completionist", "desc": "Collect 100 of any item type", "unlocked": false},
	"ultimate_champion": {"name": "Ultimate Champion", "desc": "Master of Bubakra - Fulfill the ancient prophecy", "unlocked": false}
}

# Victory conditions
var victory_requirements = {
	"total_items": 500, # Collect 500 total items
	"achievements": 6, # Unlock 6 out of 7 achievements
	"coins": 200, # Collect 200 coins
	"keys": 20 # Collect 20 keys
}

var has_won_game: bool = false
var game_start_time: float = 0.0

signal achievement_unlocked(achievement_name: String, achievement_data: Dictionary)
signal milestone_reached(milestone: int, total_collected: int)
signal game_won(victory_stats: Dictionary)

func _ready():
	# Record game start time
	game_start_time = Time.get_unix_time_from_system()
	
	# Initialize type tracking
	for i in range(5): # 5 item types
		items_by_type[i] = 0
	
	# Connect to inventory system
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.item_collected.connect(_on_item_collected)

func _on_item_collected(item_type: int, amount: int):
	# Update statistics
	total_items_collected += amount
	if item_type in items_by_type:
		items_by_type[item_type] += amount
	
	# Check for achievements
	check_achievements(item_type)
	
	# Check for milestones
	check_milestones()
	
	# Check for victory conditions
	check_victory_conditions()
	
	# Log collection info
	print_collection_stats()

func check_achievements(item_type: int):
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# First coin achievement
	if item_type == 0 and not achievements["first_coin"]["unlocked"]:
		unlock_achievement("first_coin")
	
	# Coin collector achievement
	if inventory_system.get_item_count(0) >= 50 and not achievements["coin_collector"]["unlocked"]:
		unlock_achievement("coin_collector")
	
	# Key master achievement
	if inventory_system.get_item_count(1) >= 10 and not achievements["key_master"]["unlocked"]:
		unlock_achievement("key_master")
	
	# Usage-based achievements (tracked separately)
	# These would be triggered by the upgrade system
	
	# Completionist achievement
	for i in range(5):
		if inventory_system.get_item_count(i) >= 100 and not achievements["completionist"]["unlocked"]:
			unlock_achievement("completionist")
			break

func check_milestones():
	for milestone in collection_milestones:
		if total_items_collected >= milestone and milestone not in milestones_reached:
			milestones_reached.append(milestone)
			milestone_reached.emit(milestone, total_items_collected)
			print("🎉 Milestone Reached: ", milestone, " total items collected!")

func unlock_achievement(achievement_key: String):
	if achievement_key in achievements and not achievements[achievement_key]["unlocked"]:
		achievements[achievement_key]["unlocked"] = true
		var achievement_data = achievements[achievement_key]
		achievement_unlocked.emit(achievement_key, achievement_data)
		print("🏆 Achievement Unlocked: ", achievement_data["name"], " - ", achievement_data["desc"])
		
		# Check victory after unlocking achievement
		check_victory_conditions()

func check_victory_conditions():
	"""Check if the player has met all victory requirements"""
	if has_won_game:
		return # Already won
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# Check all victory requirements
	var total_items_met = total_items_collected >= victory_requirements.total_items
	var coins_met = inventory_system.get_item_count(0) >= victory_requirements.coins
	var keys_met = inventory_system.get_item_count(1) >= victory_requirements.keys
	var achievements_met = get_unlocked_achievements().size() >= victory_requirements.achievements
	
	# Debug victory progress
	if total_items_collected % 50 == 0 and total_items_collected > 0: # Every 50 items
		print("🎯 Victory Progress:")
		print("  Total Items: ", total_items_collected, "/", victory_requirements.total_items)
		print("  Coins: ", inventory_system.get_item_count(0), "/", victory_requirements.coins)
		print("  Keys: ", inventory_system.get_item_count(1), "/", victory_requirements.keys)
		print("  Achievements: ", get_unlocked_achievements().size(), "/", victory_requirements.achievements)
	
	# Check if all conditions are met
	if total_items_met and coins_met and keys_met and achievements_met:
		trigger_victory()

func trigger_victory():
	"""Trigger the game victory sequence"""
	if has_won_game:
		return
		
	has_won_game = true
	
	# Unlock the ultimate achievement
	unlock_achievement("ultimate_champion")
	
	# Play victory sound (safely check if AudioManager exists)
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_method("play_victory_sound"):
		audio_manager.play_victory_sound()
		DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Victory sound played")
	else:
		DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "AudioManager not available for victory sound (disabled for crash testing)")
	
	# Create victory stats
	var victory_stats = get_collection_stats()
	victory_stats["victory_time"] = get_elapsed_time()
	
	# Emit victory signal
	game_won.emit(victory_stats)
	
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "🎉🏆 VICTORY! Player has fulfilled the ancient prophecy and saved Bubakra!")
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "🎯 Final Stats:")
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "  Total Items Collected: " + str(total_items_collected))
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "  Achievements Unlocked: " + str(get_unlocked_achievements().size()) + "/" + str(achievements.size()))
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "  Time Played: " + str(victory_stats.victory_time) + " seconds")
	
	# Show victory screen
	call_deferred("show_victory_screen")

func show_victory_screen():
	"""Display the victory screen"""
	# Create a simple victory notification for now
	var victory_label = Label.new()
	victory_label.text = "🎉 VICTORY! 🎉\nYou have saved Bubakra!\nPress ESC to return to Main Menu"
	victory_label.add_theme_font_size_override("font_size", 24)
	victory_label.add_theme_color_override("font_color", Color.GOLD)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var victory_screen = Control.new()
	victory_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_screen.add_child(bg)
	victory_screen.add_child(victory_label)
	
	# Add to scene
	var current_scene = get_tree().current_scene
	if DebugManager.safe_add_child(current_scene, victory_screen, "CollectionTracker victory screen"):
		DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "Victory screen displayed successfully")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.SYSTEM, "Failed to display victory screen")
	
	# Auto-save the victory
	if SaveSystem:
		SaveSystem.save_game()

func get_collection_stats() -> Dictionary:
	return {
		"total_collected": total_items_collected,
		"by_type": items_by_type.duplicate(),
		"milestones_reached": milestones_reached.duplicate(),
		"achievements_unlocked": get_unlocked_achievements(),
		"completion_percentage": calculate_completion_percentage()
	}

func get_unlocked_achievements() -> Array:
	var unlocked = []
	for key in achievements:
		if achievements[key]["unlocked"]:
			unlocked.append({
				"key": key,
				"name": achievements[key]["name"],
				"desc": achievements[key]["desc"]
			})
	return unlocked

func calculate_completion_percentage() -> float:
	var unlocked_count = 0
	for key in achievements:
		if achievements[key]["unlocked"]:
			unlocked_count += 1
	
	return (float(unlocked_count) / float(achievements.size())) * 100.0

func print_collection_stats():
	print("\n=== COLLECTION STATS ===")
	print("Total Items: ", total_items_collected)
	var item_names = ["Coins", "Keys", "Potions", "Speed Boosts", "Dash Boosts"]
	for i in range(5):
		if i < item_names.size():
			print(item_names[i], ": ", items_by_type.get(i, 0))
	print("Achievements: ", get_unlocked_achievements().size(), "/", achievements.size())
	print("Completion: ", "%.1f" % calculate_completion_percentage(), "%")

# Method for upgrade system to call when items are used
func on_item_used(item_type: int, _amount: int = 1):
	match item_type:
		3: # Speed boost used
			var inventory_system = get_node_or_null("/root/InventorySystem")
			if inventory_system:
				# Check if this was the 5th speed boost ever used
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_node("PlayerUpgrades"):
					var upgrades_node = player.get_node("PlayerUpgrades")
					if upgrades_node.speed_boosts_applied >= 5 and not achievements["speed_demon"]["unlocked"]:
						unlock_achievement("speed_demon")
		
		4: # Dash boost used
			var inventory_system = get_node_or_null("/root/InventorySystem")
			if inventory_system:
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_node("PlayerUpgrades"):
					var upgrades_node = player.get_node("PlayerUpgrades")
					if upgrades_node.dash_boosts_applied >= 5 and not achievements["dash_expert"]["unlocked"]:
						unlock_achievement("dash_expert")

# Save/Load functionality for SaveSystem
func get_save_data() -> Dictionary:
	"""Get collection data for saving"""
	var save_data = {
		"total_items_collected": total_items_collected,
		"items_by_type": items_by_type.duplicate(),
		"milestones_reached": milestones_reached.duplicate(),
		"achievements": {}
	}
	
	# Save achievement states
	for key in achievements:
		save_data.achievements[key] = achievements[key].unlocked
	
	print("CollectionTracker: Saving collection data: ", save_data)
	return save_data

func load_save_data(data: Dictionary):
	"""Load collection data from save"""
	if data.is_empty():
		print("CollectionTracker: No collection data to load")
		return
	
	print("CollectionTracker: Loading collection data: ", data)
	
	# Load collection stats
	total_items_collected = data.get("total_items_collected", 0)
	items_by_type = data.get("items_by_type", {})
	milestones_reached = data.get("milestones_reached", [])
	
	# Load achievement states
	var saved_achievements = data.get("achievements", {})
	for key in achievements:
		if key in saved_achievements:
			achievements[key].unlocked = saved_achievements[key]
	
	print("CollectionTracker: Collection data loaded - Total: ", total_items_collected, " Achievements: ", get_unlocked_achievements().size())

func get_elapsed_time() -> float:
	"""Get time elapsed since game start"""
	return Time.get_unix_time_from_system() - game_start_time
