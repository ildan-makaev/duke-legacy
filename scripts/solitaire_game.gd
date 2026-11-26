extends Control

var moves_left: int = 38
var stock_pile: Array = []
var waste_pile: Array = []
var tableau_columns: Array = []
var category_slots: Dictionary = {}
var selected_card: Dictionary = {}

var lbl_pounds: Label
var lbl_gold: Label
var lbl_level: Label
var lbl_moves: Label
var btn_stock: Button
var btn_waste: Button
var categories_box: HBoxContainer
var columns_box: HBoxContainer
var popup_panel: PanelContainer
var popup_text: Label
var btn_hint: Button

var main_menu_layer: Control
var tier_badge_panel: PanelContainer
var lbl_tier_info: Label
var lbl_menu_stats: Label

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create_duke_theme()
	build_ui()
	build_main_menu()
	start_level(GameManager.current_level)
	YandexSdk.rewarded_success.connect(_on_rewarded_ad_done)

func build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.22, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	top_bar.size = Vector2(680, 60)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 20)
	add_child(top_bar)

	var btn_menu = Button.new()
	btn_menu.text = "☰ Меню"
	btn_menu.custom_minimum_size = Vector2(115, 48)
	btn_menu.focus_mode = Control.FOCUS_NONE
	btn_menu.add_theme_font_size_override("font_size", 16)
	btn_menu.pressed.connect(func():
		if is_instance_valid(main_menu_layer):
			update_main_menu_ui()
			main_menu_layer.visible = true
	)
	top_bar.add_child(btn_menu)

	lbl_pounds = create_badge(top_bar, "£ 100", Color(0.85, 0.68, 0.2))
	lbl_gold = create_badge(top_bar, "Слитки: 1", Color(0.95, 0.8, 0.3))
	lbl_level = create_badge(top_bar, "Ур. 1", Color(0.9, 0.9, 0.9))

	var deck_area = HBoxContainer.new()
	deck_area.position = Vector2(20, 100)
	deck_area.size = Vector2(680, 130)
	deck_area.add_theme_constant_override("separation", 10)
	add_child(deck_area)

	lbl_moves = Label.new()
	lbl_moves.custom_minimum_size = Vector2(105, 115)
	lbl_moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_moves.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_moves.add_theme_font_size_override("font_size", 26)
	deck_area.add_child(lbl_moves)

	btn_stock = Button.new()
	btn_stock.text = "КОЛОДА\n(Взять)"
	btn_stock.custom_minimum_size = Vector2(130, 115)
	btn_stock.pressed.connect(_on_stock_pressed)
	deck_area.add_child(btn_stock)

	btn_waste = Button.new()
	btn_waste.text = "Пусто"
	btn_waste.custom_minimum_size = Vector2(130, 115)
	btn_waste.focus_mode = Control.FOCUS_NONE
	btn_waste.pressed.connect(_on_waste_pressed)
	load("res://scripts/drag_helper.gd").make_draggable(btn_waste, {"source": "waste"}, self)
	deck_area.add_child(btn_waste)

	btn_hint = Button.new()
	btn_hint.text = "💡 Совет\n(£ 50)"
	btn_hint.custom_minimum_size = Vector2(115, 115)
	btn_hint.focus_mode = Control.FOCUS_NONE
	btn_hint.add_theme_font_size_override("font_size", 16)
	btn_hint.pressed.connect(_on_hint_pressed)
	deck_area.add_child(btn_hint)

	var btn_joker = Button.new()
	btn_joker.text = "🃏 Джокер\n(£ 50)"
	btn_joker.custom_minimum_size = Vector2(115, 115)
	btn_joker.focus_mode = Control.FOCUS_NONE
	btn_joker.add_theme_font_size_override("font_size", 16)
	btn_joker.pressed.connect(func():
		var fx = load("res://scripts/fx_helper.gd")
		if not fx:
			return
		if GameManager.pounds < 50:
			fx.shake_node(btn_joker)
			fx.show_floating_toast(self, btn_joker.global_position + Vector2(-95, 75), "Нужно £ 50!", Color(0.85, 0.35, 0.32))
		else:
			fx.show_floating_toast(self, btn_joker.global_position + Vector2(-115, 75), "Перетащи Джокер\nна любой столбец!", Color(0.95, 0.85, 0.6))
	)
	load("res://scripts/drag_helper.gd").make_draggable(btn_joker, {"source": "joker"}, self)
	deck_area.add_child(btn_joker)

	categories_box = HBoxContainer.new()
	categories_box.position = Vector2(25, 255)
	categories_box.size = Vector2(670, 140)
	categories_box.alignment = BoxContainer.ALIGNMENT_CENTER
	categories_box.add_theme_constant_override("separation", 15)
	add_child(categories_box)

	columns_box = HBoxContainer.new()
	columns_box.position = Vector2(25, 425)
	columns_box.size = Vector2(670, 800)
	columns_box.alignment = BoxContainer.ALIGNMENT_CENTER
	columns_box.add_theme_constant_override("separation", 15)
	add_child(columns_box)

	popup_panel = PanelContainer.new()
	popup_panel.position = Vector2(110, 480)
	popup_panel.size = Vector2(500, 300)
	popup_panel.visible = false
	popup_panel.z_index = 40
	add_child(popup_panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	popup_panel.add_child(vbox)

	popup_text = Label.new()
	popup_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_text.add_theme_font_size_override("font_size", 26)
	vbox.add_child(popup_text)

	var btn_next = Button.new()
	btn_next.text = "Продолжить"
	btn_next.custom_minimum_size = Vector2(220, 60)
	btn_next.pressed.connect(func():
		popup_panel.visible = false
		if is_instance_valid(main_menu_layer):
			update_main_menu_ui()
			main_menu_layer.visible = true
	)

	vbox.add_child(btn_next)

func build_main_menu() -> void:
	main_menu_layer = Control.new()
	main_menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_menu_layer.z_index = 90
	add_child(main_menu_layer)

	var menu_bg = ColorRect.new()
	menu_bg.color = Color(0.05, 0.14, 0.10, 0.98)
	menu_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_menu_layer.add_child(menu_bg)

	var center_box = VBoxContainer.new()
	center_box.position = Vector2(85, 230)
	center_box.size = Vector2(550, 740)
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 24)
	main_menu_layer.add_child(center_box)

	var title_lbl = Label.new()
	title_lbl.text = "♛ НАСЛЕДИЕ ГЕРЦОГА ♛"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 38)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35))
	center_box.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Аристократический словесный пасьянс"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 20)
	sub_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	center_box.add_child(sub_lbl)

	lbl_menu_stats = Label.new()
	lbl_menu_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_menu_stats.add_theme_font_size_override("font_size", 22)
	lbl_menu_stats.add_theme_color_override("font_color", Color(0.92, 0.85, 0.65))
	center_box.add_child(lbl_menu_stats)

	var btn_play = Button.new()
	btn_play.text = "♠  ИГРАТЬ  ♠"
	btn_play.custom_minimum_size = Vector2(420, 96)
	btn_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_play.focus_mode = Control.FOCUS_NONE
	btn_play.add_theme_font_size_override("font_size", 28)
	btn_play.pressed.connect(func():
		main_menu_layer.visible = false
		start_level(GameManager.current_level)
	)
	center_box.add_child(btn_play)

	tier_badge_panel = PanelContainer.new()
	tier_badge_panel.custom_minimum_size = Vector2(420, 76)
	tier_badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_box.add_child(tier_badge_panel)

	lbl_tier_info = Label.new()
	lbl_tier_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tier_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_tier_info.add_theme_font_size_override("font_size", 19)
	tier_badge_panel.add_child(lbl_tier_info)
	var btn_ad_coins = Button.new()
	btn_ad_coins.text = "🎬 +1000 £ (Реклама)"
	btn_ad_coins.custom_minimum_size = Vector2(420, 68)
	btn_ad_coins.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_ad_coins.focus_mode = Control.FOCUS_NONE
	btn_ad_coins.add_theme_font_size_override("font_size", 21)
	btn_ad_coins.pressed.connect(func():
		YandexSdk.show_rewarded_ad("free_1000")
	)
	center_box.add_child(btn_ad_coins)

	update_main_menu_ui()

