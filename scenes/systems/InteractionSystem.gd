extends Node2D
class_name InteractionSystem

# System for handling player interactions with signs, NPCs, and other interactive elements

signal interaction_detected(interaction_data: Dictionary)
signal interaction_lost

@onready var interaction_area: Area2D
@onready var collision_shape: CollisionShape2D
@onready var interaction_prompt: Label

var dialogue_ui: DialogueUI
var current_interactive_objects: Array = []
var interaction_range: float = 80.0 # Range for interaction detection
var player_reference: Node2D

func _ready():
	create_interaction_area()
	create_interaction_prompt()
	
	# Set up input handling
	set_process_input(true)
	
	# Connect to the dialogue UI
	setup_dialogue_system()

func create_interaction_area():
	"""Create the interaction detection area"""
	interaction_area = Area2D.new()
	collision_shape = CollisionShape2D.new()
	
	var shape = CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	
	interaction_area.add_child(collision_shape)
	add_child(interaction_area)
	
	# Connect area signals
	interaction_area.area_entered.connect(_on_interactive_area_entered)
	interaction_area.area_exited.connect(_on_interactive_area_exited)
	interaction_area.body_entered.connect(_on_interactive_body_entered)
	interaction_area.body_exited.connect(_on_interactive_body_exited)

func create_interaction_prompt():
	"""Create the interaction prompt UI"""
	interaction_prompt = Label.new()
	interaction_prompt.text = "[E] Interact"
	interaction_prompt.position = Vector2(-50, -40) # Above player
	interaction_prompt.size = Vector2(100, 20)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style the prompt
	interaction_prompt.add_theme_font_size_override("font_size", 12)
	interaction_prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8, 1.0))
	interaction_prompt.add_theme_color_override("font_shadow_color", Color(0.2, 0.2, 0.2, 1.0))
	
	# Create background for prompt
	var prompt_background = Panel.new()
	prompt_background.size = Vector2(120, 30)
	prompt_background.position = Vector2(-60, -45)
	
	var prompt_style = StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	prompt_style.border_color = Color(0.8, 0.8, 0.6, 1.0)
	prompt_style.border_width_left = 1
	prompt_style.border_width_right = 1
	prompt_style.border_width_top = 1
	prompt_style.border_width_bottom = 1
	prompt_style.corner_radius_top_left = 6
	prompt_style.corner_radius_top_right = 6
	prompt_style.corner_radius_bottom_left = 6
	prompt_style.corner_radius_bottom_right = 6
	prompt_background.add_theme_stylebox_override("panel", prompt_style)
	
	add_child(prompt_background)
	add_child(interaction_prompt)
	
	# Start hidden
	interaction_prompt.visible = false
	prompt_background.visible = false

func setup_dialogue_system():
	"""Set up the dialogue system"""
	# Create dialogue UI if it doesn't exist
	if not dialogue_ui:
		var dialogue_scene = preload("res://scenes/ui/DialogueUI.tscn")
		dialogue_ui = dialogue_scene.instantiate()
		dialogue_ui.visible = false
		
		# Add to player node instead of scene
		if player_reference:
			player_reference.add_child.call_deferred(dialogue_ui)
		else:
			# Fallback: find player and add to it
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.add_child.call_deferred(dialogue_ui)
			else:
				# Last resort: add to scene
				get_tree().current_scene.add_child.call_deferred(dialogue_ui)

func set_player_reference(player: Node2D):
	"""Set reference to the player"""
	player_reference = player
	if player_reference:
		# Follow the player
		position = player_reference.global_position

func _process(_delta):
	"""Update interaction system"""
	if player_reference:
		# Follow the player
		global_position = player_reference.global_position
		
		# Update interaction prompt visibility
		update_interaction_prompt()

func update_interaction_prompt():
	"""Update the interaction prompt visibility and text"""
	if current_interactive_objects.size() > 0:
		var closest_object = get_closest_interactive_object()
		if closest_object:
			interaction_prompt.visible = true
			interaction_prompt.get_parent().get_child(0).visible = true # Background
			
			# Update prompt text based on object type
			var interaction_data = closest_object.get("interaction_data", {})
			var object_type = interaction_data.get("type", "")
			
			match object_type:
				"shop_sign":
					interaction_prompt.text = "[E] Read sign"
				"npc":
					interaction_prompt.text = "[E] Talk"
				"info_sign":
					interaction_prompt.text = "[E] Read"
				_:
					interaction_prompt.text = "[E] Interact"
		else:
			hide_interaction_prompt()
	else:
		hide_interaction_prompt()

func hide_interaction_prompt():
	"""Hide the interaction prompt"""
	interaction_prompt.visible = false
	interaction_prompt.get_parent().get_child(0).visible = false # Background

