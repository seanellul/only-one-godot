extends Control
class_name DialogueUI

# Dialogue system for interacting with signs and NPCs
signal dialogue_finished

@onready var dialogue_panel: Panel
@onready var title_label: Label
@onready var content_label: RichTextLabel
@onready var speaker_label: Label
@onready var continue_button: Button
@onready var background_overlay: ColorRect

var current_dialogue_data: Dictionary = {}
var dialogue_queue: Array = []
var is_showing: bool = false

func _ready():
	create_dialogue_ui()
	hide_dialogue()
	
	# Connect input handling
	set_process_input(true)

func create_dialogue_ui():
	"""Create the medieval-styled dialogue UI"""
	
	# Background overlay (darkens screen)
	background_overlay = ColorRect.new()
	background_overlay.color = Color(0, 0, 0, 0.6)
	background_overlay.size = get_viewport().get_visible_rect().size
	background_overlay.position = Vector2.ZERO
	background_overlay.z_index = 100
	add_child(background_overlay)
	
	# Main dialogue panel with medieval styling
	dialogue_panel = Panel.new()
	dialogue_panel.size = Vector2(600, 200)
	dialogue_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 600) / 2,
		get_viewport().get_visible_rect().size.y - 250
	)
	dialogue_panel.z_index = 101
	
	# Medieval panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.15, 0.1, 0.95) # Dark brown with transparency
	panel_style.border_color = Color(0.8, 0.6, 0.3, 1.0) # Golden border
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(dialogue_panel)
	
	# Speaker/Title label
	speaker_label = Label.new()
	speaker_label.text = "Character Name"
	speaker_label.position = Vector2(20, 10)
	speaker_label.size = Vector2(560, 30)
	speaker_label.add_theme_font_size_override("font_size", 18)
	speaker_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4, 1.0)) # Golden text
	speaker_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 1.0))
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_panel.add_child(speaker_label)
	
	# Content text (supports rich text)
	content_label = RichTextLabel.new()
	content_label.position = Vector2(20, 50)
	content_label.size = Vector2(560, 100)
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.scroll_active = false
	
	# Content styling
	content_label.add_theme_font_size_override("normal_font_size", 14)
	content_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.9, 1.0))
	content_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 1.0))
	
	# Custom content background - lighter for better text visibility
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.25, 0.2, 0.15, 0.9) # Lighter brown for readability
	content_style.border_color = Color(0.6, 0.5, 0.3, 1.0) # Brighter border
	content_style.border_width_left = 2
	content_style.border_width_right = 2
	content_style.border_width_top = 2
	content_style.border_width_bottom = 2
	content_style.corner_radius_top_left = 6
	content_style.corner_radius_top_right = 6
	content_style.corner_radius_bottom_left = 6
	content_style.corner_radius_bottom_right = 6
	content_label.add_theme_stylebox_override("normal", content_style)
	
	dialogue_panel.add_child(content_label)
	
	# Continue button with medieval styling
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.position = Vector2(480, 160)
	continue_button.size = Vector2(100, 30)
	
	# Button styling
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.5, 0.3, 0.1, 1.0) # Brown background
	button_style.border_color = Color(0.8, 0.6, 0.3, 1.0) # Golden border
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	continue_button.add_theme_stylebox_override("normal", button_style)
	
	# Button hover style
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.6, 0.4, 0.2, 1.0) # Lighter brown
	button_hover_style.border_color = Color(1.0, 0.8, 0.4, 1.0) # Brighter golden border
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_bottom = 2
	button_hover_style.corner_radius_top_left = 8
	button_hover_style.corner_radius_top_right = 8
	button_hover_style.corner_radius_bottom_left = 8
	button_hover_style.corner_radius_bottom_right = 8
	continue_button.add_theme_stylebox_override("hover", button_hover_style)
	
	continue_button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4, 1.0))
	continue_button.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 1.0))
	continue_button.add_theme_font_size_override("font_size", 12)
	
	continue_button.pressed.connect(_on_continue_pressed)
	dialogue_panel.add_child(continue_button)