func update_main_menu_ui() -> void:
	if not is_instance_valid(tier_badge_panel):
		return
	var lvl: int = GameManager.current_level
	lbl_menu_stats.text = "Уровень: " + str(lvl) + "   |   £ " + str(GameManager.pounds) + "   |   Слитки: " + str(GameManager.gold_bars)

	var gen = load("res://scripts/level_generator.gd")
	var tier: String = gen.get_level_tier(lvl) if gen else "normal"

	var border_col := Color(0.85, 0.68, 0.22)
	var tier_txt := "Уровень " + str(lvl) + ": ОБЫЧНЫЙ\n(3 темы • без замков)"

	if tier == "hard":
		border_col = Color(0.86, 0.20, 0.22)
		tier_txt = "Уровень " + str(lvl) + ": СЛОЖНЫЙ\n(4 темы • красный замок 🔒)"
	elif tier == "honor":
		border_col = Color(0.62, 0.26, 0.78)
		tier_txt = "Уровень " + str(lvl) + ": ЭКСПЕРТ\n(5 тем • 2 цветных замка 🔒)"

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.16, 0.13)
	sb.border_color = border_col
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)

	tier_badge_panel.add_theme_stylebox_override("panel", sb)
	lbl_tier_info.text = tier_txt
	lbl_tier_info.add_theme_color_override("font_color", Color(0.95, 0.91, 0.82))

