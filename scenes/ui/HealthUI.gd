extends Control

var health_bar: ProgressBar
var health_label: Label
var damage_label: Label

func _ready():
	# Create health bar UI
	create_health_ui()
	
	# Move to UI layer if not already there
	call_deferred("move_to_ui_layer")
	
	# Connect to player's combat system
	call_deferred("connect_to_player")

func create_health_ui():
	# Main container
	var container = VBoxContainer.new()
	container.position = Vector2(10, 10)
	container.add_theme_constant_override("separation", 5)
	add_child(container)
	
	# Health label
	health_label = Label.new()
	health_label.text = "Health: 100/100"
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(health_label)
	
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(200, 20)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	
	# Style the health bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	container.add_child(health_bar)
	
	# Damage label
	damage_label = Label.new()
	damage_label.text = "Damage: 25"
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6, 1.0))
	container.add_child(damage_label)

func move_to_ui_layer():
	var ui_layer = get_node_or_null("../UI")
	if ui_layer and ui_layer is CanvasLayer:
		var current_parent = get_parent()
		if current_parent != ui_layer:
			current_parent.remove_child(self)
			ui_layer.add_child(self)
			print("HealthUI: Moved to UI layer")

func connect_to_player():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_combat_system"):
		var combat_system = player.get_combat_system()
		if combat_system:
			combat_system.health_changed.connect(_on_health_changed)
			
			# Get initial values
			var stats = combat_system.get_combat_stats()
			_on_health_changed(stats.health, stats.max_health)
			damage_label.text = "Damage: " + str(stats.damage)
			
			print("HealthUI: Connected to player combat system")

func _on_health_changed(current_health: int, max_health: int):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
		# Change color based on health percentage
		var health_percent = float(current_health) / float(max_health)
		var fill_style = StyleBoxFlat.new()
		
		if health_percent > 0.6:
			fill_style.bg_color = Color(0.2, 0.8, 0.2, 1.0) # Green
		elif health_percent > 0.3:
			fill_style.bg_color = Color(0.8, 0.8, 0.2, 1.0) # Yellow
		else:
			fill_style.bg_color = Color(0.8, 0.2, 0.2, 1.0) # Red
			
		fill_style.corner_radius_top_left = 3
		fill_style.corner_radius_top_right = 3
		fill_style.corner_radius_bottom_left = 3
		fill_style.corner_radius_bottom_right = 3
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	if health_label:
		health_label.text = "Health: " + str(current_health) + "/" + str(max_health)