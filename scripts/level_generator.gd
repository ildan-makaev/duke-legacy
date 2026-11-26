extends Node

const DB_PATH := "res://data/themes_db.json"
static var cached_pool: Array = []
static var recent_ids: Array = []

static func _load_pool() -> Array:
	if not cached_pool.is_empty():
		return cached_pool
	if FileAccess.file_exists(DB_PATH):
		var file = FileAccess.open(DB_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array and parsed.size() > 0:
			cached_pool = parsed
			return cached_pool
	return [
		{"id": "MANOR", "domain": "nobility", "title": "УСАДЬБА", "items": ["Камин", "Дворецкий", "Герб", "Библиотека"]},
		{"id": "SAVANNA", "domain": "animals", "title": "САВАННА", "items": ["Жираф", "Зебра", "Гепард", "Носорог"]},
		{"id": "COSMOS", "domain": "science", "title": "КОСМОС", "items": ["Сатурн", "Комета", "Телескоп", "Галактика"]}
	]

static func get_level_tier(level_num: int) -> String:
	if level_num <= 5:
		return "normal"
	if level_num == 6:
		return "hard"
	if level_num == 7:
		return "normal"
	var cycle: int = (level_num - 8) % 6
	if cycle == 1 or cycle == 5:
		return "hard"
	elif cycle == 3:
		return "honor"
	return "normal"

static func generate_level(level_num: int) -> Dictionary:
	var pool: Array = _load_pool()
	var tier: String = get_level_tier(level_num)
	var cat_count: int = 3
	var moves: int = 38
	var lock_colors: Array = []

	if tier == "hard":
		cat_count = 4
		moves = 48
		lock_colors = ["red"]
	elif tier == "honor":
		cat_count = 5
		moves = 60
		lock_colors = ["red", "violet"]

	var avail: Array = []
	for t in pool:
		if not recent_ids.has(t["id"]):
			avail.append(t)
	if avail.size() < cat_count * 2:
		recent_ids.clear()
		avail = pool.duplicate()

	avail.shuffle()
	var chosen_raw: Array = []
	var used_domains: Array = []

	# На первых 5 уровнях добавляем 1 аристократическую тему через уровень (1, 3, 5)
	if level_num <= 5 and (level_num % 2 == 1):
		for t in avail:
			if t.get("domain", "") == "nobility":
				chosen_raw.append(t)
				used_domains.append("nobility")
				break

	# На сложных уровнях намеренно берём 1 пару близких тем из одной смысловой группы (ловушка!)
	if tier != "normal" and chosen_raw.is_empty():
		var domain_map: Dictionary = {}
		for t in avail:
			var d: String = t.get("domain", "general")
			if not domain_map.has(d):
				domain_map[d] = []
			domain_map[d].append(t)
		var pair_domains: Array = []
		for d in domain_map.keys():
			if domain_map[d].size() >= 2:
				pair_domains.append(d)
		if not pair_domains.is_empty():
			pair_domains.shuffle()
			var trap_domain: String = pair_domains[0]
			var pair_list: Array = domain_map[trap_domain]
			pair_list.shuffle()
			chosen_raw.append(pair_list[0])
			chosen_raw.append(pair_list[1])
			used_domains.append(trap_domain)

	# Остальные темы строго из РАЗНЫХ смысловых групп (чтобы не путать игрока!)
	for t in avail:
		if chosen_raw.size() >= cat_count:
			break
		var already_id := false
		for c in chosen_raw:
			if c["id"] == t["id"]:
				already_id = true
				break
		if already_id:
			continue
		var d: String = t.get("domain", "general")
		if not used_domains.has(d):
			chosen_raw.append(t)
			used_domains.append(d)

	# Запасной добор, если вдруг не хватило уникальных групп
	for t in avail:
		if chosen_raw.size() >= cat_count:
			break
		var already_id := false
		for c in chosen_raw:
			if c["id"] == t["id"]:
				already_id = true
				break
		if not already_id:
			chosen_raw.append(t)

	chosen_raw.shuffle()
	var chosen_cats: Array = []
	for i in range(chosen_raw.size()):
		var raw: Dictionary = chosen_raw[i]
		recent_ids.append(raw["id"])
		if recent_ids.size() > 24:
			recent_ids.pop_front()
		var w_list: Array = raw["items"].duplicate()
		w_list.shuffle()
		var take_count: int = 4 if (i % 2 == 0) else 5
		chosen_cats.append({
			"id": raw["id"],
			"title": raw["title"],
			"items": w_list.slice(0, min(take_count, w_list.size()))
		})

	return {
		"moves": moves,
		"difficulty": tier,
		"lock_colors": lock_colors,
		"categories": chosen_cats
	}

static func apply_locks_and_keys(tableau_columns: Array, stock_pile: Array, lock_colors: Array) -> void:
	if lock_colors.is_empty():
		return

	for l_color in lock_colors:
		var lock_candidates: Array = []
		for col_idx in range(tableau_columns.size()):
			var col: Array = tableau_columns[col_idx]
			for row_idx in range(col.size()):
				var c: Dictionary = col[row_idx]
				if c.get("face_up", false) and not c.get("is_theme", false) and c.get("locked_color", "") == "" and c.get("key_color", "") == "":
					lock_candidates.append({"col": col_idx, "card": c})

		if lock_candidates.is_empty():
			continue

		lock_candidates.shuffle()
		var chosen_lock: Dictionary = lock_candidates[0]
		var locked_col: int = chosen_lock["col"]
		var lock_card: Dictionary = chosen_lock["card"]

		var key_candidates: Array = []
		for col_idx in range(tableau_columns.size()):
			if col_idx == locked_col:
				continue
			var col: Array = tableau_columns[col_idx]
			for c in col:
				if not c.get("is_theme", false) and c.get("locked_color", "") == "" and c.get("key_color", "") == "":
					key_candidates.append(c)

		for c in stock_pile:
			if not c.get("is_theme", false) and c.get("locked_color", "") == "" and c.get("key_color", "") == "":
				key_candidates.append(c)

		if key_candidates.is_empty():
			continue

		key_candidates.shuffle()
		var key_card: Dictionary = key_candidates[0]

		lock_card["locked_color"] = l_color
		key_card["key_color"] = l_color
