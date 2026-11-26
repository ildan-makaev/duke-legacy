extends Node

signal stats_updated

var pounds: int = 100
var gold_bars: int = 1
var current_level: int = 1

var duke_name: String = "Герцог Блэквуд"
var beard_stage: float = 0.0

var manor_upgrades: Dictionary = {
	"fireplace": 0,
	"sofa": 0,
	"coat_of_arms": 0,
	"library": 0
}

var owned_artifacts: Array = []

const SAVE_PATH = "user://duke_legacy_save.cfg"

func _ready() -> void:
	load_game()

func add_pounds(amount: int) -> void:
	pounds += amount
	stats_updated.emit()
	save_game()

func complete_level() -> void:
	current_level += 1
	gold_bars += 1
	beard_stage = min(3.0, beard_stage + 0.15)
	stats_updated.emit()
	save_game()

func buy_artifact(artifact_id: String, price: int) -> bool:
	if pounds >= price and not owned_artifacts.has(artifact_id):
		pounds -= price
		owned_artifacts.append(artifact_id)
		stats_updated.emit()
		save_game()
		return true
	return false

func upgrade_manor(item_id: String, cost: int) -> bool:
	if gold_bars >= cost and manor_upgrades.has(item_id):
		gold_bars -= cost
		manor_upgrades[item_id] += 1
		stats_updated.emit()
		save_game()
		return true
	return false

func save_game() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("economy", "pounds", pounds)
	cfg.set_value("economy", "gold_bars", gold_bars)
	cfg.set_value("economy", "level", current_level)
	cfg.set_value("duke", "name", duke_name)
	cfg.set_value("duke", "beard", beard_stage)
	cfg.set_value("manor", "upgrades", manor_upgrades)
	cfg.set_value("collection", "artifacts", owned_artifacts)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		pounds = cfg.get_value("economy", "pounds", 100)
		gold_bars = cfg.get_value("economy", "gold_bars", 1)
		current_level = cfg.get_value("economy", "level", 1)
		duke_name = cfg.get_value("duke", "name", "Герцог Блэквуд")
		beard_stage = cfg.get_value("duke", "beard", 0.0)
		manor_upgrades = cfg.get_value("manor", "upgrades", manor_upgrades)
		owned_artifacts = cfg.get_value("collection", "artifacts", [])
