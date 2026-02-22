class_name CastManager
extends Node

class ActiveCast:
	var handle: AbilitySpecHandle
	var duration: float
	var elapsed: float = 0.0
	var on_complete: Callable
	var on_cancel: Callable
	
	func _init(p_handle: AbilitySpecHandle, p_duration: float, p_on_complete: Callable, p_on_cancel: Callable = Callable()):
		handle = p_handle
		duration = p_duration
		on_complete = p_on_complete
		on_cancel = p_on_cancel

var active_casts: Dictionary = {}


func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	_process_logic(delta)


## Testable process logic - call directly in tests
func _process_logic(delta: float) -> void:
	_process_active_casts(delta)


func start_cast(handle: AbilitySpecHandle, duration: float, on_complete: Callable, on_cancel: Callable = Callable()) -> void:
	if not multiplayer.is_server(): return
	_start_cast_logic(handle, duration, on_complete, on_cancel)


## Testable start cast logic - call directly in tests
func _start_cast_logic(handle: AbilitySpecHandle, duration: float, on_complete: Callable, on_cancel: Callable = Callable()) -> void:
	if active_casts.has(handle):
		GlobalLogger.log("[CastManager] Warning: Cast already in progress for: ", handle)
		return
	
	var cast = ActiveCast.new(handle, duration, on_complete, on_cancel)
	active_casts[handle] = cast
	GlobalLogger.log("[CastManager] Started cast for ", handle, " | Duration: ", duration, "s")


func cancel_cast(handle: AbilitySpecHandle) -> void:
	if not multiplayer.is_server(): return
	_cancel_cast_logic(handle)


## Testable cancel cast logic - call directly in tests
func _cancel_cast_logic(handle: AbilitySpecHandle) -> void:
	if not active_casts.has(handle): return
	
	var cast: ActiveCast = active_casts[handle]
	GlobalLogger.log("[CastManager] Cast CANCELLED for ", handle)
	
	if cast.on_cancel.is_valid():
		cast.on_cancel.call()
	
	active_casts.erase(handle)


func has_active_cast(handle: AbilitySpecHandle) -> bool:
	return active_casts.has(handle)


func _process_active_casts(delta: float) -> void:
	var completed_casts: Array[AbilitySpecHandle] = []
	
	for handle in active_casts:
		var cast: ActiveCast = active_casts[handle]
		cast.elapsed += delta
		
		if cast.elapsed >= cast.duration:
			completed_casts.append(handle)
	
	for handle in completed_casts:
		var cast: ActiveCast = active_casts[handle]
		GlobalLogger.log("[CastManager] Cast COMPLETED for ", handle)
		
		if cast.on_complete.is_valid():
			cast.on_complete.call()
		
		active_casts.erase(handle)
