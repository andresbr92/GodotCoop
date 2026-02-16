class_name EquipmentData
extends Resource

enum SlotType { HEAD, CHEST, LEGS, FEET, MAIN_HAND, OFF_HAND, ACCESSORY }

@export_group("Slot Configuration")
@export var slot_type: SlotType

@export_group("Visuals")
@export var visual_scene: PackedScene 
@export var bone_name: String = "" # e.g. "Head", "RightHand"

@export_group("Gameplay Specs")
# Effects applied passively while equipped (e.g. +10 Strength)
@export var passive_effects: Array[GameplayEffect] 

# Abilities granted while equipped (e.g. Sword Slash)
@export var granted_abilities: Array[AbilityGrant]
