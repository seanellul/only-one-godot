extends Control

# Cutscene data structure
class CutsceneScene:
	var background_texture: Texture2D # Far background layer
	var midground_texture: Texture2D # Middle layer
	var foreground_texture: Texture2D # Front particles/effects layer
	var background_color: Color
	var text: String
	var text_color: Color
	var fade_duration: float
	var parallax_speeds: Vector3 # x=background, y=midground, z=foreground speeds
	
	func _init(bg_color: Color, scene_text: String, txt_color: Color = Color.WHITE, fade_time: float = 1.0, parallax: Vector3 = Vector3(0.3, 0.6, 1.0)):
		background_color = bg_color
		text = scene_text
		text_color = txt_color
		fade_duration = fade_time
		parallax_speeds = parallax
	
	func set_textures(bg_tex: Texture2D = null, mid_tex: Texture2D = null, fg_tex: Texture2D = null):
		background_texture = bg_tex
		midground_texture = mid_tex
		foreground_texture = fg_tex
		return self

# Cutscene management
var cutscene_scenes: Array = []
var current_scene_index: int = 0
var is_playing: bool = false
var can_advance: bool = false

# UI Elements
var background_layer: Control
var parallax_container: Control
var background_parallax: Control # Far background layer
var midground_parallax: Control # Middle layer
var foreground_parallax: Control # Front effects layer
var text_container: Control
var cutscene_label: RichTextLabel
var fade_overlay: ColorRect
var advance_prompt: Label

# Signals
signal cutscene_finished()
signal scene_changed(scene_index: int)

func _ready():
	setup_ui()
	setup_input_handling()

func setup_ui():
	# Make fullscreen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background layer
	background_layer = Control.new()
	background_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_layer)
	
	# Parallax container for all moving layers with strict clipping
	parallax_container = Control.new()
	parallax_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parallax_container.clip_contents = true
	parallax_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(parallax_container)
	
	# Create three parallax layers (back to front) with clipping
	background_parallax = Control.new()
	background_parallax.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_parallax.clip_contents = true
	background_parallax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parallax_container.add_child(background_parallax)
	
	midground_parallax = Control.new()
	midground_parallax.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	midground_parallax.clip_contents = true
	midground_parallax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parallax_container.add_child(midground_parallax)
	
	foreground_parallax = Control.new()
	foreground_parallax.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foreground_parallax.clip_contents = true
	foreground_parallax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parallax_container.add_child(foreground_parallax)
	
	# Text container
	text_container = Control.new()
	text_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(text_container)
	
	# Main cutscene text
	cutscene_label = RichTextLabel.new()
	cutscene_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cutscene_label.custom_minimum_size = Vector2(800, 200)
	cutscene_label.position = Vector2(-400, -100)
	cutscene_label.bbcode_enabled = true
	cutscene_label.fit_content = true
	cutscene_label.scroll_active = false
	
	# Style the text
	cutscene_label.add_theme_font_size_override("normal_font_size", 24)
	cutscene_label.add_theme_font_size_override("bold_font_size", 28)
	cutscene_label.add_theme_color_override("default_color", Color.WHITE)
	
	text_container.add_child(cutscene_label)
	
	# Advance prompt
	advance_prompt = Label.new()
	advance_prompt.text = "Click to continue..."
	advance_prompt.add_theme_font_size_override("font_size", 16)
	advance_prompt.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	advance_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	advance_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	advance_prompt.position.y -= 50
	advance_prompt.modulate.a = 0.0
	text_container.add_child(advance_prompt)
	
	# Fade overlay
	fade_overlay = ColorRect.new()
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0
	add_child(fade_overlay)

func setup_input_handling():
	# Make sure we can receive input
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event):
	if not is_playing:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if can_advance:
			advance_scene()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		if can_advance:
			advance_scene()

func play_cutscene(scenes: Array):
	"""Start playing a cutscene with the given scenes"""
	cutscene_scenes = scenes
	current_scene_index = 0
	is_playing = true
	can_advance = false
	
	print("CutsceneManager: Starting cutscene with ", scenes.size(), " scenes")
	
	# Start with fade overlay visible
	fade_overlay.modulate.a = 1.0
	
	# Play first scene
	if cutscene_scenes.size() > 0:
		play_scene(0)

func play_scene(scene_index: int):
	"""Play a specific scene"""
	if scene_index >= cutscene_scenes.size():
		finish_cutscene()
		return
	
	current_scene_index = scene_index
	var scene = cutscene_scenes[scene_index]
	
	print("CutsceneManager: Playing scene ", scene_index + 1, "/", cutscene_scenes.size())
	
	# Update background
	update_background(scene)
	
	# Update text (initially hidden)
	cutscene_label.text = "[center]" + scene.text + "[/center]"
	cutscene_label.modulate = scene.text_color
	cutscene_label.modulate.a = 0.0
	
	# Hide advance prompt
	advance_prompt.modulate.a = 0.0
	can_advance = false
	
	# Fade in sequence
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out black overlay
	tween.tween_property(fade_overlay, "modulate:a", 0.0, scene.fade_duration)
	
	# Fade in text after a short delay
	tween.tween_property(cutscene_label, "modulate:a", 1.0, scene.fade_duration * 0.8).set_delay(scene.fade_duration * 0.3)
	
	# Show advance prompt after text is visible
	tween.tween_callback(show_advance_prompt).set_delay(scene.fade_duration * 1.2)
	
	# Start multi-layer parallax effect
	start_multi_parallax_effect(scene.parallax_speeds)
	
	scene_changed.emit(scene_index)

