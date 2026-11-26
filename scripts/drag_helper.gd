extends Node

static func make_draggable(card_btn: Button, card_data: Dictionary, game_node: Control) -> void:
	var state := {"dragging": false, "ghost": null, "start_pos": Vector2.ZERO}

	card_btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Если это карта из сброса, берём актуальную верхнюю карту
				var actual_data = card_data
				if card_data.get("source") == "waste":
					if game_node.waste_pile.is_empty():
						return
					actual_data = {"source": "waste", "card": game_node.waste_pile.back()}

				state["dragging"] = true
				state["start_pos"] = card_btn.global_position
				game_node.selected_card = actual_data

				var ghost = Button.new()
				ghost.text = card_btn.text
				ghost.size = card_btn.size
				ghost.global_position = card_btn.global_position
				ghost.scale = Vector2(1.08, 1.08)
				ghost.z_index = 100
				ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
				game_node.add_child(ghost)
				state["ghost"] = ghost
				card_btn.modulate.a = 0.35
			else:
				if state["dragging"]:
					state["dragging"] = false
					card_btn.modulate.a = 1.0
					var ghost: Button = state["ghost"]
					state["ghost"] = null
					if is_instance_valid(ghost):
						var drop_pos = ghost.get_global_rect().get_center()
						var hit_cat := _find_category_at(drop_pos, game_node)
						var hit_col := _find_column_at(drop_pos, game_node)

						if hit_cat != "":
							ghost.queue_free()
							game_node._on_category_pressed(hit_cat)
						elif hit_col != -1:
							ghost.queue_free()
							var rules = preload("res://scripts/solitaire_rules.gd")
							if rules.try_move_to_column(hit_col, game_node):
								game_node.check_lose()
								game_node.refresh_ui()
							else:
								game_node.selected_card = {}
								game_node.refresh_ui()
						else:
							var tw = game_node.create_tween()
							tw.tween_property(ghost, "global_position", state["start_pos"], 0.18).set_trans(Tween.TRANS_QUAD)
							tw.chain().tween_callback(func():
								if is_instance_valid(ghost):
									ghost.queue_free()
								game_node.refresh_ui()
							)

		elif event is InputEventMouseMotion and state["dragging"]:
			var ghost: Button = state["ghost"]
			if is_instance_valid(ghost):
				ghost.global_position = event.global_position - ghost.size / 2.0
				var over_cat := _find_category_at(event.global_position, game_node)
				_highlight_categories(over_cat, game_node)
	)

static func _find_category_at(pos: Vector2, game_node: Control) -> String:
	var cat_keys: Array = game_node.category_slots.keys()
	var box: HBoxContainer = game_node.categories_box
	for i in range(box.get_child_count()):
		var btn: Control = box.get_child(i)
		if btn.get_global_rect().grow(12.0).has_point(pos) and i < cat_keys.size():
			return cat_keys[i]
	return ""

static func _find_column_at(pos: Vector2, game_node: Control) -> int:
	var box: HBoxContainer = game_node.columns_box
	for i in range(box.get_child_count()):
		var col_vbox: Control = box.get_child(i)
		if col_vbox.get_global_rect().grow(10.0).has_point(pos):
			return i
	return -1

static func _highlight_categories(active_cat: String, game_node: Control) -> void:
	var cat_keys: Array = game_node.category_slots.keys()
	var box: HBoxContainer = game_node.categories_box
	for i in range(box.get_child_count()):
		var btn: Control = box.get_child(i)
		if i < cat_keys.size() and cat_keys[i] == active_cat:
			btn.modulate = Color(1.15, 1.05, 0.7)
		else:
			var slot = game_node.category_slots[cat_keys[i]]
			btn.modulate = Color(0.4, 1.0, 0.5) if slot["count"] >= slot["total"] else Color.WHITE