func create_badge(parent: Node, txt: String, col: Color) -> Label:
	var lbl = Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 22)
	parent.add_child(lbl)
	return lbl

func start_level(lvl_num: int) -> void:
	var gen = load("res://scripts/level_generator.gd")
	var data: Dictionary = gen.generate_level(lvl_num)
	moves_left = data["moves"]
	selected_card = {}
	waste_pile.clear()
	category_slots.clear()

	var all_cards: Array = []
	for cat in data["categories"]:
		category_slots[cat["id"]] = {
			"title": cat["title"],
			"count": 0,
			"total": cat["items"].size(),
			"unlocked": false
		}
		all_cards.append({
			"word": cat["title"],
			"cat_id": cat["id"],
			"is_theme": true,
			"face_up": false
		})
		for item in cat["items"]:
			all_cards.append({
				"word": item,
				"cat_id": cat["id"],
				"is_theme": false,
				"face_up": false
			})
	all_cards.shuffle()

	var cols_count: int = data["categories"].size()
	tableau_columns.clear()
	for _c in range(cols_count):
		tableau_columns.append([])
	for col_idx in range(cols_count):
		for row in range(col_idx + 1):
			if all_cards.size() > 0:
				var c = all_cards.pop_back()
				if row == col_idx:
					c["face_up"] = true
				tableau_columns[col_idx].append(c)

	stock_pile = all_cards
	gen.apply_locks_and_keys(tableau_columns, stock_pile, data.get("lock_colors", []))
	refresh_ui()
