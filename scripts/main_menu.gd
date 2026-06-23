extends Control

@onready var main_panel: Panel = $MainPanel
@onready var single_panel: Panel = $SinglePlayerPanel
@onready var multi_panel: Panel = $MultiplayerPanel
@onready var status_label: Label = $StatusLabel
@onready var map_option: OptionButton = $SinglePlayerPanel/VBox/MapOption
@onready var address_input: LineEdit = $MultiplayerPanel/VBox/AddressInput

func _ready() -> void:
	_show_panel(main_panel)
	_setup_map_options()
	status_label.text = ""

	$MainPanel/VBox/SinglePlayerButton.pressed.connect(_on_single_player_pressed)
	$MainPanel/VBox/MultiplayerButton.pressed.connect(_on_multiplayer_pressed)
	$MainPanel/VBox/QuitButton.pressed.connect(func(): get_tree().quit())

	$SinglePlayerPanel/VBox/BackButton.pressed.connect(_show_main)
	$SinglePlayerPanel/VBox/StartButton.pressed.connect(_on_start_single)

	$MultiplayerPanel/VBox/BackButton.pressed.connect(_show_main)
	$MultiplayerPanel/VBox/HostButton.pressed.connect(_on_host)
	$MultiplayerPanel/VBox/JoinButton.pressed.connect(_on_join)

	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _setup_map_options() -> void:
	map_option.clear()
	for map_name in GameState.MAP_NAMES:
		map_option.add_item(map_name)

func _show_panel(panel: Panel) -> void:
	main_panel.visible = panel == main_panel
	single_panel.visible = panel == single_panel
	multi_panel.visible = panel == multi_panel

func _show_main() -> void:
	_show_panel(main_panel)
	status_label.text = ""

func _on_single_player_pressed() -> void:
	_show_panel(single_panel)

func _on_multiplayer_pressed() -> void:
	_show_panel(multi_panel)

func _on_start_single() -> void:
	GameState.mode = GameState.Mode.SINGLE_PLAYER
	GameState.selected_map = map_option.selected
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_host() -> void:
	GameState.mode = GameState.Mode.MULTIPLAYER
	GameState.is_host = true
	var err := NetworkManager.host_game()
	if err != OK:
		status_label.text = "Failed to host game."
		return
	status_label.text = "Hosting on port %d. Waiting for players..." % GameState.DEFAULT_PORT
	_start_multiplayer_game()

func _on_join() -> void:
	GameState.mode = GameState.Mode.MULTIPLAYER
	GameState.is_host = false
	var address := address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var err := NetworkManager.join_game(address)
	if err != OK:
		status_label.text = "Failed to connect."
		return
	status_label.text = "Connecting to %s..." % address

func _on_connection_succeeded() -> void:
	status_label.text = "Connected!"
	_start_multiplayer_game()

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the address and try again."

func _start_multiplayer_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
