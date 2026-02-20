class_name GA_Drink_Potion
extends GameplayAbility

@export var potion_data: PotionData


func activate(actor: Node, handle: AbilitySpecHandle, args: Dictionary = {}) -> void:
	GlobalLogger.log("drinking potion")
	