func refresh_ui() -> void:
	lbl_pounds.text = "£ " + str(GameManager.pounds)
	lbl_gold.text = "Слитки: " + str(GameManager.gold_bars)
	lbl_level.text = "Ур. " + str(GameManager.current_level)
	lbl_moves.text = "Ходы:\n" + str(moves_left)

	var empty_sb = StyleBoxFlat.new()
	empty_sb.bg_color = Color(0.04, 0.10, 0.08, 0.55)
	empty_sb.border_color = Color(0.76, 0.58, 0.22, 0.30)
	empty_sb.set_border_width_all(2)
	empty_sb.set_corner_radius_all(12)

	if stock_pile.size() > 0:
		btn_stock.remove_theme_stylebox_override("normal")
		btn_stock.remove_theme_stylebox_override("hover")
		btn_stock.remove_theme_stylebox_override("pressed")
		btn_stock.text = "КОЛОДА\n(" + str(stock_pile.size()) + ")"
		btn_stock.modulate = Color.WHITE
	elif waste_pile.size() > 0:
		btn_stock.remove_theme_stylebox_override("normal")
		btn_stock.remove_theme_stylebox_override("hover")
		btn_stock.remove_theme_stylebox_override("pressed")
		btn_stock.text = "↻ ВЕРНУТЬ\n(" + str(waste_pile.size()) + ")"
		btn_stock.modulate = Color.WHITE
	else:
		btn_stock.text = ""
		btn_stock.modulate = Color.WHITE
		btn_stock.add_theme_stylebox_override("normal", empty_sb)
		btn_stock.add_theme_stylebox_override("hover", empty_sb)
		btn_stock.add_theme_stylebox_override("pressed", empty_sb)

	for w_child in btn_waste.get_children():
		w_child.queue_free()

	if waste_pile.size() > 0:
		btn_waste.remove_theme_stylebox_override("normal")
		btn_waste.remove_theme_stylebox_override("hover")
		btn_waste.remove_theme_stylebox_override("pressed")
		var top_waste: Dictionary = waste_pile.back()
		btn_waste.text = top_waste["word"]
		btn_waste.modulate = Color.WHITE

		var w_key_col: String = top_waste.get("key_color", "")
		if w_key_col != "":
			var col_renderer = load("res://scripts/column_renderer.gd")
			btn_waste.text = "\n" + top_waste["word"]
			var wk_lbl = Label.new()
			wk_lbl.text = "🗝"
			wk_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
			wk_lbl.offset_top = 8
			wk_lbl.offset_bottom = 32
			wk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			wk_lbl.add_theme_font_size_override("font_size", 20)
			wk_lbl.add_theme_color_override("font_color", col_renderer.get_lock_color(w_key_col))
			wk_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_waste.add_child(wk_lbl)

		if top_waste.get("is_theme", false):
			btn_waste.text = "\n" + top_waste["word"]
			var w_crown = Label.new()
			w_crown.text = "♛"
			w_crown.set_anchors_preset(Control.PRESET_TOP_WIDE)
			w_crown.offset_top = 10
			w_crown.offset_bottom = 36
			w_crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			w_crown.add_theme_font_size_override("font_size", 22)
			w_crown.add_theme_color_override("font_color", Color(0.82, 0.58, 0.12))
			w_crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_waste.add_child(w_crown)

			var inner_w = Panel.new()
			inner_w.set_anchors_preset(Control.PRESET_FULL_RECT)
			inner_w.offset_left = 6
			inner_w.offset_top = 6
			inner_w.offset_right = -6
			inner_w.offset_bottom = -6
			inner_w.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var inner_w_sb = StyleBoxFlat.new()
			inner_w_sb.bg_color = Color(0, 0, 0, 0)
			inner_w_sb.border_color = Color(0.88, 0.67, 0.16, 0.95)
			inner_w_sb.set_border_width_all(2)
			inner_w_sb.set_corner_radius_all(8)
			inner_w.add_theme_stylebox_override("panel", inner_w_sb)
			btn_waste.add_child(inner_w)

			var corners_w = [
				["╔", Control.PRESET_TOP_LEFT, Vector2(7, 3)],
				["╗", Control.PRESET_TOP_RIGHT, Vector2(-19, 3)],
				["╚", Control.PRESET_BOTTOM_LEFT, Vector2(7, -21)],
				["╝", Control.PRESET_BOTTOM_RIGHT, Vector2(-19, -21)]
			]
			for c_info in corners_w:
				var c_lbl = Label.new()
				c_lbl.text = c_info[0]
				c_lbl.set_anchors_preset(c_info[1])
				c_lbl.offset_left = c_info[2].x
				c_lbl.offset_top = c_info[2].y
				c_lbl.add_theme_font_size_override("font_size", 11)
				c_lbl.add_theme_color_override("font_color", Color(0.78, 0.56, 0.12, 0.9))
				c_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn_waste.add_child(c_lbl)
	else:
		btn_waste.text = ""
		btn_waste.modulate = Color.WHITE
		btn_waste.add_theme_stylebox_override("normal", empty_sb)
		btn_waste.add_theme_stylebox_override("hover", empty_sb)
		btn_waste.add_theme_stylebox_override("pressed", empty_sb)

	for child in categories_box.get_children():
		child.queue_free()

	categories_box.visible = true
	categories_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var count_cats: int = max(1, category_slots.size())

	var empty_cat_sb = StyleBoxFlat.new()
	empty_cat_sb.bg_color = Color(0.04, 0.13, 0.10, 0.90)
	empty_cat_sb.border_color = Color(0.90, 0.72, 0.30, 0.95)
	empty_cat_sb.set_border_width_all(2)
	empty_cat_sb.set_corner_radius_all(12)

	for cat_id in category_slots.keys():
		var slot: Dictionary = category_slots[cat_id]
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var slot_w: int = int(660.0 / count_cats) - 10
		btn.custom_minimum_size = Vector2(slot_w, 120)
		btn.focus_mode = Control.FOCUS_NONE
		if count_cats >= 4:
			btn.add_theme_font_size_override("font_size", 15)

		if not slot.get("unlocked", false):
			btn.text = "♛"
			btn.add_theme_font_size_override("font_size", 26)
			btn.add_theme_color_override("font_color", Color(0.92, 0.75, 0.35, 0.85))
			btn.add_theme_stylebox_override("normal", empty_cat_sb)
			btn.add_theme_stylebox_override("hover", empty_cat_sb)
			btn.add_theme_stylebox_override("pressed", empty_cat_sb)

			var inner_filigree = Panel.new()
			inner_filigree.set_anchors_preset(Control.PRESET_FULL_RECT)
			inner_filigree.offset_left = 5
			inner_filigree.offset_top = 5
			inner_filigree.offset_right = -5
			inner_filigree.offset_bottom = -5
			inner_filigree.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var inner_sb = StyleBoxFlat.new()
			inner_sb.bg_color = Color(0, 0, 0, 0)
			inner_sb.border_color = Color(0.82, 0.65, 0.28, 0.25)
			inner_sb.set_border_width_all(1)
			inner_sb.set_corner_radius_all(9)
			inner_filigree.add_theme_stylebox_override("panel", inner_sb)
			btn.add_child(inner_filigree)

			var corner_glyphs = [
				["╔", Control.PRESET_TOP_LEFT, Vector2(6, 2)],
				["╗", Control.PRESET_TOP_RIGHT, Vector2(-18, 2)],
				["╚", Control.PRESET_BOTTOM_LEFT, Vector2(6, -20)],
				["╝", Control.PRESET_BOTTOM_RIGHT, Vector2(-18, -20)]
			]
			for c_info in corner_glyphs:
				var c_lbl = Label.new()
				c_lbl.text = c_info[0]
				c_lbl.set_anchors_preset(c_info[1])
				c_lbl.offset_left = c_info[2].x
				c_lbl.offset_top = c_info[2].y
				c_lbl.add_theme_font_size_override("font_size", 11)
				c_lbl.add_theme_color_override("font_color", Color(0.85, 0.68, 0.30, 0.45))
				c_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(c_lbl)
		else:
			var is_done: bool = (slot["count"] >= slot["total"])
			if is_done:
				btn.text = "✦\n" + slot["title"]
				btn.disabled = true
				btn.modulate = Color(1.0, 1.0, 1.0, 0.35)
			else:
				btn.text = "♛\n" + slot["title"]
				btn.modulate = Color.WHITE
				var cat_badge = Label.new()
				cat_badge.text = str(slot["count"]) + "/" + str(slot["total"])
				cat_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
				cat_badge.offset_left = -56
				cat_badge.offset_right = -8
				cat_badge.offset_top = 4
				cat_badge.offset_bottom = 24
				cat_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				cat_badge.add_theme_font_size_override("font_size", 13)
				cat_badge.add_theme_color_override("font_color", Color(0.38, 0.28, 0.16))
				cat_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(cat_badge)

		btn.pressed.connect(_on_category_pressed.bind(cat_id))
		categories_box.add_child(btn)

	for child in columns_box.get_children():
		child.queue_free()

	var renderer = load("res://scripts/column_renderer.gd")
	if renderer:
		renderer.render_columns(self)