func get_closest_interactive_object() -> Dictionary:
	"""Get the closest interactive object"""
	if current_interactive_objects.size() == 0:
		return {}
	
	var closest_object = null
	var closest_distance = INF
	
	for obj in current_interactive_objects:
		var obj_position = Vector2.ZERO
		if obj.has("position"):
			obj_position = obj.position
		elif obj.has("global_position"):
			obj_position = obj.global_position
		
		var distance = global_position.distance_to(obj_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_object = obj
	
	return closest_object if closest_object else {}

func _input(event):
	"""Handle interaction input"""
	# Use 'E' key or Enter/Space for interactions
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.is_action_pressed("ui_accept"):
			if current_interactive_objects.size() > 0:
				var closest_object = get_closest_interactive_object()
				if closest_object:
					trigger_interaction(closest_object)
				get_viewport().set_input_as_handled()
		
		# Test dialogue with T key
		elif event.keycode == KEY_T:
			test_dialogue_system()
			get_viewport().set_input_as_handled()

func trigger_interaction(interactive_object: Dictionary):
	"""Trigger interaction with an object"""
	var interaction_data = interactive_object.get("interaction_data", {})
	
	if interaction_data.size() > 0:
		# Ensure dialogue UI is available
		if not dialogue_ui:
			setup_dialogue_system()
			await get_tree().process_frame
		
		# Show dialogue based on interaction type
		dialogue_ui.show_dialogue(interaction_data)
		interaction_detected.emit(interaction_data)

func _on_interactive_area_entered(area: Area2D):
	"""Handle when an interactive area enters detection range"""
	var parent_node = area.get_parent()
	
	# Check if this is a sign or other interactive element
	if parent_node.has_method("get_interaction_data"):
		var interaction_data = parent_node.get_interaction_data()
		var interactive_object = {
			"node": parent_node,
			"area": area,
			"interaction_data": interaction_data,
			"position": parent_node.global_position
		}
		current_interactive_objects.append(interactive_object)

func _on_interactive_area_exited(area: Area2D):
	"""Handle when an interactive area exits detection range"""
	var parent_node = area.get_parent()
	
	# Remove from interactive objects list
	for i in range(current_interactive_objects.size() - 1, -1, -1):
		var obj = current_interactive_objects[i]
		if obj.get("node") == parent_node or obj.get("area") == area:
			current_interactive_objects.remove_at(i)
	
	if current_interactive_objects.size() == 0:
		interaction_lost.emit()

func _on_interactive_body_entered(body: Node2D):
	"""Handle when an interactive body enters detection range"""
	# Check for NPCs or other interactive bodies
	if body.has_method("get_interaction_data"):
		var interaction_data = body.get_interaction_data()
		var interactive_object = {
			"node": body,
			"interaction_data": interaction_data,
			"position": body.global_position
		}
		current_interactive_objects.append(interactive_object)

func _on_interactive_body_exited(body: Node2D):
	"""Handle when an interactive body exits detection range"""
	# Remove from interactive objects list
	for i in range(current_interactive_objects.size() - 1, -1, -1):
		var obj = current_interactive_objects[i]
		if obj.get("node") == body:
			current_interactive_objects.remove_at(i)
	
	if current_interactive_objects.size() == 0:
		interaction_lost.emit()

func register_interactive_signs(signs: Array):
	"""Register interactive signs from the town generator"""
	print("InteractionSystem: Registering ", signs.size(), " interactive signs")
	
	for sign_data in signs:
		var area = sign_data.get("area")
		if area:
			# Add interaction method to the area's parent
			var sign_panel = area.get_parent()
			if sign_panel:
				if not sign_panel.has_method("get_interaction_data"):
					sign_panel.set_script(preload("res://scenes/systems/InteractiveSign.gd"))
				sign_panel.setup_interaction_data(sign_data)

func add_interactive_object(object_node: Node2D, interaction_data: Dictionary):
	"""Add a new interactive object to the system"""
	var interactive_object = {
		"node": object_node,
		"interaction_data": interaction_data,
		"position": object_node.global_position
	}
	current_interactive_objects.append(interactive_object)

func test_dialogue_system():
	"""Test the dialogue system with sample data"""
	# Ensure dialogue UI is available
	if not dialogue_ui:
		setup_dialogue_system()
		await get_tree().process_frame
	
	# Create test dialogue data
	var test_data = {
		"type": "shop_sign",
		"shop_type": "weapon",
		"title": "Test Weapon Shop",
		"description": "This is a test dialogue to verify the system is working correctly."
	}
	
	dialogue_ui.show_dialogue(test_data)
