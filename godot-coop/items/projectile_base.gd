class_name ProjectileBase
extends ItemBase # <--- CHANGED: Inherits from ItemBase instead of RigidBody3D

# --- SPECIFIC DATA ---
# We keep a typed reference for autocomplete convenience,
# but logic could also use 'common_data' from parent casted.
var throwable_data: ThrowableData

# --- NODE REFERENCES ---
# 'visuals' is already defined in ItemBase!
@onready var area_effect: Area3D = %AreaEffect
@onready var impact_sound: AudioStreamPlayer3D = %ImpactSound
@onready var impact_particles: GPUParticles3D = %ImpactParticles

func _ready() -> void:
	super._ready() # <--- IMPORTANT: Call parent _ready
	
	# Projectile specific physics settings override
	# (Though ItemBase already sets this, we keep it explicit if logic changes)
	if multiplayer.is_server():
		body_entered.connect(on_impact)

# --- SETUP ---

# This matches the signature called by ProjectileSpawner
func setup_projectile(new_data: ThrowableData, initial_velocity: Vector3, p_thrower_id: int = 0) -> void:
	# 1. Store specific data
	self.throwable_data = new_data
	self.linear_velocity = initial_velocity
	
	# 2. Call generic setup from ItemBase (Handles ID and Collision Exceptions)
	base_setup(p_thrower_id, new_data)

# --- VIRTUAL METHODS ---

func on_impact(_body: Node) -> void:
	# To be overridden by specific projectiles (e.g. PotionProjectile)
	pass
