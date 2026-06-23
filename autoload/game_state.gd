extends Node

enum Mode { SINGLE_PLAYER, MULTIPLAYER }

var mode: Mode = Mode.SINGLE_PLAYER
var selected_map: int = 0
var is_host: bool = false

const MAPS: Array[String] = [
	"res://scenes/maps/map_arena.tscn",
	"res://scenes/maps/map_forest.tscn",
	"res://scenes/maps/map_city.tscn",
]

const MAP_NAMES: Array[String] = ["Arena", "Forest", "City"]

const BOT_COUNT: int = 5
const DEFAULT_PORT: int = 7777