func show_dialogue(dialogue_data: Dictionary):
	"""Show dialogue with the given data"""
	if is_showing:
		return
	
	print("DialogueUI: Showing dialogue with data: ", dialogue_data)
	
	current_dialogue_data = dialogue_data
	is_showing = true
	
	# Set content based on dialogue type
	match dialogue_data.get("type", ""):
		"shop_sign":
			show_shop_sign_dialogue(dialogue_data)
		"npc_conversation":
			show_npc_dialogue(dialogue_data)
		"info_sign":
			show_info_sign_dialogue(dialogue_data)
		_:
			show_generic_dialogue(dialogue_data)
	
	# Show the UI
	background_overlay.visible = true
	dialogue_panel.visible = true
	
	# Pause the game while showing dialogue
	get_tree().paused = true
	
	print("DialogueUI: Dialogue UI now showing")

func show_shop_sign_dialogue(data: Dictionary):
	"""Show dialogue for shop signs"""
	var shop_type = data.get("shop_type", "unknown")
	var title = data.get("title", "Shop")
	var description = data.get("description", "A mysterious shop.")
	
	print("DialogueUI: Shop dialogue - Type: ", shop_type, " Title: ", title)
	
	speaker_label.text = title
	
	# Rich text content with shop-specific styling
	var shop_icon = get_shop_icon(shop_type)
	var shop_color = get_shop_color(shop_type)
	
	var content_text = "[center]%s[/center]\n\n[color=%s]%s[/color]\n\n[i]Press [E] to enter and browse our wares...[/i]" % [shop_icon, shop_color, description]
	content_label.text = content_text
	
	print("DialogueUI: Set content text: ", content_text)

func show_npc_dialogue(data: Dictionary):
	"""Show dialogue for NPC conversations"""
	var npc_name = data.get("npc_name", "Villager")
	var dialogue_text = data.get("dialogue", "Hello, traveler!")
	
	speaker_label.text = npc_name
	content_label.text = "[color=#f0e0c0]%s[/color]" % dialogue_text

func show_info_sign_dialogue(data: Dictionary):
	"""Show dialogue for informational signs"""
	var sign_title = data.get("title", "Notice")
	var sign_text = data.get("text", "Information.")
	
	speaker_label.text = sign_title
	content_label.text = "[center][color=#d0c080]%s[/color][/center]" % sign_text

func show_generic_dialogue(data: Dictionary):
	"""Show generic dialogue"""
	var title = data.get("title", "Information")
	var text = data.get("text", data.get("description", "Something interesting."))
	
	print("DialogueUI: Generic dialogue - Title: ", title, " Text: ", text)
	
	speaker_label.text = title
	content_label.text = text

func get_shop_icon(shop_type: String) -> String:
	"""Get emoji icon for shop type"""
	match shop_type:
		"weapon": return "⚔️ WEAPON SMITH ⚔️"
		"item": return "🧪 APOTHECARY 🧪"
		"armor": return "🛡️ ARMORY 🛡️"
		"magic": return "🔮 MAGIC SHOP 🔮"
		_: return "🏪 SHOP 🏪"

func get_shop_color(shop_type: String) -> String:
	"""Get color code for shop type"""
	match shop_type:
		"weapon": return "#ff8040" # Orange-red
		"item": return "#40ff80" # Green
		"armor": return "#8080ff" # Blue
		"magic": return "#ff40ff" # Purple
		_: return "#ffffff" # White

func hide_dialogue():
	"""Hide the dialogue UI"""
	if not is_showing:
		return
	
	is_showing = false
	background_overlay.visible = false
	dialogue_panel.visible = false
	
	# Resume the game
	get_tree().paused = false
	
	# Emit signal that dialogue finished
	dialogue_finished.emit()

func _on_continue_pressed():
	"""Handle continue button press"""
	hide_dialogue()

func _input(event):
	"""Handle input for dialogue system"""
	if not is_showing:
		return
	
	# Close dialogue on Escape or Space
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		hide_dialogue()
		get_viewport().set_input_as_handled()

func queue_dialogue(dialogue_data: Dictionary):
	"""Add dialogue to queue for sequential display"""
	dialogue_queue.append(dialogue_data)
	
	if not is_showing:
		show_next_dialogue()

func show_next_dialogue():
	"""Show the next dialogue in queue"""
	if dialogue_queue.size() > 0:
		var next_dialogue = dialogue_queue.pop_front()
		show_dialogue(next_dialogue)

func _on_dialogue_finished():
	"""Handle when dialogue finishes"""
	if dialogue_queue.size() > 0:
		# Show next dialogue in queue after a brief delay
		await get_tree().create_timer(0.2).timeout
		show_next_dialogue()
