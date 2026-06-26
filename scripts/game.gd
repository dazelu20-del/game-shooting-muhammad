extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BOT_SCENE := preload("res://scenes/bot.tscn")

var map_instance: Node3D
var local_player: Node3D
var game_over: bool = false
var bots_alive: int = 0
var players_alive: int = 0

@onready var hud: CanvasLayer = $HUD
@onready var health_label: Label = $HUD/HealthLabel
@onready var bots_label: Label = $HUD/BotsLabel
@onready var players_label: Label = $HUD/PlayersLabel
@onready var result_panel: Panel = $HUD/ResultPanel
@onready var result_label: Label = $HUD/ResultPanel/ResultLabel
@onready var menu_button: Button = $HUD/ResultPanel/MenuButton
@onready var crosshair: Control = $HUD/Crosshair
@onready var spawn_root: Node3D = $SpawnRoot

func _ready() -> void:
	result_panel.visible = false
	menu_button.pressed.connect(_return_to_menu)

	if GameState.mode == GameState.Mode.SINGLE_PLAYER:
		players_label.visible = false
		_start_single_player()
	else:
		bots_label.visible = false
		_start_multiplayer()

func _start_single_player() -> void:
	if not _load_map(GameState.MAPS[GameState.selected_map]):
		_show_result(false, "Failed to load map.")
		return
	call_deferred("_finish_single_player_setup")

func _finish_single_player_setup() -> void:
	_spawn_local_player()
	_spawn_bots(GameState.BOT_COUNT)
	_update_hud()
	_on_health_changed(local_player.health, 100)

func _start_multiplayer() -> void:
	if not _load_map(GameState.MAPS[0]):
		_show_result(false, "Failed to load map.")
		return
	if multiplayer.is_server():
		_spawn_all_players()
	else:
		_request_spawn.rpc_id(1)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _load_map(map_path: String) -> bool:
	var map_scene: PackedScene = load(map_path)
	if map_scene == null:
		push_error("Failed to load map: %s" % map_path)
		return false
	map_instance = map_scene.instantiate()
	add_child(map_instance)
	move_child(map_instance, 0)
	return true

func _get_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	if map_instance and map_instance.has_method("get_spawn_points"):
		points = map_instance.get_spawn_points()
	if points.is_empty():
		points.append(Vector3(0, 2, 15))
	return points

func _spawn_local_player() -> void:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "Player1"
	player.player_color = Color(0.2, 0.6, 1.0)
	var spawns := _get_spawn_points()
	player.position = spawns[0] if spawns.size() > 0 else Vector3(0, 1, 15)
	spawn_root.add_child(player)
	player.set_multiplayer_authority(1)
	local_player = player
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)

func _spawn_bots(count: int) -> void:
	var spawns := _get_spawn_points()
	var bot_colors := [
		Color(1, 0.3, 0.3), Color(1, 0.5, 0.2), Color(0.9, 0.2, 0.5),
		Color(0.8, 0.4, 0.1), Color(1, 0.6, 0.3),
	]
	bots_alive = count
	for i in count:
		var bot: CharacterBody3D = BOT_SCENE.instantiate()
		bot.name = "Bot%d" % (i + 1)
		bot.bot_color = bot_colors[i % bot_colors.size()]
		var spawn_idx := mini(i + 1, spawns.size() - 1)
		bot.position = spawns[spawn_idx] if spawns.size() > spawn_idx else Vector3(randf_range(-10, 10), 1, randf_range(-10, 10))
		spawn_root.add_child(bot)
		bot.died.connect(_on_bot_died)

func _spawn_all_players() -> void:
	for peer_id in multiplayer.get_peers():
		_spawn_player_for_peer(peer_id)
	_spawn_player_for_peer(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_spawn() -> void:
	if multiplayer.is_server():
		_spawn_player_for_peer(multiplayer.get_remote_sender_id())

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player_for_peer(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	var player_node := spawn_root.get_node_or_null("Player%d" % peer_id)
	if player_node:
		player_node.queue_free()
	_check_multiplayer_win()

func _spawn_player_for_peer(peer_id: int) -> void:
	if spawn_root.has_node("Player%d" % peer_id):
		return
	var spawns := _get_spawn_points()
	var idx := (peer_id - 1) % spawns.size()
	var colors := [Color(0.2, 0.6, 1), Color(0.2, 1, 0.4), Color(1, 0.8, 0.2), Color(0.8, 0.2, 1), Color(0.2, 1, 1), Color(1, 0.4, 0.4), Color(0.6, 0.6, 1), Color(1, 0.6, 0.6)]
	var color: Color = colors[(peer_id - 1) % colors.size()]
	_spawn_player_rpc.rpc(spawns[idx], color, peer_id)

@rpc("authority", "call_local", "reliable")
func _spawn_player_rpc(pos: Vector3, color: Color, peer_id: int) -> void:
	if spawn_root.has_node("Player%d" % peer_id):
		return
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "Player%d" % peer_id
	player.player_color = color
	player.position = pos
	spawn_root.add_child(player, true)
	player.set_multiplayer_authority(peer_id)
	player.died.connect(_on_player_died)

	if peer_id == multiplayer.get_unique_id():
		local_player = player
		player.health_changed.connect(_on_health_changed)

	players_alive = _count_alive_players()
	_update_hud()

func _on_bot_died(_bot: Node3D) -> void:
	if game_over:
		return
	bots_alive = max(bots_alive - 1, 0)
	_update_hud()
	if bots_alive <= 0:
		_show_result(true, "You Win! All bots eliminated.")

func _on_player_died(player: Node3D) -> void:
	if game_over:
		return

	if GameState.mode == GameState.Mode.SINGLE_PLAYER:
		if player == local_player:
			_show_result(false, "You Lose!")
		return

	players_alive = _count_alive_players()
	_update_hud()

	if player == local_player:
		if players_alive == 0:
			_show_result(false, "You Lose!")
		else:
			_show_result(false, "You were eliminated!")
	elif players_alive <= 1 and local_player and local_player.visible:
		_show_result(true, "You Win! Last one standing.")
	else:
		_check_multiplayer_win()

func _check_multiplayer_win() -> void:
	if game_over or not local_player:
		return
	players_alive = _count_alive_players()
	if players_alive <= 1 and local_player.visible:
		_show_result(true, "You Win! Last one standing.")

func _count_alive_players() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(node) and node.visible:
			count += 1
	return count

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "Health: %d / %d" % [current, maximum]

func _update_hud() -> void:
	if GameState.mode == GameState.Mode.SINGLE_PLAYER:
		bots_label.text = "Bots Remaining: %d" % bots_alive
	else:
		players_alive = _count_alive_players()
		players_label.text = "Players Alive: %d" % players_alive

func _show_result(won: bool, message: String) -> void:
	if game_over:
		return
	game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crosshair.visible = false
	result_panel.visible = true
	result_label.text = message
	result_label.modulate = Color(0.3, 1, 0.4) if won else Color(1, 0.35, 0.35)

func _return_to_menu() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
