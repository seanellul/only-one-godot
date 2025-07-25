# Save System & Main Menu Implementation

## Overview
This implementation provides a complete main menu and save system for the "Only One" game with the following features:

- **Main Menu**: Clean UI with New Game, Continue, and Quit options
- **Auto-Save**: Saves game state when exiting via ESC key
- **Death Handling**: Deletes save on player death and returns to main menu
- **Session Persistence**: Continues from saved state when reopening the game

## Game Flow

### First Time Playing
1. Open Game → Main Menu appears
2. Click "New Game" → Start fresh game
3. "Continue" button is disabled (no save exists)

### Normal Gameplay Loop
1. Press ESC → Auto-save and return to Main Menu
2. Click "Continue" → Resume from saved position
3. Close game window → Auto-save before quit

### Death Scenario
1. Player dies → Save file deleted automatically
2. Return to Main Menu
3. "Continue" button becomes disabled
4. Must click "New Game" to play again

## Technical Implementation

### Core Components

1. **MainMenu.tscn/gd** - Main menu interface
2. **SaveSystem.gd** - Autoload for save/load functionality
3. **GameManager.gd** - Autoload for scene management and game flow

### Save Data Structure
```gdscript
{
    "player_name": "SIR KNIGHT",
    "player_health": 100,
    "player_max_health": 100,
    "player_position": Vector2(x, y),
    "current_zone": "town",
    "inventory": {},
    "upgrades": {},
    "play_time": 0.0,
    "save_timestamp": "2024-01-01 12:00:00"
}
```

### Key Features

#### ESC Key Handling
- **In Main Menu**: Quit game
- **In Game**: Save and return to main menu

#### Death Detection
- Automatically connects to player's `player_died` signal
- Deletes save file on death
- Returns to main menu

#### Auto-Save
- Saves when pressing ESC
- Saves when closing game window
- Saves player position, health, inventory, upgrades

## Usage

### For Players
- **ESC** - Exit to main menu (saves automatically)
- **Close Window** - Auto-saves before quitting
- **Death** - Returns to main menu, must start new game

### For Developers

#### Adding Save Data to Systems
```gdscript
# In your system script
func get_save_data() -> Dictionary:
    return {"key": value}

func load_save_data(data: Dictionary):
    # Apply loaded data
    pass
```

#### Connecting to Death Events
The GameManager automatically connects to player death signals. Supported signal names:
- `died`
- `death` 
- `player_died`
- `health_depleted`

## File Locations

- **Save File**: `user://savegame.dat`
- **Main Scene**: `res://scenes/ui/MainMenu.tscn`
- **Game Scene**: `res://scenes/rooms/Room.tscn`

## Configuration

### Project Settings (project.godot)
```ini
[application]
run/main_scene="res://scenes/ui/MainMenu.tscn"

[autoload]
SaveSystem="*res://scenes/systems/SaveSystem.gd"
GameManager="*res://scenes/systems/GameManager.gd"
```

### Input Map
- `ui_cancel` mapped to ESC key (Godot default)

## Extending the System

### Adding New Save Data
1. Update `SaveSystem.collect_game_state()`
2. Update `SaveSystem.apply_game_state()`
3. Add corresponding functions to your system

### Custom Death Handling
```gdscript
# Connect to GameManager signals
GameManager.player_died.connect(_on_player_died)
GameManager.game_saved.connect(_on_game_saved)
GameManager.game_loaded.connect(_on_game_loaded)
``` 