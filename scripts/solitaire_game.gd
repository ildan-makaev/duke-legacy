extends Control

var levels_data: Array = [
	{
		"level": 1,
		"moves": 30,
		"categories": [
			{"id": "manor", "title": "УСАДЬБА", "items": ["Камин", "Дворецкий", "Герб", "Библиотека"]},
			{"id": "hunt", "title": "ОХОТА", "items": ["Гончая", "Двустволка", "Твид", "Фазан"]},
			{"id": "wine", "title": "ПОГРЕБ", "items": ["Винтаж", "Штопор", "Дуб", "Бокал"]}
		]
	},
	{
		"level": 2,
		"moves": 35,
		"categories": [
			{"id": "crime", "title": "ИНТРИГИ", "items": ["Сейф", "Алиби", "Шифр", "Улика"]},
			{"id": "club", "title": "КЛУБ", "items": ["Сигара", "Виски", "Бильярд", "Пари"]},
			{"id": "horses", "title": "КОНЮШНЯ", "items": ["Скакун", "Жокей", "Седло", "Ипподром"]}
		]
	}
]

var moves_left: int = 30
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

func _ready() -> void:
	theme = preload("res://scripts/ui_theme.gd").create_duke_theme()
	load_levels_from_json()
	build_ui()
	start_level(GameManager.current_level)

func build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.22, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(20, 20)
	top_bar.size = Vector2(680, 60)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 30)
	add_child(top_bar)

	lbl_pounds = create_badge(top_bar, "£ 100", Color(0.85, 0.68, 0.2))
	lbl_gold = create_badge(top_bar, "Слитки: 1", Color(0.95, 0.8, 0.3))
	lbl_level = create_badge(top_bar, "Уровень 1", Color(0.9, 0.9, 0.9))

	var deck_area = HBoxContainer.new()
	deck_area.position = Vector2(30, 100)
	deck_area.size = Vector2(660, 130)
	deck_area.add_theme_constant_override("separation", 20)
	add_child(deck_area)

	lbl_moves = Label.new()
	lbl_moves.custom_minimum_size = Vector2(140, 120)
	lbl_moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_moves.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_moves.add_theme_font_size_override("font_size", 26)
	deck_area.add_child(lbl_moves)

	btn_stock = Button.new()
	btn_stock.text = "КОЛОДА\n(Взять)"
	btn_stock.custom_minimum_size = Vector2(140, 120)
	btn_stock.pressed.connect(_on_stock_pressed)
	deck_area.add_child(btn_stock)

	btn_waste = Button.new()
	btn_waste.text = "Пусто"
	btn_waste.custom_minimum_size = Vector2(160, 120)
	btn_waste.pressed.connect(_on_waste_pressed)
	preload("res://scripts/drag_helper.gd").make_draggable(btn_waste, {"source": "waste"}, self)
	deck_area.add_child(btn_waste)

	var btn_hint = Button.new()
	btn_hint.text = "Подсказка\n(£ 50)"
	btn_hint.custom_minimum_size = Vector2(150, 120)
	btn_hint.pressed.connect(_on_hint_pressed)
	deck_area.add_child(btn_hint)

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
		start_level(GameManager.current_level)
	)
	vbox.add_child(btn_next)

func create_badge(parent: Node, txt: String, col: Color) -> Label:
	var lbl = Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 24)
	parent.add_child(lbl)
	return lbl

func start_level(lvl_num: int) -> void:
	var data = levels_data[(lvl_num - 1) % levels_data.size()]
	moves_left = data["moves"]
	selected_card = {}
	waste_pile.clear()
	category_slots.clear()

	var all_cards: Array = []
	for cat in data["categories"]:
		category_slots[cat["id"]] = {
			"title": cat["title"],
			"count": 0,
			"total": cat["items"].size()
		}
		for item in cat["items"]:
			all_cards.append({"word": item, "cat_id": cat["id"], "face_up": false})

	all_cards.shuffle()

	tableau_columns = [[], [], [], []]
	for col_idx in range(4):
		for row in range(col_idx + 1):
			if all_cards.size() > 0:
				var c = all_cards.pop_back()
				if row == col_idx:
					c["face_up"] = true
				tableau_columns[col_idx].append(c)

	stock_pile = all_cards
	refresh_ui()

