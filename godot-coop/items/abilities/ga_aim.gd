extends GameplayAbility
class_name GA_Aim

func activate(actor: Node, _handle: AbilitySpecHandle, _args: Dictionary = {}) -> void:
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if asc:
		asc.is_strafing = true
		print("[GA_Aim] Strafing Active")

func input_released(actor: Node, handle: AbilitySpecHandle) -> void:
	var asc: AbilitySystemComponent = actor.get_node_or_null("AbilitySystemComponent")
	if asc:
		asc.is_strafing = false
		print("[GA_Aim] Strafing Ended")
	
	end_ability(actor, handle)
