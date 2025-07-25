extends Control

# Real-time debug console for monitoring all game systems
var debug_panel: Panel
var status_label: RichTextLabel
var error_label: Label
var validate_button: Button
var toggle_button: Button

var is_visible: bool = false
var update_timer: Timer

func _ready():
	create_debug_console()
	setup_update_timer()
	
	# Connect to DebugManager signals
	if DebugManager:
		DebugManager.error_detected.connect(_on_error_detected)
		DebugManager.warning_issued.connect(_on_warning_issued)
	
	# Start hidden
	visible = false

func create_debug_console():
	"""Create the debug console UI"""
	name = "DebugConsole"
	
	# Position in top-left corner
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(400, 300)
	position = Vector2(10, 10)
	
	# Main panel
	debug_panel = Panel.new()
	debug_panel.size = size
	debug_panel.position = Vector2.ZERO
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	panel_style.border_color = Color(0.3, 0.8, 0.3, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	debug_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(debug_panel)
	
	# Title
	var title = Label.new()
	title.text = "🔧 System Debug Console"
	title.position = Vector2(10, 5)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	debug_panel.add_child(title)
	
	# Toggle button
	toggle_button = Button.new()
	toggle_button.text = "Hide"
	toggle_button.size = Vector2(50, 25)
	toggle_button.position = Vector2(340, 5)
	toggle_button.pressed.connect(toggle_console)
	debug_panel.add_child(toggle_button)
	
	# Status display
	status_label = RichTextLabel.new()
	status_label.position = Vector2(10, 35)
	status_label.size = Vector2(380, 200)
	status_label.fit_content = true
	status_label.scroll_active = false
	status_label.add_theme_font_size_override("normal_font_size", 10)
	debug_panel.add_child(status_label)
	
	# Error summary
	error_label = Label.new()
	error_label.position = Vector2(10, 245)
	error_label.size = Vector2(280, 20)
	error_label.add_theme_font_size_override("font_size", 11)
	error_label.add_theme_color_override("font_color", Color.YELLOW)
	debug_panel.add_child(error_label)
	
	# Validate button
	validate_button = Button.new()
	validate_button.text = "Force Validation"
	validate_button.size = Vector2(100, 25)
	validate_button.position = Vector2(290, 245)
	validate_button.pressed.connect(force_validation)
	debug_panel.add_child(validate_button)

func setup_update_timer():
	"""Setup timer for regular status updates"""
	update_timer = Timer.new()
	update_timer.wait_time = 2.0 # Update every 2 seconds
	update_timer.autostart = true
	update_timer.timeout.connect(update_status_display)
	add_child(update_timer)

func update_status_display():
	"""Update the debug console with current system status"""
	if not is_visible or not DebugManager:
		return
	
	var health_report = DebugManager.check_system_health()
	var audio_debug = DebugManager.debug_audio_system()
	var save_debug = DebugManager.debug_save_system()
	
	# Format status text
	var status_text = ""
	
	# Overall system status
	var status_color = get_status_color(health_report.overall_status)
	status_text += "[color=" + status_color + "][b]System Status: " + health_report.overall_status + "[/b][/color]\n\n"
	
	# Autoload status
	status_text += "[b]🔧 Autoloads:[/b]\n"
	for autoload_name in health_report.autoloads:
		var is_valid = health_report.autoloads[autoload_name]
		var icon = "✅" if is_valid else "❌"
		status_text += "  " + icon + " " + autoload_name + "\n"
	
	status_text += "\n"
	
	# Audio system status
	status_text += "[b]🔊 Audio System:[/b]\n"
	var audio_icon = "✅" if audio_debug.audio_manager_valid else "⚠️"
	var audio_status = audio_debug.get("status", "Unknown")
	status_text += "  " + audio_icon + " " + audio_status + "\n"
	status_text += "  🎵 Players: " + str(audio_debug.players_created) + "\n"
	status_text += "  🎼 Current: " + audio_debug.current_track + "\n"
	status_text += "  💿 Tracks: " + str(audio_debug.tracks_loaded) + "\n"
	
	status_text += "\n"
	
	# Save system status
	status_text += "[b]💾 Save System:[/b]\n"
	var save_icon = "✅" if save_debug.save_system_valid else "❌"
	status_text += "  " + save_icon + " SaveSystem Valid\n"
	var file_icon = "📁" if save_debug.save_file_exists else "📄"
	status_text += "  " + file_icon + " Save File: " + ("Yes" if save_debug.save_file_exists else "No") + "\n"
	var auto_icon = "✅" if save_debug.auto_save_working else "❌"
	status_text += "  " + auto_icon + " AutoSave: " + ("Working" if save_debug.auto_save_working else "Failed") + "\n"
	
	status_text += "\n"
	
	# Error summary
	var error_counts = health_report.error_counts
	var total_errors = 0
	for category in error_counts:
		total_errors += error_counts[category]
	
	status_text += "[b]⚠️ Error Summary:[/b]\n"
	if total_errors == 0:
		status_text += "  ✅ No errors detected\n"
	else:
		for category in error_counts:
			if error_counts[category] > 0:
				status_text += "  ⚠️ " + DebugManager.DebugCategory.keys()[category] + ": " + str(error_counts[category]) + "\n"
	
	# Update displays
	status_label.text = status_text
	error_label.text = "Total Errors: " + str(total_errors)
	
	# Change error label color based on error count
	if total_errors == 0:
		error_label.add_theme_color_override("font_color", Color.GREEN)
	elif total_errors < 10:
		error_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		error_label.add_theme_color_override("font_color", Color.RED)

func get_status_color(status: String) -> String:
	"""Get color code for system status"""
	match status:
		"HEALTHY":
			return "green"
		"WARNING":
			return "yellow"
		"DEGRADED":
			return "orange"
		"CRITICAL":
			return "red"
		_:
			return "white"

func toggle_console():
	"""Toggle console visibility"""
	is_visible = not is_visible
	visible = is_visible
	toggle_button.text = "Hide" if is_visible else "Show"
	
	if is_visible:
		update_status_display()

func force_validation():
	"""Force system validation"""
	if DebugManager:
		var report = DebugManager.force_system_validation()
		update_status_display()
		
		# Flash the validate button
		var original_color = validate_button.modulate
		validate_button.modulate = Color.GREEN
		await get_tree().create_timer(0.5).timeout
		validate_button.modulate = original_color

func _on_error_detected(category: DebugManager.DebugCategory, message: String):
	"""Handle when an error is detected"""
	if is_visible:
		# Flash the panel red briefly
		var original_style = debug_panel.get_theme_stylebox("panel")
		var error_style = StyleBoxFlat.new()
		error_style.bg_color = Color(0.4, 0.1, 0.1, 0.95)
		error_style.border_color = Color.RED
		error_style.border_width_left = 3
		error_style.border_width_right = 3
		error_style.border_width_top = 3
		error_style.border_width_bottom = 3
		error_style.corner_radius_top_left = 5
		error_style.corner_radius_top_right = 5
		error_style.corner_radius_bottom_left = 5
		error_style.corner_radius_bottom_right = 5
		
		debug_panel.add_theme_stylebox_override("panel", error_style)
		await get_tree().create_timer(0.3).timeout
		debug_panel.add_theme_stylebox_override("panel", original_style)
		
		# Update display immediately
		update_status_display()

func _on_warning_issued(category: DebugManager.DebugCategory, message: String):
	"""Handle when a warning is issued"""
	if is_visible:
		# Flash the panel yellow briefly
		var original_style = debug_panel.get_theme_stylebox("panel")
		var warning_style = StyleBoxFlat.new()
		warning_style.bg_color = Color(0.3, 0.3, 0.1, 0.95)
		warning_style.border_color = Color.YELLOW
		warning_style.border_width_left = 2
		warning_style.border_width_right = 2
		warning_style.border_width_top = 2
		warning_style.border_width_bottom = 2
		warning_style.corner_radius_top_left = 5
		warning_style.corner_radius_top_right = 5
		warning_style.corner_radius_bottom_left = 5
		warning_style.corner_radius_bottom_right = 5
		
		debug_panel.add_theme_stylebox_override("panel", warning_style)
		await get_tree().create_timer(0.2).timeout
		debug_panel.add_theme_stylebox_override("panel", original_style)

func _input(event):
	"""Handle debug console hotkeys"""
	if event is InputEventKey and event.pressed:
		# F12 to toggle debug console
		if event.keycode == KEY_F12:
			toggle_console()
		# F11 to force validation
		elif event.keycode == KEY_F11 and is_visible:
			force_validation()

# Public interface
func show_console():
	"""Show the debug console"""
	is_visible = true
	visible = true
	toggle_button.text = "Hide"
	update_status_display()

func hide_console():
	"""Hide the debug console"""
	is_visible = false
	visible = false
	toggle_button.text = "Show"