extends GutTest
## Tests for TagContainer - the GameplayTag system with reference counting

var _tag_container: TagContainer


func before_each() -> void:
	_tag_container = TagContainer.new()
	add_child(_tag_container)


func after_each() -> void:
	_tag_container.queue_free()


func test_add_tag() -> void:
	# Adding a tag should register it in active_tags
	_tag_container._add_tag_logic(&"state.burning")
	
	assert_true(_tag_container.active_tags.has(&"state.burning"), "Tag should be in active_tags")
	assert_eq(_tag_container.active_tags[&"state.burning"], 1, "Tag count should be 1")


func test_remove_tag() -> void:
	# Removing a tag should decrement and eventually remove it
	_tag_container._add_tag_logic(&"state.burning")
	_tag_container._remove_tag_logic(&"state.burning")
	
	assert_false(_tag_container.active_tags.has(&"state.burning"), "Tag should be removed from active_tags")


func test_tag_reference_counting() -> void:
	# Multiple adds require multiple removes (stacking)
	_tag_container._add_tag_logic(&"buff.speed")
	_tag_container._add_tag_logic(&"buff.speed")
	_tag_container._add_tag_logic(&"buff.speed")
	
	assert_eq(_tag_container.active_tags[&"buff.speed"], 3, "Tag count should be 3 after 3 adds")
	
	_tag_container._remove_tag_logic(&"buff.speed")
	assert_eq(_tag_container.active_tags[&"buff.speed"], 2, "Tag count should be 2 after 1 remove")
	assert_true(_tag_container.has_tag(&"buff.speed"), "Tag should still be active")
	
	_tag_container._remove_tag_logic(&"buff.speed")
	_tag_container._remove_tag_logic(&"buff.speed")
	assert_false(_tag_container.has_tag(&"buff.speed"), "Tag should be gone after all removes")


func test_has_tag() -> void:
	# has_tag should return correct boolean
	assert_false(_tag_container.has_tag(&"state.stunned"), "Should not have tag initially")
	
	_tag_container._add_tag_logic(&"state.stunned")
	assert_true(_tag_container.has_tag(&"state.stunned"), "Should have tag after adding")
	
	_tag_container._remove_tag_logic(&"state.stunned")
	assert_false(_tag_container.has_tag(&"state.stunned"), "Should not have tag after removing")


func test_tag_signals() -> void:
	# Signals should emit on first add and last remove
	watch_signals(_tag_container)
	
	# First add should emit tag_added
	_tag_container._add_tag_logic(&"effect.poison")
	assert_signal_emitted(_tag_container, "tag_added", "tag_added should emit on first add")
	
	# Second add should NOT emit again (tag already exists, just increments count)
	_tag_container._add_tag_logic(&"effect.poison")
	assert_signal_emit_count(_tag_container, "tag_added", 1, "tag_added should only emit once for same tag")
	
	# First remove should NOT emit (tag still has count > 0)
	_tag_container._remove_tag_logic(&"effect.poison")
	assert_signal_not_emitted(_tag_container, "tag_removed", "tag_removed should NOT emit while count > 0")
	
	# Last remove should emit tag_removed
	_tag_container._remove_tag_logic(&"effect.poison")
	assert_signal_emitted(_tag_container, "tag_removed", "tag_removed should emit when count reaches 0")
