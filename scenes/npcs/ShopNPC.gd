extends CharacterBody2D

# Shop NPC for selling items to players
class_name ShopNPC

# Shop configuration
var shop_type: String = "general"
var shop_inventory = {}
var player_in_range: bool = false

# Visual elements
var npc_visual: ColorRect
var interaction_prompt: Label
var shop_ui: Control

# Shop types and their inventories
var shop_inventories = {
	"weapon": {
		"Sword Upgrade": {"price": 100, "type": "upgrade", "stat": "damage", "value": 10},
		"Better Sword": {"price": 250, "type": "upgrade", "stat": "damage", "value": 25}
	},
	"item": {
		"Health Potion": {"price": 20, "type": "item", "item_id": 2, "amount": 1},
		"5x Health Potions": {"price": 80, "type": "item", "item_id": 2, "amount": 5},
		"Speed Boost": {"price": 50, "type": "item", "item_id": 3, "amount": 1}
	},
	"armor": {
		"Health Upgrade": {"price": 150, "type": "upgrade", "stat": "health", "value": 50},
		"Max Health Boost": {"price": 300, "type": "upgrade", "stat": "health", "value": 100}
	},
	"magic": {
		"Dash Boost": {"price": 60, "type": "item", "item_id": 4, "amount": 1},
		"Mystic Key": {"price": 100, "type": "item", "item_id": 1, "amount": 1},
		"Portal Scroll": {"price": 200, "type": "special", "effect": "portal"}
	}
}

func _ready():
	print("ShopNPC: Starting setup at position ", global_position)
	
	# Add to NPC group for easy finding
	add_to_group("shopnpc")
	
	# Create visual representation
	create_npc_visual()
	create_interaction_ui()
	
	# Set up collision detection
	var area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	collision_shape.shape = shape
	area.add_child(collision_shape)
	add_child(area)
	
	# Set collision layers properly
	area.collision_layer = 0 # NPC area doesn't need to be on a layer
	area.collision_mask = 2 # Detect player layer (collision_layer 2)
	
	area.body_entered.connect(_on_player_entered)
	area.body_exited.connect(_on_player_exited)
	
	print("ShopNPC: Setup complete - collision mask: ", area.collision_mask)

func setup_shop(type: String):
	"""Set up the shop type and inventory"""
	shop_type = type
	shop_inventory = shop_inventories.get(type, {})
	
	# Update visual based on shop type
	update_shop_visual()
	
	print("ShopNPC: Set up ", type, " shop with ", shop_inventory.size(), " items")

func create_npc_visual():
	"""Create the visual representation of the NPC"""
	npc_visual = ColorRect.new()
	npc_visual.size = Vector2(28, 28)
	npc_visual.position = Vector2(-14, -14)
	npc_visual.color = Color.GRAY
	npc_visual.z_index = 10 # Ensure NPC is visible above tiles
	add_child(npc_visual)
	
	# Add a simple border to make NPC more visible
	var border = ColorRect.new()
	border.size = Vector2(32, 32)
	border.position = Vector2(-16, -16)
	border.color = Color.WHITE
	border.z_index = 9
	add_child(border)

func create_interaction_ui():
	"""Create UI elements for interaction"""
	interaction_prompt = Label.new()
	interaction_prompt.text = "Press F to shop"
	interaction_prompt.position = Vector2(-40, -50)
	interaction_prompt.add_theme_color_override("font_color", Color.YELLOW)
	interaction_prompt.visible = false
	add_child(interaction_prompt)

func update_shop_visual():
	"""Update NPC appearance based on shop type"""
	if not npc_visual:
		return
	
	match shop_type:
		"weapon":
			npc_visual.color = Color.RED
		"item":
			npc_visual.color = Color.GREEN
		"armor":
			npc_visual.color = Color.BLUE
		"magic":
			npc_visual.color = Color.PURPLE
		_:
			npc_visual.color = Color.GRAY

func _input(event):
	"""Handle shop interaction"""
	# Handle escape key to close shop
	if shop_ui and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		close_shop()
		return
	
	# Debug F key presses
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		print("ShopNPC: F key pressed - player_in_range: ", player_in_range, " shop_type: ", shop_type)
		if player_in_range:
			print("ShopNPC: Opening shop!")
			open_shop()
		else:
			print("ShopNPC: Player not in range, cannot open shop")
		return
	
	# This was redundant - removed the second check

func open_shop():
	"""Open the shop interface"""
	print("ShopNPC: Opening ", shop_type, " shop")
	
	# Create simple shop UI
	create_shop_ui()

