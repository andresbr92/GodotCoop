class_name HarvestableData
extends Resource

@export_group("General")
@export var tier_name: String = "Common Resource"
@export var harvest_duration: float = 2.0

@export_group("Loot")
@export var loot_table_id: String = ""
@export var destroy_on_harvest: bool = true
@export var respawn_time: float = -1.0
