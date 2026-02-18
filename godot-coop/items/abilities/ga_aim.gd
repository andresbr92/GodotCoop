extends GameplayAbility
class_name GA_Aim

func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	# 1. Start Strafing
	var asc = actor.get_node("AttributeSet")
	if asc:
		asc.is_strafing = true
		print("[GA_Aim] Strafing Active")

func input_released(actor: Node, handle: AbilitySpecHandle) -> void:
	# 2. Stop Strafing when button is released
	var asc = actor.get_node("AttributeSet")
	if asc:
		asc.is_strafing = false
		print("[GA_Aim] Strafing Ended")
	
	# 3. End the ability immediately
	end_ability(actor, handle)
