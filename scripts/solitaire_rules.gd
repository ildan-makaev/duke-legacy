extends Node

# Проверяет, сколько подряд открытых карт одной категории лежит внизу столбца
static func get_top_group_count(col: Array) -> int:
	if col.is_empty():
		return 0
	var top_card = col.back()
	if not top_card["face_up"]:
		return 0
	var target_cat = top_card["cat_id"]
	var count := 0
	for i in range(col.size() - 1, -1, -1):
		if col[i]["face_up"] and col[i]["cat_id"] == target_cat:
			count += 1
		else:
			break
	return count

# Попытка положить карту (или пачку карт) на другой столбец
static func try_move_to_column(target_col_idx: int, game_node: Control) -> bool:
	var sel: Dictionary = game_node.selected_card
	if sel.is_empty() or game_node.moves_left <= 0:
		return false

	var target_col: Array = game_node.tableau_columns[target_col_idx]
	var moving_card: Dictionary = sel["card"]

	# Нельзя класть столбец сам на себя
	if sel["source"] == "col" and sel["col"] == target_col_idx:
		return false

	# Правило: можно положить на пустой столбец ИЛИ на карту ТОЙ ЖЕ категории
	var can_place := false
	if target_col.is_empty():
		can_place = true
	elif target_col.back()["face_up"] and target_col.back()["cat_id"] == moving_card["cat_id"]:
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
		var moved_cards = src_col.slice(start_idx, src_col.size())
		for _i in range(group_size):
			src_col.pop_back()
		target_col.append_array(moved_cards)
		# Открываем нижнюю закрытую карту в освободившемся столбце
		if src_col.size() > 0:
			src_col.back()["face_up"] = true

	game_node.selected_card = {}
	return true