func _on_stock_pressed() -> void:
	if moves_left <= 0:
		return
	if stock_pile.is_empty() and waste_pile.is_empty():
		return
	selected_card = {}
	moves_left -= 1
	if stock_pile.size() > 0:
		var c = stock_pile.pop_back()
		c["face_up"] = true
		waste_pile.append(c)
	elif waste_pile.size() > 0:
		waste_pile.reverse()
		stock_pile = waste_pile.duplicate()
		waste_pile.clear()
	check_lose()
	if waste_pile.size() > 0:
		var fx = load("res://scripts/fx_helper.gd")
		if fx:
			fx.fly_card(self, waste_pile.back()["word"], btn_stock.global_position, btn_waste.global_position, Callable())
	refresh_ui()

func _on_waste_pressed() -> void:
	if waste_pile.size() == 0:
		return
	selected_card = {"source": "waste", "card": waste_pile.back()}
	refresh_ui()

func _on_tableau_card_pressed(col_idx: int, card_idx: int) -> void:
	var col: Array = tableau_columns[col_idx]
	if card_idx == col.size() - 1:
		if col[card_idx].get("locked_color", "") != "":
			return
		selected_card = {"source": "col", "col": col_idx, "idx": card_idx, "card": col[card_idx]}
		refresh_ui()

