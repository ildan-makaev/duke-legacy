extends Node

static func get_top_group_count(col: Array) -> int:
	if col.is_empty():
		return 0
	var top_card: Dictionary = col.back()
	if not top_card["face_up"] or top_card["cat_id"] == "JOKER" or top_card.get("locked_color", "") != "":
		return 0
	if top_card.get("is_theme", false):
		return 1
	var target_cat: String = top_card["cat_id"]
	var count := 0
	for i in range(col.size() - 1, -1, -1):
		if col[i]["face_up"] and col[i]["cat_id"] == target_cat and not col[i].get("is_theme", false) and col[i].get("locked_color", "") == "":
			count += 1
		else:
			break
	return count

static func try_place_joker(target_col_idx: int, game_node: Control) -> bool:
	if GameManager.pounds < 50:
		return false
	var target_col: Array = game_node.tableau_columns[target_col_idx]
	if target_col.size() > 0 and target_col.back().get("locked_color", "") != "":
		var fx = load("res://scripts/fx_helper.gd")
		if fx and target_col_idx < game_node.columns_box.get_child_count():
			fx.shake_node(game_node.columns_box.get_child(target_col_idx))
			fx.show_floating_toast(game_node, Vector2(210, 380), "Сначала сними замок 🔒!", Color(0.88, 0.30, 0.32))
		return false

	GameManager.pounds -= 50
	if GameManager.has_method("save_game"):
		GameManager.save_game()
	target_col.append({"word": "🃏 ДЖОКЕР", "cat_id": "JOKER", "face_up": true})
	game_node.selected_card = {}
	return true

static func try_move_to_column(target_col_idx: int, game_node: Control) -> bool:
	var sel: Dictionary = game_node.selected_card
	if sel.is_empty() or game_node.moves_left <= 0:
		return false
	if sel.get("source") == "joker":
		return try_place_joker(target_col_idx, game_node)
	if not sel.has("card"):
		return false

	var target_col: Array = game_node.tableau_columns[target_col_idx]
	var moving_card: Dictionary = sel["card"]

	if moving_card.get("locked_color", "") != "":
		return false

	if sel["source"] == "col" and sel["col"] == target_col_idx:
		return false

	var can_place := false
	if target_col.is_empty():
		can_place = true
	else:
		var top_target: Dictionary = target_col.back()
		if top_target["face_up"] and not top_target.get("is_theme", false) and top_target.get("locked_color", "") == "":
			if top_target["cat_id"] == moving_card["cat_id"] or top_target["cat_id"] == "JOKER":
				can_place = true

	if not can_place:
		return false

	game_node.moves_left -= 1

	if sel["source"] == "waste":
		var c = game_node.waste_pile.pop_back()
		target_col.append(c)
	elif sel["source"] == "col":
		var src_col: Array = game_node.tableau_columns[sel["col"]]
		var group_size = get_top_group_count(src_col)
		var start_idx = src_col.size() - group_size
		if start_idx > 0 and src_col[start_idx - 1]["cat_id"] == "JOKER":
			start_idx -= 1
		var total_to_move = src_col.size() - start_idx
		var moved_cards = src_col.slice(start_idx, src_col.size())
		for _i in range(total_to_move):
			src_col.pop_back()
		target_col.append_array(moved_cards)
		if src_col.size() > 0:
			src_col.back()["face_up"] = true
	game_node.selected_card = {}
	return true
