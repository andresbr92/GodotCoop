class_name LootContainerData
extends Resource

@export_group("Loot Settings")
@export var loot_table_id: String = ""
@export var min_rolls: int = 2
@export var max_rolls: int = 5

@export_group("Search Mechanics")
@export var seconds_to_reveal_per_item: float = 1.5 # Tiempo por cada slot
@export var auto_search_on_open: bool = true # Si empieza a buscar solo al abrir
