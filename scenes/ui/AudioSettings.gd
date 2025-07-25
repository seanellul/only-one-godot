extends Control

# Audio settings panel for volume control
class_name AudioSettings

# UI elements
var settings_panel: Panel
var master_slider: HSlider
var music_slider: HSlider
var fx_slider: HSlider
var close_button: Button

# Labels
var master_label: Label
var music_label: Label
var fx_label: Label

func _ready():
	create_settings_ui()
	load_settings()
	
	# Connect to AudioManager volume signals (safely)
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_signal("volume_changed"):
		audio_manager.volume_changed.connect(_on_volume_changed)

func create_settings_ui():
	"""Create the audio settings interface"""
	name = "AudioSettings"
	visible = false
	
	# Main panel
	settings_panel = Panel.new()
	settings_panel.size = Vector2(300, 200)
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-150, -100)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_color = Color(0.6, 0.5, 0.3, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(settings_panel)
	
	# Title
	var title = Label.new()
	title.text = "Audio Settings"
	title.position = Vector2(110, 10)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(title)
	
	# Master Volume
	master_label = Label.new()
	master_label.text = "Master Volume: 80%"
	master_label.position = Vector2(20, 45)
	master_label.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(master_label)
	
	master_slider = HSlider.new()
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = 0.8
	master_slider.size = Vector2(250, 20)
	master_slider.position = Vector2(20, 65)
	master_slider.value_changed.connect(_on_master_volume_changed)
	settings_panel.add_child(master_slider)
	
	# Music Volume
	music_label = Label.new()
	music_label.text = "Music Volume: 70%"
	music_label.position = Vector2(20, 95)
	music_label.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(music_label)
	
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = 0.7
	music_slider.size = Vector2(250, 20)
	music_slider.position = Vector2(20, 115)
	music_slider.value_changed.connect(_on_music_volume_changed)
	settings_panel.add_child(music_slider)
	
	# FX Volume
	fx_label = Label.new()
	fx_label.text = "Effects Volume: 90%"
	fx_label.position = Vector2(20, 145)
	fx_label.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(fx_label)
	
	fx_slider = HSlider.new()
	fx_slider.min_value = 0.0
	fx_slider.max_value = 1.0
	fx_slider.step = 0.05
	fx_slider.value = 0.9
	fx_slider.size = Vector2(250, 20)
	fx_slider.position = Vector2(20, 165)
	fx_slider.value_changed.connect(_on_fx_volume_changed)
	settings_panel.add_child(fx_slider)
	
	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.size = Vector2(80, 30)
	close_button.position = Vector2(110, 195)
	close_button.pressed.connect(hide_settings)
	settings_panel.add_child(close_button)

func show_settings():
	"""Show the audio settings panel"""
	visible = true
	# Animate in
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(settings_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(settings_panel, "scale", Vector2(1.0, 1.0), 0.3)

func hide_settings():
	"""Hide the audio settings panel"""
	# Animate out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(settings_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(settings_panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	await tween.finished
	visible = false
	
	# Save settings
	save_settings()

func _on_master_volume_changed(value: float):
	"""Handle master volume change"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_method("set_master_volume"):
		audio_manager.set_master_volume(value)
	master_label.text = "Master Volume: " + str(int(value * 100)) + "%"

func _on_music_volume_changed(value: float):
	"""Handle music volume change"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_method("set_music_volume"):
		audio_manager.set_music_volume(value)
	music_label.text = "Music Volume: " + str(int(value * 100)) + "%"

func _on_fx_volume_changed(value: float):
	"""Handle FX volume change"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager) and audio_manager.has_method("set_fx_volume"):
		audio_manager.set_fx_volume(value)
	fx_label.text = "Effects Volume: " + str(int(value * 100)) + "%"

func _on_volume_changed(volume_type: String, new_volume: float):
	"""Handle volume changes from AudioManager"""
	match volume_type:
		"master":
			master_slider.value = new_volume
			master_label.text = "Master Volume: " + str(int(new_volume * 100)) + "%"
		"music":
			music_slider.value = new_volume
			music_label.text = "Music Volume: " + str(int(new_volume * 100)) + "%"
		"fx":
			fx_slider.value = new_volume
			fx_label.text = "Effects Volume: " + str(int(new_volume * 100)) + "%"

func save_settings():
	"""Save audio settings to file"""
	var config = ConfigFile.new()
	
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager):
		if "master_volume" in audio_manager:
			config.set_value("audio", "master_volume", audio_manager.master_volume)
		if "music_volume" in audio_manager:
			config.set_value("audio", "music_volume", audio_manager.music_volume)
		if "fx_volume" in audio_manager:
			config.set_value("audio", "fx_volume", audio_manager.fx_volume)
	else:
		# Save current slider values if AudioManager is not available
		config.set_value("audio", "master_volume", master_slider.value if master_slider else 0.8)
		config.set_value("audio", "music_volume", music_slider.value if music_slider else 0.7)
		config.set_value("audio", "fx_volume", fx_slider.value if fx_slider else 0.9)
	
	config.save("user://audio_settings.cfg")
	print("AudioSettings: Settings saved")

func load_settings():
	"""Load audio settings from file"""
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		print("AudioSettings: No settings file found, using defaults")
		return
	
	var master_vol = config.get_value("audio", "master_volume", 0.8)
	var music_vol = config.get_value("audio", "music_volume", 0.7)
	var fx_vol = config.get_value("audio", "fx_volume", 0.9)
	
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager):
		if audio_manager.has_method("set_master_volume"):
			audio_manager.set_master_volume(master_vol)
		if audio_manager.has_method("set_music_volume"):
			audio_manager.set_music_volume(music_vol)
		if audio_manager.has_method("set_fx_volume"):
			audio_manager.set_fx_volume(fx_vol)
		
		# Update sliders
		master_slider.value = master_vol
		music_slider.value = music_vol
		fx_slider.value = fx_vol
		
		print("AudioSettings: Settings loaded")

func _input(event):
	"""Handle input for closing settings"""
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		hide_settings()