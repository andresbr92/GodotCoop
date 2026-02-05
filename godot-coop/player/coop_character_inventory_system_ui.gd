extends Control
class_name CoopInventorySystemUI

var coop_character_inventory_system : CoopCharacterInventorySystem
@onready var player_inventory_ui: GridInventoryPanel = %GridInventoryPanel



func _ready() -> void:
	player_inventory_ui.visible = false


func setup(characterInventorySystem : CoopCharacterInventorySystem) -> void:
	self.coop_character_inventory_system = characterInventorySystem
	
	set_player_inventory(coop_character_inventory_system.main_inventory)
	coop_character_inventory_system.opened_inventory.connect(_on_open_inventory)

## Setup player inventories
func set_player_inventory(player_inventory : GridInventory):
	player_inventory_ui.inventory = player_inventory
	
# Open Inventory of player	
func _on_open_inventory(inventory : Inventory):
	#if character.main_inventory != inventory:
		#loot_inventory_ui.inventory = inventory
		#loot_inventory_ui.visible = true
		#alternative_inventory = loot_inventory_ui.inventory
	#else:
		_open_player_inventory()
func _open_player_inventory():
	player_inventory_ui.visible = true
