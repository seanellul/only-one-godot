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
	"completionist": {"name": "Completionist", "desc": "Collect 100 of any item type", "unlocked": false}
}

signal achievement_unlocked(achievement_name: String, achievement_data: Dictionary)
signal milestone_reached(milestone: int, total_collected: int)

func _ready():
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
					var upgrades = player.get_node("PlayerUpgrades")
					if upgrades.speed_boosts_applied >= 5 and not achievements["speed_demon"]["unlocked"]:
						unlock_achievement("speed_demon")
		
		4: # Dash boost used
			var inventory_system = get_node_or_null("/root/InventorySystem")
			if inventory_system:
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_node("PlayerUpgrades"):
					var upgrades = player.get_node("PlayerUpgrades")
					if upgrades.dash_boosts_applied >= 5 and not achievements["dash_expert"]["unlocked"]:
						unlock_achievement("dash_expert")