func _on_category_pressed(cat_id: String) -> void:
	if selected_card.is_empty() or moves_left <= 0:
		return
	var card: Dictionary = selected_card["card"]
	if card.get("locked_color", "") != "":
		return

	var start_pos := get_global_mouse_position() - Vector2(75, 40)
	var cat_keys: Array = category_slots.keys()
	var cat_index: int = cat_keys.find(cat_id)
	var target_btn: Control = categories_box.get_child(cat_index) if cat_index >= 0 and cat_index < categories_box.get_child_count() else null
	var target_pos: Vector2 = target_btn.global_position if target_btn else Vector2(300, 200)

	if card.get("is_theme", false):
		var real_cat_id: String = card["cat_id"]
		if not category_slots[real_cat_id].get("unlocked", false):
			moves_left -= 1
			category_slots[real_cat_id]["unlocked"] = true
			remove_selected_card()
			selected_card = {}
			var fx_theme = load("res://scripts/fx_helper.gd")
			if fx_theme:
				fx_theme.show_floating_toast(self, target_pos + Vector2(0, 20), "Тема открыта!", Color(0.96, 0.85, 0.55))
			refresh_ui()
		return
	if not category_slots[cat_id].get("unlocked", false):
		moves_left -= 1
		selected_card = {}
		var fx_lock = load("res://scripts/fx_helper.gd")
		if fx_lock and target_btn:
			fx_lock.shake_node(target_btn)
			fx_lock.show_floating_toast(self, target_pos, "Сначала найди\nкарту темы ♛!", Color(0.85, 0.35, 0.32))
		check_lose()
		refresh_ui()
		return

	if card["cat_id"] == cat_id:
		var word_txt: String = card["word"]
		var moved_count := 1
		var unlocked_keys: Array = []

		if selected_card["source"] == "col":
			var rules = preload("res://scripts/solitaire_rules.gd")
			var src_col: Array = tableau_columns[selected_card["col"]]
			moved_count = rules.get_top_group_count(src_col)
			for _i in range(moved_count):
				var top_c: Dictionary = src_col.back()
				if top_c.get("key_color", "") != "":
					unlocked_keys.append(top_c["key_color"])
				remove_selected_card()
		else:
			if card.get("key_color", "") != "":
				unlocked_keys.append(card["key_color"])
			remove_selected_card()

		moves_left -= 1
		category_slots[cat_id]["count"] += moved_count
		selected_card = {}

		for k_color in unlocked_keys:
			unlock_cards_by_color(k_color)

		var is_group_done: bool = (category_slots[cat_id]["count"] == category_slots[cat_id]["total"])
		var reward: int = category_slots[cat_id]["total"] * 15
		if is_group_done:
			GameManager.add_pounds(reward)

		refresh_ui()

		var fx = preload("res://scripts/fx_helper.gd")
		if not unlocked_keys.is_empty():
			var renderer = load("res://scripts/column_renderer.gd")
			fx.show_floating_toast(self, target_pos + Vector2(-20, 65), "🔓 Замок открыт!", renderer.get_lock_color(unlocked_keys[0]))

		fx.fly_card(self, word_txt, start_pos, target_pos, func():
			if is_group_done:
				var phrases = ["ВЕЛИКОЛЕПНО!", "БЕЗУПРЕЧНО!", "БРАВО, ГЕРЦОГ!", "ТОЧНО В ЦЕЛЬ!"]
				var msg = phrases[randi() % phrases.size()] + "\n+£" + str(reward)
				fx.show_floating_toast(self, target_pos + Vector2(-40, 20), msg)
				fx.pulse_node(lbl_pounds)
			check_win_or_lose()
		)
	else:
		moves_left -= 1
		selected_card = {}
		var fx = preload("res://scripts/fx_helper.gd")
		if target_btn:
			fx.shake_node(target_btn)
		fx.show_floating_toast(self, target_pos, "Не подходит!", Color(1.0, 0.45, 0.45))
		check_lose()
		refresh_ui()

func unlock_cards_by_color(k_color: String) -> void:
	for col in tableau_columns:
		for c in col:
			if c.get("locked_color", "") == k_color:
				c["locked_color"] = ""
	for c in stock_pile:
		if c.get("locked_color", "") == k_color:
			c["locked_color"] = ""
	for c in waste_pile:
		if c.get("locked_color", "") == k_color:
			c["locked_color"] = ""

