extends Node

static func make_draggable(card_btn: Button, card_data: Dictionary, game_node: Control) -> void:
	var state := {"dragging": false, "ghost": null, "hidden_node": null}

	card_btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var is_joker: bool = (card_data.get("source") == "joker")

				if is_joker and GameManager.pounds < 50:
					var fx = load("res://scripts/fx_helper.gd")
					if fx:
						fx.shake_node(card_btn)
						fx.show_floating_toast(game_node, card_btn.global_position + Vector2(-95, 75), "Нужно £ 50!", Color(0.85, 0.35, 0.32))
					return

				var actual_data = card_data
				if card_data.get("source") == "waste":
					if game_node.waste_pile.is_empty():
						return
					actual_data = {"source": "waste", "card": game_node.waste_pile.back()}

				state["dragging"] = true
				game_node.selected_card = actual_data

				var source_node: Control = card_btn.get_parent() if card_data.get("source") == "col" else card_btn
				var ghost: Control = source_node.duplicate()
				if is_joker and ghost is Button:
					ghost.text = "🃏 ДЖОКЕР"
				ghost.global_position = source_node.global_position
				ghost.z_index = 100
				ghost.scale = Vector2(1.05, 1.05)
				_disable_mouse_recursive(ghost)
				game_node.add_child(ghost)
				state["ghost"] = ghost

				if not is_joker:
					state["hidden_node"] = source_node
					source_node.modulate.a = 0.0
					# Оживляем нижнюю карту под Джокером, пока тащим связку
					if card_data.get("source") == "col":
						for locked_card in game_node.get_tree().get_nodes_in_group("locked_col_" + str(card_data.get("col"))):
							locked_card.modulate = Color.WHITE
			else:
				if state["dragging"]:
					state["dragging"] = false
					if is_instance_valid(state["hidden_node"]):
						state["hidden_node"].modulate.a = 1.0
					# Если бросили обратно — возвращаем нижней карте полупрозрачность
					if card_data.get("source") == "col":
						for locked_card in game_node.get_tree().get_nodes_in_group("locked_col_" + str(card_data.get("col"))):
							locked_card.modulate = Color(0.65, 0.65, 0.65, 0.55)

					var ghost: Control = state["ghost"]
					state["ghost"] = null
					if is_instance_valid(ghost):
						var drop_pos = ghost.get_global_rect().get_center()
						var hit_cat := _find_category_at(drop_pos, game_node)
						var hit_col := _find_column_at(drop_pos, game_node)

						_highlight_categories("", game_node)
						ghost.queue_free()

						if card_data.get("source") == "joker":
							if hit_col != -1:
								var rules = load("res://scripts/solitaire_rules.gd")
								if rules and rules.try_place_joker(hit_col, game_node):
									game_node.refresh_ui()
						elif hit_cat != "":
							game_node._on_category_pressed(hit_cat)
						elif hit_col != -1:
							var rules = load("res://scripts/solitaire_rules.gd")
							if rules and rules.try_move_to_column(hit_col, game_node):
								game_node.check_lose()
								game_node.refresh_ui()
							else:
								game_node.selected_card = {}
								game_node.refresh_ui()
						else:
							game_node.selected_card = {}
							game_node.refresh_ui()

		elif event is InputEventMouseMotion and state["dragging"]:
			var ghost: Control = state["ghost"]
			if is_instance_valid(ghost):
				ghost.global_position = event.global_position - ghost.size / 2.0
				var over_cat := _find_category_at(event.global_position, game_node)
				_highlight_categories(over_cat, game_node)
	)

static func _disable_mouse_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_recursive(child)

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
		var rect := col_vbox.get_global_rect().grow(10.0)
		rect.size.y = max(rect.size.y, 400.0)
		if rect.has_point(pos):
			return i
	return -1

static func _highlight_categories(active_cat: String, game_node: Control) -> void:
	var cat_keys: Array = game_node.category_slots.keys()
	var box: HBoxContainer = game_node.categories_box
	for i in range(box.get_child_count()):
		var btn: Control = box.get_child(i)
		var slot = game_node.category_slots[cat_keys[i]]
		btn.modulate = Color(1.0, 1.0, 1.0, 0.35) if slot["count"] >= slot["total"] else Color.WHITE
		if i < cat_keys.size() and cat_keys[i] == active_cat:
			btn.position.y = -5.0
		else:
			btn.position.y = 0.0
