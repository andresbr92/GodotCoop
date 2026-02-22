class_name EquipmentData
extends Resource

## SlotType define el TIPO de equipamiento, no la instancia física.
## Un item con SlotType.BELT puede ir en cualquier BeltSlot (1, 2 o 3).
## Un item puede tener múltiples allowed_slots (ej: poción puede ir en BELT o HAND).
enum SlotType { HEAD, CHEST, HAND, BELT }

@export_group("Slot Configuration")
## Lista de slots donde este item puede equiparse.
## Ejemplo: una poción puede tener [BELT, HAND] para equiparse en cualquiera.
@export var allowed_slots: Array[SlotType]

@export_group("Visuals")
@export var visual_scene: PackedScene 
@export var bone_name: String = "" # e.g. "Head", "RightHand"

@export_group("Gameplay Specs")
# Effects applied passively while equipped (e.g. +10 Strength)
@export var passive_effects: Array[GameplayEffect] 

# Abilities granted while equipped (e.g. Sword Slash)
@export var granted_abilities: Array[AbilityGrant]
