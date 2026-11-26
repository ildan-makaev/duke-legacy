extends Node

static func analyze_and_show(game_node: Control) -> void:
	var fx = load("res://scripts/fx_helper.gd")
	var rules = load("res://scripts/solitaire_rules.gd")
	var cols: Array = game_node.tableau_columns
	var cat_keys: Array = game_node.category_slots.keys()

	# 1. ПРИОРИТЕТ: Найти ход, который откроет закрытую карту в столбце
	for i in range(cols.size()):
		var col_a: Array = cols[i]
		if col_a.is_empty() or not col_a.back()["face_up"] or col_a.back()["cat_id"] == "JOKER":
			continue
		var grp_size: int = rules.get_top_group_count(col_a)
		var has_hidden_below: bool = (col_a.size() > grp_size)
		if not has_hidden_below:
			continue

		var cat_a: String = col_a.back()["cat_id"]
		var word_a: String = col_a.back()["word"]

		for j in range(cols.size()):
			if i == j:
				continue
			var col_b: Array = cols[j]
			if col_b.size() > 0 and col_b.back()["face_up"] and col_b.back()["cat_id"] == cat_a:
				var word_b: String = col_b.back()["word"]
				_highlight_col(game_node, i, fx)
				_highlight_col(game_node, j, fx)
				_toast(game_node, "Переложи «" + word_a + "» на «" + word_b + "»\n— откроешь скрытую карту!", fx)
				return

	# 2. ПРИОРИТЕТ: Убрать готовую пачку (2+ карт) или закрыть категорию целиком
	for i in range(cols.size()):
		var col: Array = cols[i]
		if col.is_empty() or not col.back()["face_up"] or col.back()["cat_id"] == "JOKER":
			continue
		var cid: String = col.back()["cat_id"]
		var grp_size: int = rules.get_top_group_count(col)
		var slot: Dictionary = game_node.category_slots[cid]
		var will_finish: bool = (slot["count"] + grp_size >= slot["total"])

		if grp_size >= 2 or will_finish:
			var c_idx := cat_keys.find(cid)
			if c_idx >= 0:
				_highlight_col(game_node, i, fx)
				fx.pulse_node(game_node.categories_box.get_child(c_idx))
				var reason: String = "закроешь тему «" + slot["title"] + "»!" if will_finish else "уберёшь связку в «" + slot["title"] + "»!"

				_toast(game_node, "Перетащи «" + col.back()["word"] + "» наверх\n— " + reason, fx)
				return

	# 3. ПРИОРИТЕТ: Использовать карту из колоды сброса (waste_pile)
	if not game_node.waste_pile.is_empty():
		var w_card: Dictionary = game_node.waste_pile.back()
		var w_cat: String = w_card["cat_id"]
		var w_word: String = w_card["word"]

		for i in range(cols.size()):
			var col: Array = cols[i]
			if col.size() > 0 and col.back()["face_up"] and col.back()["cat_id"] == w_cat:
				fx.pulse_node(game_node.btn_waste)
				_highlight_col(game_node, i, fx)
				_toast(game_node, "Соедини «" + w_word + "» со столбцом №" + str(i + 1) + "\n— соберёшь общую пачку!", fx)
				return

		for i in range(cols.size()):
			if cols[i].is_empty():
				fx.pulse_node(game_node.btn_waste)
				_highlight_col(game_node, i, fx)
				_toast(game_node, "Выложи «" + w_word + "» на пустой слот\n— освободишь колоду!", fx)
				return

	# 4. ПРИОРИТЕТ: Обычный одиночный ход в категорию или открытие колоды
	for i in range(cols.size()):
		var col: Array = cols[i]
		if col.size() > 0 and col.back()["face_up"] and col.back()["cat_id"] != "JOKER":
			var cid: String = col.back()["cat_id"]
			var c_idx := cat_keys.find(cid)
			if c_idx >= 0:
				_highlight_col(game_node, i, fx)
				fx.pulse_node(game_node.categories_box.get_child(c_idx))
				_toast(game_node, "Убери «" + col.back()["word"] + "» в «" + game_node.category_slots[cid]["title"] + "»", fx)
				return

	if game_node.stock_pile.size() > 0 or game_node.waste_pile.size() > 0:
		fx.pulse_node(game_node.btn_stock)
		_toast(game_node, "Нажми на КОЛОДУ\n— на столе пока нет выгодных ходов", fx)
	else:
		_toast(game_node, "Используй 🃏 ДЖОКЕР,\nчтобы разблокировать нужный столбец!", fx)

static func _highlight_col(game_node: Control, col_idx: int, fx) -> void:
	if col_idx < game_node.columns_box.get_child_count():
		var col_vbox: Control = game_node.columns_box.get_child(col_idx)
		if col_vbox.get_child_count() > 0:
			fx.pulse_node(col_vbox.get_child(col_vbox.get_child_count() - 1))

static func _toast(game_node: Control, msg: String, fx) -> void:
	if fx:
		fx.show_floating_toast(game_node, Vector2(120, 230), msg, Color(0.96, 0.86, 0.62))