func remove_selected_card() -> void:
	if selected_card["source"] == "waste":
		waste_pile.pop_back()
	elif selected_card["source"] == "col":
		var col: Array = tableau_columns[selected_card["col"]]
		col.pop_back()
		if col.size() > 0 and col.back()["cat_id"] == "JOKER":
			col.pop_back()
		if col.size() > 0:
			col.back()["face_up"] = true

func _on_hint_pressed() -> void:
	if GameManager.pounds < 50:
		var fx = load("res://scripts/fx_helper.gd")
		if fx:
			fx.shake_node(btn_hint)
			fx.show_floating_toast(self, btn_hint.global_position + Vector2(-45, 75), "Нужно £ 50!", Color(0.85, 0.35, 0.32))
		return

	GameManager.add_pounds(-50)
	refresh_ui()
	var advisor = load("res://scripts/hint_advisor.gd")
	if advisor:
		advisor.analyze_and_show(self)

func check_win_or_lose() -> void:
	var all_done = true
	for cat_id in category_slots.keys():
		if category_slots[cat_id]["count"] < category_slots[cat_id]["total"]:
			all_done = false
			break
	if all_done:
		var moves_bonus := moves_left * 5
		if moves_bonus > 0:
			GameManager.add_pounds(moves_bonus)
		GameManager.complete_level()
		refresh_ui()
		popup_text.text = "БРАВО, ВАША СВЕТЛОСТЬ!\nУровень пройден!\n+1 Слиток золота!\nБонус за ходы (" + str(moves_left) + "): +£" + str(moves_bonus)
		popup_panel.visible = true
	else:
		check_lose()

func check_lose() -> void:
	if moves_left <= 0:
		popup_text.text = "Ходы иссякли!\nПопробуйте заново."
		popup_panel.visible = true

var extra_tabs_ready := false
var tab_manor: PanelContainer
var tab_artifacts: PanelContainer
var manor_box: VBoxContainer
var artifacts_box: VBoxContainer
var lbl_duke_info: Label

var manor_items := {
	"fireplace": {"title": "Мраморный камин", "s0": "Завален сажей", "s1": "Очищенный камень", "s2": "Пылающий очаг"},
	"sofa": {"title": "Диван «Честерфилд»", "s0": "Рваная обивка", "s1": "Реставрированная кожа", "s2": "Королевский дуб"},
	"coat_of_arms": {"title": "Фамильный герб", "s0": "Пустая рама", "s1": "Деревянный щит", "s2": "Золотое тиснение"},
	"library": {"title": "Дубовая библиотека", "s0": "Пыльные полки", "s1": "Собрание классиков", "s2": "Тайный архив"}
}

var artifacts_list := [
	{"id": "ring_tudor", "name": "Перстень-печатка Тюдоров", "price": 150, "desc": "Золотой перстень XVI века с потайным отделением."},
	{"id": "flask_1890", "name": "Охотничья фляга лорда", "price": 300, "desc": "Серебряная фляга с гравировкой фамильного герба."},
	{"id": "compass_brass", "name": "Хронометр Ост-Индской компании", "price": 500, "desc": "Латунный прибор 1784 года для поиска реликвий."},
	{"id": "duel_pistol", "name": "Кремнёвый дуэльный пистолет", "price": 800, "desc": "Работа лондонских мастеров со слоновой костью."}
]

func _process(_delta: float) -> void:
	if not extra_tabs_ready:
		extra_tabs_ready = true
		init_extra_tabs()

