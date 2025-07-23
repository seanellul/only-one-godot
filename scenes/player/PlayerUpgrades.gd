extends Node

# Upgrade tracking
var speed_boosts_applied = 0
var dash_boosts_applied = 0
var max_upgrades_per_type = 5

# Upgrade effects
var speed_boost_per_upgrade = 50.0 # +50 speed per boost
var dash_cooldown_reduction = 0.1 # -0.1s cooldown per boost
var dash_distance_increase = 0.05 # +5% distance per boost

signal upgrade_applied(upgrade_type: String, level: int)

func _ready():
	# Add player to group for easy reference
	get_parent().add_to_group("player")

func add_speed_boost():
	if speed_boosts_applied < max_upgrades_per_type:
		speed_boosts_applied += 1
		apply_speed_upgrade()
		upgrade_applied.emit("Speed", speed_boosts_applied)
		print("Speed Boost Applied! Level: ", speed_boosts_applied, "/", max_upgrades_per_type)
	else:
		print("Maximum speed boosts reached!")

func add_dash_boost():
	if dash_boosts_applied < max_upgrades_per_type:
		dash_boosts_applied += 1
		apply_dash_upgrade()
		upgrade_applied.emit("Dash", dash_boosts_applied)
		print("Dash Boost Applied! Level: ", dash_boosts_applied, "/", max_upgrades_per_type)
	else:
		print("Maximum dash boosts reached!")

func apply_speed_upgrade():
	var player = get_parent()
	if "SPEED" in player:
		# Modify the base speed
		var new_speed = 200.0 + (speed_boosts_applied * speed_boost_per_upgrade)
		player.SPEED = new_speed
		print("Player speed increased to: ", new_speed)

func apply_dash_upgrade():
	var player = get_parent()
	
	# Reduce dash cooldown
	if "DASH_COOLDOWN" in player:
		var new_cooldown = max(0.2, 1.0 - (dash_boosts_applied * dash_cooldown_reduction))
		player.DASH_COOLDOWN = new_cooldown
		print("Dash cooldown reduced to: ", new_cooldown, "s")
	
	# Increase dash distance by modifying speed
	if "DASH_SPEED" in player:
		var base_dash_speed = 600.0
		var multiplier = 1.0 + (dash_boosts_applied * dash_distance_increase)
		var new_dash_speed = base_dash_speed * multiplier
		player.DASH_SPEED = new_dash_speed
		print("Dash speed increased to: ", new_dash_speed)

func get_upgrade_info() -> Dictionary:
	return {
		"speed_level": speed_boosts_applied,
		"speed_max": max_upgrades_per_type,
		"dash_level": dash_boosts_applied,
		"dash_max": max_upgrades_per_type,
		"speed_next_bonus": speed_boost_per_upgrade,
		"dash_next_bonus": dash_cooldown_reduction
	}
