extends GutTest
## Tests for CastManager - handles channeled/casted abilities with duration

var _cast_manager: CastManager

# Tracking variables for callbacks (class-level to avoid lambda capture issues)
var _cancel_called: bool = false
var _complete_called: bool = false


func before_each() -> void:
	_cast_manager = CastManager.new()
	_cancel_called = false
	_complete_called = false
	add_child(_cast_manager)


func after_each() -> void:
	_cast_manager.queue_free()


func _on_cancel() -> void:
	_cancel_called = true


func _on_complete() -> void:
	_complete_called = true


func test_start_cast() -> void:
	# Starting a cast should register it in active_casts
	var handle = AbilitySpecHandle.new("Test Cast")
	
	_cast_manager._start_cast_logic(handle, 2.0, _on_complete)
	
	assert_true(_cast_manager.active_casts.has(handle), "Cast should be registered")
	assert_eq(_cast_manager.active_casts[handle].duration, 2.0, "Duration should match")
	assert_eq(_cast_manager.active_casts[handle].elapsed, 0.0, "Elapsed should start at 0")


func test_cancel_cast() -> void:
	# Cancelling a cast should call on_cancel and remove it
	var handle = AbilitySpecHandle.new("Cancelable Cast")
	
	_cast_manager._start_cast_logic(handle, 5.0, _on_complete, _on_cancel)
	assert_true(_cast_manager.has_active_cast(handle), "Cast should be active")
	
	_cast_manager._cancel_cast_logic(handle)
	
	assert_true(_cancel_called, "on_cancel callback should be called")
	assert_false(_cast_manager.has_active_cast(handle), "Cast should be removed after cancel")


func test_cast_completes() -> void:
	# Cast should call on_complete when duration is reached
	var handle = AbilitySpecHandle.new("Completing Cast")
	
	_cast_manager._start_cast_logic(handle, 2.0, _on_complete)
	
	# Simulate time passing (not enough to complete)
	_cast_manager._process_logic(1.0)
	assert_false(_complete_called, "on_complete should not be called yet")
	assert_true(_cast_manager.has_active_cast(handle), "Cast should still be active")
	
	# Simulate more time (enough to complete)
	_cast_manager._process_logic(1.5)
	assert_true(_complete_called, "on_complete should be called after duration")
	assert_false(_cast_manager.has_active_cast(handle), "Cast should be removed after completion")


func test_has_active_cast() -> void:
	# has_active_cast should correctly report cast status
	var handle = AbilitySpecHandle.new("Status Check Cast")
	
	assert_false(_cast_manager.has_active_cast(handle), "Should not have cast initially")
	
	_cast_manager._start_cast_logic(handle, 3.0, _on_complete)
	assert_true(_cast_manager.has_active_cast(handle), "Should have cast after starting")
	
	_cast_manager._cancel_cast_logic(handle)
	assert_false(_cast_manager.has_active_cast(handle), "Should not have cast after cancel")