func init_extra_tabs() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.14, 0.11, 1.0)
	panel_style.border_color = Color(0.85, 0.68, 0.2, 1.0)
	panel_style.set_border_width_all(2)

	tab_manor = PanelContainer.new()
	tab_manor.position = Vector2(20, 90)
	tab_manor.size = Vector2(680, 1070)
	tab_manor.visible = false
	tab_manor.add_theme_stylebox_override("panel", panel_style)
	add_child(tab_manor)

	var m_vbox = VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 18)
	tab_manor.add_child(m_vbox)

	lbl_duke_info = Label.new()
	lbl_duke_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_duke_info.add_theme_font_size_override("font_size", 22)
	lbl_duke_info.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	m_vbox.add_child(lbl_duke_info)

	var btn_shave = Button.new()
	btn_shave.text = "Вызвать цирюльника (£ 50)"
	btn_shave.custom_minimum_size = Vector2(0, 65)
	btn_shave.pressed.connect(func():
		if GameManager.pounds >= 50 and GameManager.beard_stage > 0.0:
			GameManager.add_pounds(-50)
			GameManager.beard_stage = 0.0
			GameManager.save_game()
			update_extra_tabs()
	)
	m_vbox.add_child(btn_shave)

	manor_box = VBoxContainer.new()
	manor_box.add_theme_constant_override("separation", 15)
	m_vbox.add_child(manor_box)

	tab_artifacts = PanelContainer.new()
	tab_artifacts.position = Vector2(20, 90)
	tab_artifacts.size = Vector2(680, 1070)
	tab_artifacts.visible = false
	tab_artifacts.add_theme_stylebox_override("panel", panel_style)
	add_child(tab_artifacts)

	artifacts_box = VBoxContainer.new()
	artifacts_box.add_theme_constant_override("separation", 18)
	tab_artifacts.add_child(artifacts_box)

	var nav = HBoxContainer.new()
	nav.position = Vector2(20, 1180)
	nav.size = Vector2(680, 80)
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 15)
	add_child(nav)

	var b1 = Button.new()
	b1.text = "♠ ПАСЬЯНС"
	b1.custom_minimum_size = Vector2(210, 75)
	b1.pressed.connect(func():
		tab_manor.visible = false
		tab_artifacts.visible = false
		refresh_ui()
	)
	nav.add_child(b1)

	var b2 = Button.new()
	b2.text = "♛ ПОМЕСТЬЕ"
	b2.custom_minimum_size = Vector2(210, 75)
	b2.pressed.connect(func():
		tab_manor.visible = true
		tab_artifacts.visible = false
		update_extra_tabs()
	)
	nav.add_child(b2)

	var b3 = Button.new()
	b3.text = "✦ РЕЛИКВИИ"
	b3.custom_minimum_size = Vector2(210, 75)
	b3.pressed.connect(func():
		tab_manor.visible = false
		tab_artifacts.visible = true
		update_extra_tabs()
	)
	nav.add_child(b3)

func update_extra_tabs() -> void:
	refresh_ui()
	var st := int(GameManager.beard_stage)
	var beard_txt := "Гладко выбрит"
	if st == 1:
		beard_txt = "Лёгкая щетина"
	elif st == 2:
		beard_txt = "Ухоженная борода"
	elif st >= 3:
		beard_txt = "Густая борода лорда"
	lbl_duke_info.text = "♛ " + GameManager.duke_name + " | Вид: " + beard_txt

	for c in manor_box.get_children():
		c.queue_free()
	for id in manor_items.keys():
		var info: Dictionary = manor_items[id]
		var lvl: int = GameManager.manor_upgrades[id]
		var st_name: String = info["s0"]
		if lvl == 1:
			st_name = info["s1"]
		elif lvl >= 2:
			st_name = info["s2"]

		var row = HBoxContainer.new()
		manor_box.add_child(row)
		var l = Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 20)
		l.text = info["title"] + "\n[" + st_name + "]"
		row.add_child(l)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 75)
		if lvl >= 2:
			btn.text = "★ ГОТОВО ★"
			btn.disabled = true
		else:
			var cost := lvl + 1
			btn.text = "Улучшить (" + str(cost) + " Слит.)"
			btn.pressed.connect(func():
				if GameManager.upgrade_manor(id, cost):
					update_extra_tabs()
			)
		row.add_child(btn)

	for c in artifacts_box.get_children():
		c.queue_free()
	for item in artifacts_list:
		var art_id: String = item["id"]
		var art_name: String = item["name"]
		var art_price: int = item["price"]
		var art_desc: String = item["desc"]
		var owned := GameManager.owned_artifacts.has(art_id)

		var row = HBoxContainer.new()
		artifacts_box.add_child(row)
		var l = Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 18)
		l.text = ("✦ " if owned else "🔒 ") + art_name + "\n" + art_desc
		row.add_child(l)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 80)
		if owned:
			btn.text = "В КОЛЛЕКЦИИ"
			btn.disabled = true
		else:
				btn.text = "Купить (£ " + str(art_price) + ")"
				btn.pressed.connect(func():
					if GameManager.buy_artifact(art_id, art_price):
						update_extra_tabs()
)
				row.add_child(btn)
func _on_rewarded_ad_done(tag: String) -> void:
	if tag == "free_1000":
				GameManager.add_pounds(1000)
				update_main_menu_ui()
				refresh_ui()
