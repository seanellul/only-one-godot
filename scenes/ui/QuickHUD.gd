extends Control

@onready var coin_label = get_node_or_null("HUDContainer/CoinContainer/CoinLabel")
@onready var key_label = get_node_or_null("HUDContainer/KeyContainer/KeyLabel")
@onready var potion_label = get_node_or_null("HUDContainer/PotionContainer/PotionLabel")
@onready var notification_container = get_node_or_null("NotificationContainer")

func _ready():
	# Check if we need to create missing UI elements
	if not coin_label or not key_label or not potion_label:
		print("QuickHUD: Some labels missing, creating fallback UI")
		call_deferred("create_fallback_ui")
		return
	
	# Connect to inventory updates
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.inventory_updated.connect(_on_inventory_updated)
		inventory_system.item_collected.connect(_on_item_collected)
	
	# Initial update - wait a frame to ensure nodes are ready
	call_deferred("_on_inventory_updated")

func create_fallback_ui():
	# Create a simple fallback HUD if the TSCN structure is broken
	print("QuickHUD: Creating fallback UI")
	
	# Clear any existing children that might be corrupted
	for child in get_children():
		child.queue_free()
	
	# Create a simple container (positioned properly on screen)
	var hud_container = HBoxContainer.new()
	var screen_size = get_viewport().get_visible_rect().size
	hud_container.position = Vector2(screen_size.x - 300, 10) # Top right
	hud_container.add_theme_constant_override("separation", 15)
	add_child(hud_container)
	
	# Create coin display
	var coin_container = HBoxContainer.new()
	hud_container.add_child(coin_container)
	
	var coin_icon = ColorRect.new()
	coin_icon.size = Vector2(20, 20)
	coin_icon.color = Color.GOLD
	coin_container.add_child(coin_icon)
	
	coin_label = Label.new()
	coin_label.text = "0"
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	coin_label.add_theme_font_size_override("font_size", 14)
	coin_container.add_child(coin_label)
	
	# Create key display
	var key_container = HBoxContainer.new()
	hud_container.add_child(key_container)
	
	var key_icon = ColorRect.new()
	key_icon.size = Vector2(20, 20)
	key_icon.color = Color.SILVER
	key_container.add_child(key_icon)
	
	key_label = Label.new()
	key_label.text = "0"
	key_label.add_theme_color_override("font_color", Color.WHITE)
	key_label.add_theme_font_size_override("font_size", 14)
	key_container.add_child(key_label)
	
	# Create potion display
	var potion_container = HBoxContainer.new()
	hud_container.add_child(potion_container)
	
	var potion_icon = ColorRect.new()
	potion_icon.size = Vector2(20, 20)
	potion_icon.color = Color.RED
	potion_container.add_child(potion_icon)
	
	potion_label = Label.new()
	potion_label.text = "0"
	potion_label.add_theme_color_override("font_color", Color.WHITE)
	potion_label.add_theme_font_size_override("font_size", 14)
	potion_container.add_child(potion_label)
	
	# Create notification container
	notification_container = VBoxContainer.new()
	notification_container.position = Vector2(get_viewport().get_visible_rect().size.x - 220, 50)
	add_child(notification_container)
	
	# Now connect to inventory updates
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.inventory_updated.connect(_on_inventory_updated)
		inventory_system.item_collected.connect(_on_item_collected)
	
	# Initial update
	_on_inventory_updated()

func _on_inventory_updated():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# Check if labels are ready
	if not coin_label or not key_label or not potion_label:
		return
	
	# Update quick counts
	coin_label.text = str(inventory_system.get_item_count(0)) # Coins
	key_label.text = str(inventory_system.get_item_count(1)) # Keys
	potion_label.text = str(inventory_system.get_item_count(2)) # Health Potions
	
	# Color coding based on amounts
	update_label_colors()

func update_label_colors():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# Check if labels are ready
	if not coin_label or not key_label or not potion_label:
		return
	
	# Coins - green if 10+, yellow if 5+, white otherwise
	var coin_count = inventory_system.get_item_count(0)
	if coin_count >= 10:
		coin_label.modulate = Color.GREEN
	elif coin_count >= 5:
		coin_label.modulate = Color.YELLOW
	else:
		coin_label.modulate = Color.WHITE
	
	# Keys - gold if any, gray if none
	var key_count = inventory_system.get_item_count(1)
	if key_count > 0:
		key_label.modulate = Color.GOLD
	else:
		key_label.modulate = Color.GRAY
	
	# Potions - red if any, gray if none
	var potion_count = inventory_system.get_item_count(2)
	if potion_count > 0:
		potion_label.modulate = Color.LIGHT_CORAL
	else:
		potion_label.modulate = Color.GRAY

func _on_item_collected(item_type: int, amount: int):
	# Show pickup notification
	show_pickup_notification(item_type, amount)

