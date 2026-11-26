extends Node

# 1. Полёт копии карты от места клика до слота категории
static func fly_card(parent: Control, word: String, start_pos: Vector2, target_pos: Vector2, on_done: Callable) -> void:
	var ghost = Button.new()
	ghost.text = word
	ghost.size = Vector2(150, 80)
	ghost.position = start_pos
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 50
	parent.add_child(ghost)

	var tw = parent.create_tween().set_parallel(true)
	tw.tween_property(ghost, "position", target_pos, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "scale", Vector2(0.6, 0.6), 0.28)
	tw.tween_property(ghost, "modulate:a", 0.3, 0.28)
	tw.chain().tween_callback(func():
		ghost.queue_free()
		if on_done.is_valid():
			on_done.call()
	)

# 2. Всплывающее мини-поздравление и награда (+£60)
static func show_floating_toast(parent: Control, pos: Vector2, text_msg: String, col: Color = Color(1.0, 0.88, 0.3)) -> void:
	var lbl = Label.new()
	lbl.text = text_msg
	lbl.position = pos
	lbl.z_index = 60
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.01))
	lbl.add_theme_constant_override("outline_size", 5)
	parent.add_child(lbl)

	var tw = parent.create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 95, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.1).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)

# 3. Анимация подпрыгивания счётчика денег или кнопки
static func pulse_node(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	var tw = node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.22, 1.22), 0.12)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.14)

# 4. Встряска при неверном ходе
static func shake_node(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var orig_x = node.position.x
	node.modulate = Color(1.0, 0.45, 0.45)
	var tw = node.create_tween()
	tw.tween_property(node, "position:x", orig_x + 12, 0.05)
	tw.tween_property(node, "position:x", orig_x - 12, 0.05)
	tw.tween_property(node, "position:x", orig_x + 8, 0.05)
	tw.tween_property(node, "position:x", orig_x, 0.05)
	tw.tween_callback(func():
		if is_instance_valid(node):
			node.modulate = Color.WHITE
	)