func update_background(scene: CutsceneScene):
	"""Update all parallax layers for a scene"""
	# Clear all existing layers
	clear_parallax_layer(background_parallax)
	clear_parallax_layer(midground_parallax)
	clear_parallax_layer(foreground_parallax)
	
	# Create base color background (always present) with overscan
	var bg_rect = ColorRect.new()
	
	# Apply same overscan as textures to ensure no gaps
	var overscan_factor = 1.4
	var screen_size = get_viewport().get_visible_rect().size
	var overscan_size = screen_size * overscan_factor
	var offset = (overscan_size - screen_size) / 2
	
	bg_rect.position = Vector2(-offset.x, -offset.y)
	bg_rect.size = overscan_size
	bg_rect.color = scene.background_color
	background_parallax.add_child(bg_rect)
	
	# Add background texture layer (farthest back)
	if scene.background_texture:
		add_texture_to_layer(background_parallax, scene.background_texture, 0.8)
	
	# Add midground texture layer
	if scene.midground_texture:
		add_texture_to_layer(midground_parallax, scene.midground_texture, 0.7)
	
	# Add foreground texture layer (closest, with transparency for particles/effects)
	if scene.foreground_texture:
		add_texture_to_layer(foreground_parallax, scene.foreground_texture, 0.6)

func clear_parallax_layer(layer: Control):
	"""Clear all children from a parallax layer"""
	for child in layer.get_children():
		child.queue_free()

func add_texture_to_layer(layer: Control, texture: Texture2D, opacity: float = 1.0):
	"""Add a texture to a specific parallax layer with overscan for movement"""
	var texture_rect = TextureRect.new()
	
	# Create overscan to accommodate parallax movement (20% extra on each side)
	var overscan_factor = 1.4 # 40% extra total (20% each side)
	var screen_size = get_viewport().get_visible_rect().size
	var overscan_size = screen_size * overscan_factor
	
	# Center the oversized rect
	var offset = (overscan_size - screen_size) / 2
	texture_rect.position = Vector2(-offset.x, -offset.y)
	texture_rect.size = overscan_size
	
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.modulate.a = opacity
	layer.add_child(texture_rect)

func start_multi_parallax_effect(speeds: Vector3):
	"""Start multi-layer parallax movement with different speeds"""
	# Background layer (slowest, subtle movement)
	if speeds.x > 0:
		start_layer_parallax(background_parallax, speeds.x, 8.0)
	
	# Midground layer (medium speed)
	if speeds.y > 0:
		start_layer_parallax(midground_parallax, speeds.y, 15.0)
	
	# Foreground layer (fastest, most dramatic)
	if speeds.z > 0:
		start_layer_parallax(foreground_parallax, speeds.z, 25.0)

func start_layer_parallax(layer: Control, speed: float, movement_range: float):
	"""Start parallax animation for a specific layer"""
	var tween = create_tween()
	tween.set_loops()
	
	# Create flowing movement pattern
	var base_time = 4.0 / speed
	tween.tween_property(layer, "position:x", movement_range, base_time)
	tween.tween_property(layer, "position:x", -movement_range, base_time * 2)
	tween.tween_property(layer, "position:x", 0.0, base_time)

func start_parallax_effect(speed: float):
	"""Legacy single-layer parallax (kept for compatibility)"""
	start_multi_parallax_effect(Vector3(speed, speed, speed))

func show_advance_prompt():
	"""Show the advance prompt with a gentle fade"""
	can_advance = true
	var tween = create_tween()
	tween.tween_property(advance_prompt, "modulate:a", 1.0, 0.5)
	
	# Add gentle pulsing effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(advance_prompt, "modulate:a", 0.5, 1.0)
	pulse_tween.tween_property(advance_prompt, "modulate:a", 1.0, 1.0)

func advance_scene():
	"""Advance to the next scene"""
	if not can_advance:
		return
		
	can_advance = false
	
	# Fade to black
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.8)
	tween.tween_property(cutscene_label, "modulate:a", 0.0, 0.6)
	tween.tween_property(advance_prompt, "modulate:a", 0.0, 0.4)
	
	# Play next scene after fade
	tween.tween_callback(play_next_scene).set_delay(1.0)

func play_next_scene():
	"""Play the next scene in sequence"""
	current_scene_index += 1
	play_scene(current_scene_index)

func finish_cutscene():
	"""Finish the cutscene and clean up"""
	print("CutsceneManager: Cutscene finished")
	is_playing = false
	can_advance = false
	
	# Final fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	tween.tween_callback(emit_finished_signal).set_delay(1.2)

func emit_finished_signal():
	cutscene_finished.emit()

func skip_cutscene():
	"""Skip the entire cutscene"""
	if is_playing:
		finish_cutscene()