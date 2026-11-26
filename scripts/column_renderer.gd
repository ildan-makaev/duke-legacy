extends Node

static func get_lock_color(color_name: String) -> Color:
	if color_name == "red":
		return Color(0.86, 0.20, 0.22)
	elif color_name == "violet":
		return Color(0.60, 0.24, 0.78)
	return Color(0.85, 0.68, 0.22)

static func render_columns(game_node: Control) -> void:
	var num_cols: int = game_node.tableau_columns.size()
	var col_w: int = int(660 / max(1, num_cols)) - 10

	for col_idx in range(num_cols):
		var col_vbox = VBoxContainer.new()
		col_vbox.custom_minimum_size = Vector2(col_w, 720)
		col_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_vbox.add_theme_constant_override("separation", 4)
		game_node.columns_box.add_child(col_vbox)

		var col: Array = game_node.tableau_columns[col_idx]

		if col.is_empty():
			var empty_slot = Panel.new()
			empty_slot.custom_minimum_size = Vector2(col_w, 85)
			empty_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.04, 0.10, 0.08, 0.55)
			sb.border_color = Color(0.76, 0.58, 0.22, 0.30)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(12)
			empty_slot.add_theme_stylebox_override("panel", sb)

			col_vbox.add_child(empty_slot)
			continue

		var i := 0
		while i < col.size():
			var card: Dictionary = col[i]

			if not card["face_up"]:
				var back_btn = Button.new()
				back_btn.custom_minimum_size = Vector2(col_w, 66)
				back_btn.text = "❖"
				back_btn.disabled = true
				col_vbox.add_child(back_btn)
				i += 1
				continue

			var open_cards: Array = []
			var j := i
			while j < col.size() and col[j]["face_up"]:
				open_cards.append(col[j])
				j += 1

			var last_idx := j - 1
			var is_bottom_block := (last_idx == col.size() - 1)
			var total_open := open_cards.size()

			var y_positions: Array = []
			var cur_y := 0
			for k in range(total_open):
				y_positions.append(cur_y)
				if k < total_open - 1:
					var cur_cat: String = open_cards[k]["cat_id"]
					var next_cat: String = open_cards[k + 1]["cat_id"]
					if cur_cat == "JOKER":
						cur_y += 60
					elif next_cat == "JOKER":
						cur_y += 81
					else:
						cur_y += 42

			var last_card_h := 64 if open_cards.back()["cat_id"] == "JOKER" else 85
			var total_height := cur_y + last_card_h

			var top_card: Dictionary = open_cards.back()
			var top_cat: String = top_card["cat_id"]
			var top_locked: bool = (top_card.get("locked_color", "") != "")
			var active_group_size := 0
			var active_start_idx := total_open
			if top_cat != "JOKER" and not top_locked:
				for k in range(total_open - 1, -1, -1):
					if open_cards[k]["cat_id"] == top_cat and open_cards[k].get("locked_color", "") == "":
						active_group_size += 1
						active_start_idx = k
					else:
						break

			var stack_box = Control.new()
			stack_box.custom_minimum_size = Vector2(col_w, total_height)

			var drag_start_idx: int = active_start_idx
			if is_bottom_block and top_cat != "JOKER" and not top_locked and drag_start_idx > 0 and open_cards[drag_start_idx - 1]["cat_id"] == "JOKER":
				drag_start_idx -= 1

			var drag_group_box = Control.new()
			var active_y: int = y_positions[drag_start_idx] if (is_bottom_block and top_cat != "JOKER" and not top_locked) else 0
			drag_group_box.position = Vector2(0, active_y)
			drag_group_box.size = Vector2(col_w, total_height - active_y)

			for k in range(total_open):
				var c_data: Dictionary = open_cards[k]
				var is_joker_card: bool = (c_data["cat_id"] == "JOKER")
				var c_h := 64 if is_joker_card else 85
				var lock_col_name: String = c_data.get("locked_color", "")
				var key_col_name: String = c_data.get("key_color", "")

				var card_visual = Button.new()
				card_visual.size = Vector2(col_w, c_h)
				card_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

				# 1. Карточка-тема (золотая рамка + корона сверху)
				if c_data.get("is_theme", false):
					var inner_line = Panel.new()
					inner_line.set_anchors_preset(Control.PRESET_FULL_RECT)
					inner_line.offset_left = 5
					inner_line.offset_top = 5
					inner_line.offset_right = -5
					inner_line.offset_bottom = -5
					inner_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
					var inner_sb = StyleBoxFlat.new()
					inner_sb.bg_color = Color(0, 0, 0, 0)
					inner_sb.border_color = Color(0.88, 0.67, 0.16, 0.95)
					inner_sb.set_border_width_all(2)
					inner_sb.set_corner_radius_all(8)
					inner_line.add_theme_stylebox_override("panel", inner_sb)
					card_visual.add_child(inner_line)

					var t_crown = Label.new()
					t_crown.text = "♛"
					t_crown.position = Vector2(0, 6)
					t_crown.size = Vector2(col_w, 24)
					t_crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					t_crown.add_theme_font_size_override("font_size", 18)
					t_crown.add_theme_color_override("font_color", Color(0.82, 0.58, 0.12))
					t_crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
					card_visual.add_child(t_crown)

					for c_info in [
						["╔", Control.PRESET_TOP_LEFT, Vector2(6, 2)],
						["╗", Control.PRESET_TOP_RIGHT, Vector2(-17, 2)],
						["╚", Control.PRESET_BOTTOM_LEFT, Vector2(6, -19)],
						["╝", Control.PRESET_BOTTOM_RIGHT, Vector2(-17, -19)]
					]:
						var c_lbl = Label.new()
						c_lbl.text = c_info[0]
						c_lbl.set_anchors_preset(c_info[1])
						c_lbl.offset_left = c_info[2].x
						c_lbl.offset_top = c_info[2].y
						c_lbl.add_theme_font_size_override("font_size", 10)
						c_lbl.add_theme_color_override("font_color", Color(0.78, 0.56, 0.12, 0.9))
						c_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
						card_visual.add_child(c_lbl)

				# 2. Запертая карта (цветная рамка + замок 🔒)
				if lock_col_name != "":
					var l_col: Color = get_lock_color(lock_col_name)
					var lock_sb = StyleBoxFlat.new()
					lock_sb.bg_color = Color(0.95, 0.91, 0.82).lerp(l_col, 0.14)
					lock_sb.border_color = l_col
					lock_sb.set_border_width_all(4)
					lock_sb.set_corner_radius_all(12)
					card_visual.add_theme_stylebox_override("normal", lock_sb)

					var lock_icon = Label.new()
					lock_icon.text = "🔒"
					lock_icon.position = Vector2(6, 4)
					lock_icon.size = Vector2(28, 22)
					lock_icon.add_theme_font_size_override("font_size", 14)
					lock_icon.add_theme_color_override("font_color", l_col)
					lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
					card_visual.add_child(lock_icon)

				# 3. Карта с ключом (цветной ключик 🗝 сверху)
				if key_col_name != "":
					var k_col: Color = get_lock_color(key_col_name)
					var key_badge = Label.new()
					key_badge.text = "🗝"
					key_badge.position = Vector2(0, 3)
					key_badge.size = Vector2(col_w, 22)
					key_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					key_badge.add_theme_font_size_override("font_size", 16)
					key_badge.add_theme_color_override("font_color", k_col)
					key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
					card_visual.add_child(key_badge)

				var is_locked_by_joker: bool = false
				for m in range(k + 1, total_open):
					if open_cards[m]["cat_id"] == "JOKER":
						is_locked_by_joker = true
						break
				if is_locked_by_joker:
					card_visual.modulate = Color(0.65, 0.65, 0.65, 0.55)
					card_visual.add_to_group("locked_col_" + str(col_idx))

				var w_lbl = Label.new()
				w_lbl.text = str(c_data["word"])
				w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				w_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				w_lbl.add_theme_font_size_override("font_size", 16 if num_cols >= 5 else 18)
				w_lbl.add_theme_color_override("font_color", Color(0.14, 0.09, 0.05))
				w_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

				var overlapped_by_same: bool = (k < total_open - 1 and not is_joker_card and open_cards[k + 1]["cat_id"] == c_data["cat_id"])
				if overlapped_by_same:
					w_lbl.position = Vector2(4, 9)
					w_lbl.size = Vector2(col_w - 8, 28)
				else:
					var y_shift: int = 12 if (c_data.get("is_theme", false) or key_col_name != "") else 0
					w_lbl.position = Vector2(4, y_shift)
					w_lbl.size = Vector2(col_w - 8, c_h - y_shift)
				card_visual.add_child(w_lbl)

				if k == active_start_idx and active_group_size > 1:
					var slot: Dictionary = game_node.category_slots[top_cat]
					var badge = Label.new()
					badge.text = str(active_group_size) + "/" + str(slot["total"])
					badge.position = Vector2(col_w - 64, 3)
					badge.size = Vector2(56, 20)
					badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					badge.add_theme_font_size_override("font_size", 13)
					badge.add_theme_color_override("font_color", Color(0.38, 0.28, 0.16))
					badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
					card_visual.add_child(badge)

				if is_bottom_block and top_cat != "JOKER" and not top_locked and k >= drag_start_idx:
					card_visual.position = Vector2(0, y_positions[k] - active_y)
					drag_group_box.add_child(card_visual)
				else:
					card_visual.position = Vector2(0, y_positions[k])
					stack_box.add_child(card_visual)

			if is_bottom_block and top_cat != "JOKER":
				if top_locked:
					var lock_btn = Button.new()
					lock_btn.position = Vector2(0, y_positions[total_open - 1])
					lock_btn.size = Vector2(col_w, last_card_h)
					lock_btn.self_modulate = Color(1, 1, 1, 0)
					lock_btn.focus_mode = Control.FOCUS_NONE
					lock_btn.pressed.connect(func():
						var fx = load("res://scripts/fx_helper.gd")
						if fx:
							fx.shake_node(lock_btn.get_parent())
							fx.show_floating_toast(game_node, lock_btn.global_position + Vector2(-40, -30), "Заперто! Найди ключ 🗝", get_lock_color(top_card["locked_color"]))
					)
					stack_box.add_child(lock_btn)
				else:
					var hit_btn = Button.new()
					hit_btn.position = Vector2.ZERO
					hit_btn.size = drag_group_box.size
					hit_btn.self_modulate = Color(1, 1, 1, 0)
					hit_btn.focus_mode = Control.FOCUS_NONE
					hit_btn.pressed.connect(game_node._on_tableau_card_pressed.bind(col_idx, last_idx))
					var drag_data = {"source": "col", "col": col_idx, "idx": last_idx, "card": col[last_idx]}
					preload("res://scripts/drag_helper.gd").make_draggable(hit_btn, drag_data, game_node)
					drag_group_box.add_child(hit_btn)
					stack_box.add_child(drag_group_box)

			col_vbox.add_child(stack_box)
			i = j