func refresh_ui() -> void:
	lbl_pounds.text = "£ " + str(GameManager.pounds)
	lbl_gold.text = "Слитки: " + str(GameManager.gold_bars)
	lbl_level.text = "Уровень " + str(GameManager.current_level)
	lbl_moves.text = "Ходы:\n" + str(moves_left)

	btn_stock.text = "КОЛОДА\n(" + str(stock_pile.size()) + ")"
	if waste_pile.size() > 0:
		var top_waste = waste_pile.back()
		btn_waste.text = top_waste["word"]
		btn_waste.modulate = Color(1, 0.9, 0.5) if selected_card.get("source") == "waste" else Color.WHITE
	else:
		btn_waste.text = "Пусто"
		btn_waste.modulate = Color.WHITE

	for child in categories_box.get_children():
		child.queue_free()

	for cat_id in category_slots.keys():
		var slot = category_slots[cat_id]
		var btn = Button.new()
		var count_cats = max(1, category_slots.size())
		var slot_w = int(660 / count_cats) - 10
		btn.custom_minimum_size = Vector2(slot_w, 130)
		if count_cats >= 4:
			btn.add_theme_font_size_override("font_size", 15)

		if slot["count"] >= slot["total"]:
			btn.text = "★ " + slot["title"] + " ★\nСОБРАНО!"
			btn.modulate = Color(0.4, 1.0, 0.5)
		else:
			btn.text = "♛ " + slot["title"] + "\n" + str(slot["count"]) + " / " + str(slot["total"])
		btn.pressed.connect(_on_category_pressed.bind(cat_id))
		categories_box.add_child(btn)

	for child in columns_box.get_children():
		child.queue_free()

		preload("res://scripts/column_renderer.gd").render_columns(self)
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
	refresh_ui()

func _on_waste_pressed() -> void:
	if waste_pile.size() == 0:
		return
	selected_card = {"source": "waste", "card": waste_pile.back()}
	refresh_ui()

func _on_tableau_card_pressed(col_idx: int, card_idx: int) -> void:
	var col = tableau_columns[col_idx]
	if card_idx == col.size() - 1:
		selected_card = {"source": "col", "col": col_idx, "idx": card_idx, "card": col[card_idx]}
		refresh_ui()

func _on_category_pressed(cat_id: String) -> void:
	if selected_card.is_empty() or moves_left <= 0:
		return
	var card = selected_card["card"]
	var start_pos = get_global_mouse_position() - Vector2(75, 40)

	var cat_keys = category_slots.keys()
	var cat_index = cat_keys.find(cat_id)
	var target_btn: Control = categories_box.get_child(cat_index) if cat_index >= 0 and cat_index < categories_box.get_child_count() else null
	var target_pos = target_btn.global_position if target_btn else Vector2(300, 200)

	if card["cat_id"] == cat_id:
		var word_txt = card["word"]
		var moved_count := 1
		if selected_card["source"] == "col":
			var rules = preload("res://scripts/solitaire_rules.gd")
			moved_count = rules.get_top_group_count(tableau_columns[selected_card["col"]])
			for _i in range(moved_count):
				remove_selected_card()
		else:
			remove_selected_card()

		moves_left -= 1
		category_slots[cat_id]["count"] += moved_count

		selected_card = {}

		var is_group_done = (category_slots[cat_id]["count"] == category_slots[cat_id]["total"])
		var reward = category_slots[cat_id]["total"] * 15
		if is_group_done:
			GameManager.add_pounds(reward)

		refresh_ui()

		var fx = preload("res://scripts/fx_helper.gd")
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


func remove_selected_card() -> void:
	if selected_card["source"] == "waste":
		waste_pile.pop_back()
	elif selected_card["source"] == "col":
		var col = tableau_columns[selected_card["col"]]
		col.pop_back()
		if col.size() > 0:
			col.back()["face_up"] = true

func _on_hint_pressed() -> void:
	if GameManager.pounds < 50:
		return
	if waste_pile.size() > 0:
		GameManager.add_pounds(-50)
		selected_card = {"source": "waste", "card": waste_pile.back()}
		_on_category_pressed(waste_pile.back()["cat_id"])
		return
	for col_idx in range(4):
		var col = tableau_columns[col_idx]
		if col.size() > 0 and col.back()["face_up"]:
			GameManager.add_pounds(-50)
			selected_card = {"source": "col", "col": col_idx, "idx": col.size() - 1, "card": col.back()}
			_on_category_pressed(col.back()["cat_id"])
			return

func check_win_or_lose() -> void:
	var all_done = true
	for cat_id in category_slots.keys():
		if category_slots[cat_id]["count"] < category_slots[cat_id]["total"]:
			all_done = false
			break
	if all_done:
		GameManager.complete_level()
		popup_text.text = "БРАВО, ВАША СВЕТЛОСТЬ!\nУровень пройден!\n+1 Слиток золота!"
		popup_panel.visible = true
	else:
		check_lose()

func check_lose() -> void:
	if moves_left <= 0:
		popup_text.text = "Ходы иссякли!\nПопробуйте заново."
		popup_panel.visible = true
# ==========================================
# ДОПОЛНЕНИЕ: НИЖНЕЕ МЕНЮ, ПОМЕСТЬЕ И РЕЛИКВИИ
# ==========================================
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
	# Делаем непрозрачный фон для вкладок, чтобы карты снизу не просвечивали
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

	# Нижняя панель из 3 кнопок
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
func load_levels_from_json() -> void:
	if FileAccess.file_exists("res://data/levels.json"):
		var file = FileAccess.open("res://data/levels.json", FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array and parsed.size() > 0:
			levels_data = parsed
