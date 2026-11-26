extends Node

static func render_columns(game_node: Control) -> void:
	for col_idx in range(4):
		var col_vbox = VBoxContainer.new()
		col_vbox.custom_minimum_size = Vector2(152, 700)
		col_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_vbox.add_theme_constant_override("separation", 10)
		game_node.columns_box.add_child(col_vbox)

		var col: Array = game_node.tableau_columns[col_idx]
		var i := 0
		while i < col.size():
			var card: Dictionary = col[i]

			if not card["face_up"]:
				var back_btn = Button.new()
				back_btn.custom_minimum_size = Vector2(150, 70)
				back_btn.text = "❖"
				back_btn.disabled = true
				col_vbox.add_child(back_btn)
				i += 1
				continue

			var cat_id: String = card["cat_id"]
			var group_words: Array = [card["word"]]
			var j := i + 1
			while j < col.size():
				var next_card: Dictionary = col[j]
				if next_card["face_up"] and next_card["cat_id"] == cat_id:
					group_words.append(next_card["word"])
					j += 1
				else:
					break

			var last_idx := j - 1
			var is_bottom_block := (last_idx == col.size() - 1)
			var group_size := group_words.size()

			var block_btn = Button.new()
			var block_height := 85 + (group_size - 1) * 42
			block_btn.custom_minimum_size = Vector2(150, block_height)

			var is_sel = (game_node.selected_card.get("source") == "col" and game_node.selected_card.get("col") == col_idx)
			if is_sel:
				block_btn.modulate = Color(1.0, 0.92, 0.55)
			elif group_size > 1:
				block_btn.modulate = Color(1.0, 0.97, 0.86)

			# Текст слов внутри единого блока собираем через переносы строк
			var joined_text := ""
			for w_idx in range(group_size):
				if w_idx > 0:
					joined_text += "\n— — —\n"
				joined_text += str(group_words[w_idx])
			block_btn.text = joined_text

			# Счётчик оставшихся слов в правом верхнем углу
			var slot: Dictionary = game_node.category_slots[cat_id]
			var left_count: int = slot["total"] - slot["count"] - group_size

			var badge = Label.new()
			badge.text = ("ВСЕ!" if left_count <= 0 else "ост. " + str(left_count))
			badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			badge.offset_left = -68
			badge.offset_right = -8
			badge.offset_top = 4
			badge.offset_bottom = 24
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			badge.add_theme_font_size_override("font_size", 13)
			badge.add_theme_color_override("font_color", Color(0.15, 0.55, 0.2) if left_count <= 0 else Color(0.65, 0.35, 0.1))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			block_btn.add_child(badge)

			if is_bottom_block:
				block_btn.pressed.connect(game_node._on_tableau_card_pressed.bind(col_idx, last_idx))
				var drag_data = {"source": "col", "col": col_idx, "idx": last_idx, "card": col[last_idx]}
				preload("res://scripts/drag_helper.gd").make_draggable(block_btn, drag_data, game_node)

			col_vbox.add_child(block_btn)
			i = j
