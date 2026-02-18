class_name ItemBase
extends RigidBody3D

# --- COMMON VARIABLES ---

# The ID of the player/entity who spawned/threw this item.
# Useful for collision exceptions (don't hit yourself).
var thrower_id: int = 0

# Generic resource reference. 
# In Projectiles, this will be ThrowableData.
# In DroppedItems, this could be ItemDefinition or EquipmentData.
var common_data: Resource

# --- NODE REFERENCES ---
@onready var visuals: Node3D = $Visuals
@onready var physics_shape: CollisionShape3D = $PhysicsShape


func _ready() -> void:
	# Basic physics optimization
	# Use continuous collision detection to prevent tunneling through floors
	continuous_cd = true
	# Usually we want to monitor contacts for impact logic
	contact_monitor = true
	max_contacts_reported = 1

# --- SETUP API ---

# Base setup function called by Spawners or Factories.
# Children classes should call super.base_setup() if they override setup logic.
func base_setup(p_thrower_id: int, p_data: Resource) -> void:
	self.thrower_id = p_thrower_id
	self.common_data = p_data
	
	_setup_collision_exceptions()

# Adds a collision exception so the item doesn't collide with its creator immediately.
func _setup_collision_exceptions() -> void:
	if thrower_id == 0: return
	pass
	
	# Try to find the thrower node in the scene tree
	# Assuming player nodes are named after their Peer ID
	#var thrower_node = get_tree().root.find_child(str(thrower_id), true, false)
	#
	#if thrower_node:
		#add_collision_exception_with(thrower_node)
