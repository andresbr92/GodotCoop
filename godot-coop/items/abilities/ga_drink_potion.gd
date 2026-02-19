class_name GA_Drink_Potion
extends GameplayAbility


func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	GlobalLogger.log("drinking potion")
	
