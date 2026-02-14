class_name LootableBase
extends Node3D


const Interactor = preload("res://addons/inventory-system-demos/interaction_system/inventory_interactor.gd")

@export_group("Lootable Settings")

@onready var inventory : Inventory = $Inventory
@export var actions : Array



func get_interact_actions(_interactor : Interactor) -> Array:
	return actions