func show_pickup_notification(item_type: int, amount: int):
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# Create notification
	var notification_popup = create_notification_popup()
	
	# Set up notification content
	var item_names = ["Gold Coin", "Ancient Key", "Health Potion", "Speed Boost", "Dash Boost"]
	var item_colors = [Color.GOLD, Color.SILVER, Color.RED, Color.CYAN, Color.LIGHT_BLUE]
	
	if item_type < item_names.size():
		# Get the hcontainer first, then its children
		var hcontainer = notification_popup.get_child(1) # Second child after panel
		if hcontainer and hcontainer.get_child_count() >= 2:
			var icon = hcontainer.get_child(0) # First child is icon
			var label = hcontainer.get_child(1) # Second child is label
			
			if icon and label:
				icon.color = item_colors[item_type]
				label.text = "+" + str(amount) + " " + item_names[item_type]
				if amount > 1:
					label.text += "s"
	
	if notification_container:
		notification_container.add_child(notification_popup)
	
	# Animate notification
	animate_notification(notification_popup)

func create_notification_popup() -> Control:
	var popup = Control.new()
	popup.custom_minimum_size = Vector2(200, 40)
	popup.position = Vector2(10, 10)
	
	# Background panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.modulate = Color(0, 0, 0, 0.8)
	popup.add_child(panel)
	
	# Horizontal container
	var hcontainer = HBoxContainer.new()
	hcontainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hcontainer.add_theme_constant_override("separation", 10)
	popup.add_child(hcontainer)
	
	# Item icon
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.color = Color.WHITE
	icon.name = "Icon"
	hcontainer.add_child(icon)
	
	# Item label
	var label = Label.new()
	label.text = "Item Collected"
	label.name = "Label"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hcontainer.add_child(label)
	
	return popup

func animate_notification(notification_popup: Control):
	# Start offscreen
	notification_popup.position.x = -250
	notification_popup.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Slide in
	tween.tween_property(notification_popup, "position:x", 10, 0.3)
	tween.tween_property(notification_popup, "modulate:a", 1.0, 0.3)
	
	# Hold for 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	# Slide out
	var exit_tween = create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(notification_popup, "position:x", -250, 0.3)
	exit_tween.tween_property(notification_popup, "modulate:a", 0.0, 0.3)
	
	# Remove after animation
	exit_tween.tween_callback(notification_popup.queue_free).set_delay(0.3)

# Hotkey item usage
func _input(event):
	if event is InputEventKey and event.pressed:
		var inventory_system = get_node_or_null("/root/InventorySystem")
		if not inventory_system:
			return
		
		match event.keycode:
			KEY_1: # Use Health Potion
				use_item(2, "Health Potion", "Restored health!")
			KEY_2: # Use Speed Boost
				use_item(3, "Speed Boost", "Movement speed increased!")
			KEY_3: # Use Dash Boost
				use_item(4, "Dash Boost", "Dash abilities enhanced!")

func use_item(item_type: int, item_name: String, effect_message: String):
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		print("QuickHUD: InventorySystem not found")
		return
	
	var item_count = inventory_system.get_item_count(item_type)
	if item_count > 0:
		print("QuickHUD: Using ", item_name, " (had ", item_count, ")")
		inventory_system.remove_item(item_type, 1)
		show_usage_notification(item_name, effect_message)
		
		# Track item usage for smart sorting
		var inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
		if not inventory_ui:
			inventory_ui = get_node_or_null("../../InventoryUI")
		if inventory_ui and inventory_ui.has_method("track_item_usage"):
			inventory_ui.track_item_usage(item_type)
		
		# Apply actual effects based on item type
		apply_item_effect(item_type)
	else:
		print("QuickHUD: No ", item_name, " to use")

func apply_item_effect(item_type: int):
	# Get player reference and apply effects
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("../../Player")
	
	if player:
		match item_type:
			2: # Health Potion - could restore health if we had a health system
				print("Health restored!")
			3: # Speed Boost - increase player speed
				if player.has_node("PlayerUpgrades"):
					player.get_node("PlayerUpgrades").add_speed_boost()
				else:
					print("Speed boost applied!")
			4: # Dash Boost - enhance dash abilities
				if player.has_node("PlayerUpgrades"):
					player.get_node("PlayerUpgrades").add_dash_boost()
				else:
					print("Dash boost applied!")
	
	# Notify collection tracker about item usage
	var collection_tracker = get_node_or_null("/root/CollectionTracker")
	if collection_tracker:
		collection_tracker.on_item_used(item_type)

func show_usage_notification(item_name: String, _effect_message: String):
	var notification_popup = create_notification_popup()
	
	# Get the hcontainer first, then its children
	var hcontainer = notification_popup.get_child(1) # Second child after panel
	if hcontainer and hcontainer.get_child_count() >= 2:
		var icon = hcontainer.get_child(0) # First child is icon
		var label = hcontainer.get_child(1) # Second child is label
		
		if icon and label:
			icon.color = Color.GREEN
			label.text = "Used " + item_name + "!"
	
	if notification_container:
		notification_container.add_child(notification_popup)
		animate_notification(notification_popup)
