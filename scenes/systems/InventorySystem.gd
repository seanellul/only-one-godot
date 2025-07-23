extends Node

# Item types
enum ItemType {
	COIN,
	KEY,
	HEALTH_POTION,
	SPEED_BOOST,
	DASH_BOOST
}

# Item data structure
class Item:
	var type: ItemType
	var name: String
	var description: String
	var icon_color: Color
	var value: int
	
	func _init(item_type: ItemType, item_name: String, item_desc: String, color: Color, item_value: int = 1):
		type = item_type
		name = item_name
		description = item_desc
		icon_color = color
		value = item_value

# Inventory storage
var inventory = {}
var item_definitions = {}

# Signals
signal item_collected(item_type: ItemType, amount: int)
signal inventory_updated()

func _ready():
	initialize_item_definitions()
	initialize_inventory()

func initialize_item_definitions():
	item_definitions = {
		ItemType.COIN: Item.new(ItemType.COIN, "Gold Coin", "Shiny currency of the realm", Color.GOLD, 1),
		ItemType.KEY: Item.new(ItemType.KEY, "Ancient Key", "Opens mysterious doors", Color.SILVER, 1),
		ItemType.HEALTH_POTION: Item.new(ItemType.HEALTH_POTION, "Health Potion", "Restores vitality", Color.RED, 1),
		ItemType.SPEED_BOOST: Item.new(ItemType.SPEED_BOOST, "Swift Boots", "Permanently increases movement speed", Color.CYAN, 1),
		ItemType.DASH_BOOST: Item.new(ItemType.DASH_BOOST, "Wind Essence", "Enhances dash abilities", Color.LIGHT_BLUE, 1)
	}

func initialize_inventory():
	for item_type in ItemType.values():
		inventory[item_type] = 0

func add_item(item_type: ItemType, amount: int = 1) -> bool:
	if item_type in inventory:
		inventory[item_type] += amount
		item_collected.emit(item_type, amount)
		inventory_updated.emit()
		print("Collected ", amount, "x ", get_item_name(item_type))
		return true
	return false

func remove_item(item_type: ItemType, amount: int = 1) -> bool:
	if item_type in inventory and inventory[item_type] >= amount:
		inventory[item_type] -= amount
		inventory_updated.emit()
		return true
	return false

func get_item_count(item_type: ItemType) -> int:
	return inventory.get(item_type, 0)

func get_item_name(item_type: ItemType) -> String:
	if item_type in item_definitions:
		return item_definitions[item_type].name
	return "Unknown Item"

func get_item_description(item_type: ItemType) -> String:
	if item_type in item_definitions:
		return item_definitions[item_type].description
	return "No description available"

func get_item_color(item_type) -> Color:
	# Handle both int and ItemType
	var enum_type = item_type
	if typeof(item_type) == TYPE_INT:
		enum_type = item_type as ItemType
	
	if enum_type in item_definitions:
		return item_definitions[enum_type].icon_color
	return Color.WHITE

func has_item(item_type: ItemType, amount: int = 1) -> bool:
	return get_item_count(item_type) >= amount

func get_total_value() -> int:
	var total = 0
	for item_type in inventory:
		if item_type in item_definitions:
			total += inventory[item_type] * item_definitions[item_type].value
	return total

# Get a random item type for world generation
func get_random_item_type(rng: RandomNumberGenerator) -> ItemType:
	var weights = {
		ItemType.COIN: 60, # 60% chance - common
		ItemType.KEY: 15, # 15% chance - uncommon
		ItemType.HEALTH_POTION: 15, # 15% chance - uncommon
		ItemType.SPEED_BOOST: 7, # 7% chance - rare
		ItemType.DASH_BOOST: 3 # 3% chance - very rare
	}
	
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_value = rng.randi_range(1, total_weight)
	var current_weight = 0
	
	for item_type in weights:
		current_weight += weights[item_type]
		if random_value <= current_weight:
			return item_type
	
	return ItemType.COIN # Fallback