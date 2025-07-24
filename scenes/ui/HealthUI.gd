extends Control

# Medieval-styled Health UI with ornate design
var health_bar: ProgressBar
var health_label: Label
var damage_label: Label
var main_panel: Panel
var knight_icon: Panel
var health_container: VBoxContainer

func _ready():
	# Create medieval health UI
	create_medieval_health_ui()
	
	# Move to UI layer if not already there
	call_deferred("move_to_ui_layer")
	
	# Connect to player's combat system
	call_deferred("connect_to_player")

func create_medieval_health_ui():
	"""Create an ornate medieval-style health display"""
	
	# Main ornate panel container
	main_panel = Panel.new()
	main_panel.position = Vector2(20, 20)
	main_panel.size = Vector2(280, 90)
	
	# Create medieval panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.02, 0.05, 0.95) # Deep dark background
	panel_style.border_color = Color(0.85, 0.65, 0.25, 1.0) # Golden border
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	
	# Add ornate shadow effect
	panel_style.shadow_color = Color(0.85, 0.65, 0.25, 0.3)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)
	
	# Knight shield icon background
	knight_icon = Panel.new()
	knight_icon.position = Vector2(12, 12)
	knight_icon.size = Vector2(66, 66)
	
	# Shield-like styling
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	icon_style.border_color = Color(0.6, 0.45, 0.2, 0.8)
	icon_style.border_width_left = 2
	icon_style.border_width_right = 2
	icon_style.border_width_top = 2
	icon_style.border_width_bottom = 2
	icon_style.corner_radius_top_left = 33
	icon_style.corner_radius_top_right = 33
	icon_style.corner_radius_bottom_left = 8
	icon_style.corner_radius_bottom_right = 8
	knight_icon.add_theme_stylebox_override("panel", icon_style)
	main_panel.add_child(knight_icon)
	
	# Knight emblem (cross design)
	create_knight_emblem()
	
	# Info container for health/damage
	health_container = VBoxContainer.new()
	health_container.position = Vector2(88, 8)
	health_container.size = Vector2(180, 74)
	health_container.add_theme_constant_override("separation", 8)
	main_panel.add_child(health_container)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "⚔️ SIR KNIGHT"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	health_container.add_child(title_label)
	
	# Health info container
	var health_info = HBoxContainer.new()
	health_info.add_theme_constant_override("separation", 8)
	health_container.add_child(health_info)
	
	# Health icon
	var health_icon = Label.new()
	health_icon.text = "❤️"
	health_icon.add_theme_font_size_override("font_size", 16)
	health_info.add_child(health_icon)
	
	# Health label
	health_label = Label.new()
	health_label.text = "100/100"
	health_label.add_theme_font_size_override("font_size", 13)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	health_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	health_info.add_child(health_label)
	
	# Health bar with medieval styling
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(170, 18)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	
	# Medieval health bar styling
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_style.border_color = Color(0.4, 0.3, 0.15, 0.8)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2, 1.0) # Default red
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	health_container.add_child(health_bar)
	
	# Damage info container
	var damage_info = HBoxContainer.new()
	damage_info.add_theme_constant_override("separation", 8)
	health_container.add_child(damage_info)
	
	# Damage icon
	# var damage_icon = Label.new()
	# damage_icon.text = "⚔️"
	# damage_icon.add_theme_font_size_override("font_size", 14)
	# damage_info.add_child(damage_icon)
	
	# # Damage label
	# damage_label = Label.new()
	# damage_label.text = "Attack: 25"
	# damage_label.add_theme_font_size_override("font_size", 12)
	# damage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	# damage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	# damage_label.add_theme_constant_override("shadow_offset_x", 1)
	# damage_label.add_theme_constant_override("shadow_offset_y", 1)
	# damage_info.add_child(damage_label)

func create_knight_emblem():
	"""Create a heraldic cross emblem on the shield"""
	# Vertical bar of cross
	var cross_v = ColorRect.new()
	cross_v.size = Vector2(6, 30)
	cross_v.position = Vector2(30, 18)
	cross_v.color = Color(0.85, 0.65, 0.25, 0.9) # Golden cross
	knight_icon.add_child(cross_v)
	
	# Horizontal bar of cross
	var cross_h = ColorRect.new()
	cross_h.size = Vector2(20, 6)
	cross_h.position = Vector2(23, 27)
	cross_h.color = Color(0.85, 0.65, 0.25, 0.9) # Golden cross
	knight_icon.add_child(cross_h)
	
	# Small decorative gems at cross intersections
	var gem_center = ColorRect.new()
	gem_center.size = Vector2(4, 4)
	gem_center.position = Vector2(31, 29)
	gem_center.color = Color(0.3, 0.7, 1.0, 1.0) # Blue gem
	knight_icon.add_child(gem_center)
	
	# Corner decorative elements
	for i in range(4):
		var corner_dot = ColorRect.new()
		corner_dot.size = Vector2(3, 3)
		corner_dot.color = Color(0.7, 0.5, 0.2, 0.8)
		
		match i:
			0: corner_dot.position = Vector2(15, 15) # Top-left
			1: corner_dot.position = Vector2(48, 15) # Top-right
			2: corner_dot.position = Vector2(15, 48) # Bottom-left
			3: corner_dot.position = Vector2(48, 48) # Bottom-right
		
		knight_icon.add_child(corner_dot)

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
			#damage_label.text = "Attack: " + str(stats.damage)
			
			print("HealthUI: Connected to medieval combat display")

func _on_health_changed(current_health: int, max_health: int):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
		# Dynamic color based on health with medieval theme
		var health_percent = float(current_health) / float(max_health)
		var fill_style = StyleBoxFlat.new()
		
		if health_percent > 0.7:
			# Healthy - Noble green
			fill_style.bg_color = Color(0.2, 0.7, 0.3, 1.0)
		elif health_percent > 0.4:
			# Wounded - Royal gold
			fill_style.bg_color = Color(0.8, 0.7, 0.2, 1.0)
		elif health_percent > 0.2:
			# Critical - Warning orange
			fill_style.bg_color = Color(0.9, 0.5, 0.1, 1.0)
		else:
			# Dying - Crimson red with pulse effect
			fill_style.bg_color = Color(0.9, 0.1, 0.1, 1.0)
			create_critical_health_effect()
			
		fill_style.corner_radius_top_left = 4
		fill_style.corner_radius_top_right = 4
		fill_style.corner_radius_bottom_left = 4
		fill_style.corner_radius_bottom_right = 4
		health_bar.add_theme_stylebox_override("fill", fill_style)
	
	if health_label:
		health_label.text = str(current_health) + "/" + str(max_health)

func create_critical_health_effect():
	"""Add pulsing effect when health is critically low"""
	if main_panel:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(main_panel, "modulate", Color(1.2, 0.8, 0.8, 1.0), 0.5)
		tween.tween_property(main_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
