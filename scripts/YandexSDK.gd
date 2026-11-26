extends Node

signal rewarded_success(tag: String)

var is_web: bool = false
var _js_callback: JavaScriptObject

func _ready() -> void:
	is_web = OS.has_feature("web")
	if is_web:
		_js_callback = JavaScriptBridge.create_callback(_on_js_message)
		var win = JavaScriptBridge.get_interface("window")
		if win:
			win.godotYandexCallback = _js_callback
		JavaScriptBridge.eval("if (window.initYandexSDK) { window.initYandexSDK(); }", true)

func _on_js_message(args: Array) -> void:
	if args.size() < 2:
		return
	var event_type: String = str(args[0])
	var payload: String = str(args[1])
	if event_type == "rewarded":
		rewarded_success.emit(payload)

func show_rewarded_ad(tag: String) -> void:
	if is_web:
		JavaScriptBridge.eval("if (window.yaShowRewarded) { window.yaShowRewarded('" + tag + "'); }", true)
	else:
		# Тестовый режим на ПК при запуске через F5
		rewarded_success.emit(tag)