func create_shop_ui():
	"""Create an improved shop UI"""
	if shop_ui:
		shop_ui.queue_free()
	
	shop_ui = Control.new()
	shop_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Remove pause functionality - let game continue running
	
	# Semi-transparent background
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0, 0, 0, 0.8)
	shop_ui.add_child(bg_overlay)
	
	# Main shop panel (properly centered)
	var panel = Panel.new()
	panel.size = Vector2(500, 400)
	# Set anchors to center and offset by half the panel size to truly center it
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -200) # Offset by half width and half height
	print("ShopNPC: Panel properly centered - size: ", panel.size, " position: ", panel.position)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	panel_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", panel_style)
	shop_ui.add_child(panel)
	
	# Title (as child of panel)
	var title = Label.new()
	title.text = shop_type.capitalize() + " Shop"
	title.position = Vector2(20, 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	
	# Player gold display (as child of panel)
	var inventory_system = get_node_or_null("/root/InventorySystem")
	var player_gold = inventory_system.get_item_count(0) if inventory_system else 0
	var gold_label = Label.new()
	gold_label.text = "Your Gold: " + str(player_gold)
	gold_label.position = Vector2(300, 20)
	gold_label.add_theme_color_override("font_color", Color.YELLOW)
	gold_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(gold_label)
	
	# Items list with better layout (as children of panel)
	var y_offset = 60
	var item_index = 0
	for item_name in shop_inventory:
		var item_data = shop_inventory[item_name]
		
		# Item background
		var item_bg = ColorRect.new()
		item_bg.size = Vector2(460, 40)
		item_bg.position = Vector2(20, y_offset - 5)
		item_bg.color = Color(0.3, 0.3, 0.4, 0.5) if item_index % 2 == 0 else Color(0.2, 0.2, 0.3, 0.5)
		panel.add_child(item_bg)
		
		# Item name and description
		var item_label = Label.new()
		item_label.text = item_name
		item_label.position = Vector2(30, y_offset)
		item_label.add_theme_color_override("font_color", Color.WHITE)
		item_label.add_theme_font_size_override("font_size", 14)
		panel.add_child(item_label)
		
		# Price
		var price_label = Label.new()
		price_label.text = str(item_data.price) + " gold"
		price_label.position = Vector2(250, y_offset)
		price_label.add_theme_color_override("font_color", Color.YELLOW)
		price_label.add_theme_font_size_override("font_size", 14)
		panel.add_child(price_label)
		
		# Buy button
		var buy_button = Button.new()
		buy_button.text = "Buy"
		buy_button.size = Vector2(70, 30)
		buy_button.position = Vector2(400, y_offset - 5)
		
		# Color button based on affordability
		if player_gold >= item_data.price:
			buy_button.add_theme_color_override("font_color", Color.WHITE)
		else:
			buy_button.add_theme_color_override("font_color", Color.GRAY)
			buy_button.disabled = true
		
		buy_button.pressed.connect(_on_buy_item.bind(item_name))
		panel.add_child(buy_button)
		
		y_offset += 45
		item_index += 1
	
	# Close button (as child of panel)
	var close_button = Button.new()
	close_button.text = "Close Shop"
	close_button.size = Vector2(120, 40)
	close_button.position = Vector2(190, 350)
	close_button.pressed.connect(close_shop)
	panel.add_child(close_button)

	
	# Add to a CanvasLayer for proper UI overlay (always on screen)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # High layer to ensure it's on top of everything
	get_tree().current_scene.add_child(canvas_layer)
	canvas_layer.add_child(shop_ui)
	
	print("ShopNPC: Shop UI added to CanvasLayer for proper screen overlay")

func _on_buy_item(item_name: String):
	"""Handle item purchase"""
	var item_data = shop_inventory[item_name]
	var price = item_data.price
	
	# Check if player has enough gold
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		print("ShopNPC: No inventory system found")
		return
	
	var player_gold = inventory_system.get_item_count(0) # Gold is item type 0
	
	if player_gold < price:
		print("ShopNPC: Not enough gold! Need ", price, ", have ", player_gold)
		show_message("Not enough gold! Need " + str(price) + ", have " + str(player_gold))
		return
	
	# Deduct gold
	inventory_system.remove_item(0, price)
	
	# Give item/upgrade
	match item_data.type:
		"item":
			inventory_system.add_item(item_data.item_id, item_data.amount)
			print("ShopNPC: Sold ", item_data.amount, "x ", item_name)
		"upgrade":
			apply_upgrade(item_data.stat, item_data.value)
			print("ShopNPC: Applied upgrade: ", item_data.stat, " +", item_data.value)
		"special":
			handle_special_item(item_data.effect)
			print("ShopNPC: Sold special item: ", item_name)
	
	show_message("Purchased " + item_name + " for " + str(price) + " gold!")

func apply_upgrade(stat: String, value: int):
	"""Apply a stat upgrade to the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	match stat:
		"damage":
			var combat_system = player.get_combat_system()
			if combat_system:
				combat_system.damage += value
		"health":
			var combat_system = player.get_combat_system()
			if combat_system:
				combat_system.max_health += value
				combat_system.heal(value) # Also heal the player

func handle_special_item(effect: String):
	"""Handle special item effects"""
	match effect:
		"portal":
			# Give player a portal scroll or similar
			print("ShopNPC: Special portal item sold")

func show_message(text: String):
	"""Show a temporary message"""
	var message = Label.new()
	message.text = text
	message.position = Vector2(-100, -80)
	message.add_theme_color_override("font_color", Color.GREEN)
	add_child(message)
	
	# Remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(message):
		message.queue_free()

func close_shop():
	"""Close the shop interface"""
	if shop_ui:
		# Get the CanvasLayer parent and remove it completely
		var canvas_layer = shop_ui.get_parent()
		if canvas_layer and canvas_layer.is_class("CanvasLayer"):
			canvas_layer.queue_free()
		else:
			shop_ui.queue_free()
		shop_ui = null
	
	print("ShopNPC: Shop closed")

func _on_player_entered(body):
	"""Handle player entering shop range"""
	print("ShopNPC: Body entered area - ", body.name, " (is_player: ", body.is_in_group("player"), ")")
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		if interaction_prompt:
			interaction_prompt.visible = true
		print("ShopNPC: Player entered shop range - showing prompt")
	else:
		print("ShopNPC: Non-player body entered: ", body.name)

func _on_player_exited(body):
	"""Handle player leaving shop range"""
	print("ShopNPC: Body exited area - ", body.name, " (is_player: ", body.is_in_group("player"), ")")
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false
		if interaction_prompt:
			interaction_prompt.visible = false
		close_shop() # Auto-close shop when leaving
		print("ShopNPC: Player left shop range - hiding prompt")
