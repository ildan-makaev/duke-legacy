extends Node

static func create_duke_theme() -> Theme:
	var t = Theme.new()

	# 1. Стиль обычных карт и кнопок (благородная слоновая кость + золотая рамка)
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.95, 0.91, 0.82) # Кремовый картон
	btn_normal.border_color = Color(0.76, 0.58, 0.22) # Античное золото
	btn_normal.set_border_width_all(3)
	btn_normal.set_corner_radius_all(12)
	btn_normal.shadow_color = Color(0, 0, 0, 0.35)
	btn_normal.shadow_size = 5
	btn_normal.shadow_offset = Vector2(0, 4)

	# 2. Стиль при наведении / выборе карты (яркое золото)
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(1.0, 0.96, 0.85)
	btn_hover.border_color = Color(0.98, 0.78, 0.25)
	btn_hover.set_border_width_all(4)

	# 3. Стиль при нажатии
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.85, 0.78, 0.65)
	btn_pressed.shadow_offset = Vector2(0, 1)

	# 4. Стиль рубашки закрытой карты (тёмный бордовый бархат + золото)
	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.28, 0.08, 0.12) # Королевский бордо
	btn_disabled.border_color = Color(0.65, 0.50, 0.20)
	btn_disabled.set_border_width_all(2)
	btn_disabled.set_corner_radius_all(12)

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", btn_hover)
	t.set_stylebox("disabled", "Button", btn_disabled)

	# Тёмно-коричневый чернильный текст на светлых картах
	t.set_color("font_color", "Button", Color(0.14, 0.09, 0.05))
	t.set_color("font_hover_color", "Button", Color(0.08, 0.05, 0.02))
	t.set_color("font_pressed_color", "Button", Color(0.14, 0.09, 0.05))
	t.set_color("font_disabled_color", "Button", Color(0.85, 0.68, 0.28)) # Золотой узор ❖ на рубашке
	t.set_font_size("font_size", "Button", 20)

	# 5. Стиль всплывающих окон и панелей (тёмный дуб + золотая кайма)
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.09, 0.06, 0.04, 0.96)
	panel_sb.border_color = Color(0.82, 0.64, 0.24)
	panel_sb.set_border_width_all(3)
	panel_sb.set_corner_radius_all(16)
	panel_sb.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	return t
