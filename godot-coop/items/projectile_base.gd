extends RigidBody3D


class_name ProjectileBase

var data: ThrowableData
var thrower_id: int = 0

@onready var visuals: Node3D = $Visuals
@onready var area_effect: Area3D = %AreaEffect


func _ready() -> void:
	contact_monitor = false
	max_contacts_reported = 1
	if multiplayer.is_server():
		body_entered.connect(on_inpact)

func setup_projectile(new_data : ThrowableData, initial_velocity: Vector3) -> void:
	self.data = new_data
	self.linear_velocity = initial_velocity

func on_inpact(body: Node) -> void:
	pass
