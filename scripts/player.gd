extends CharacterBody3D

const SPEED := 6.0
const MOUSE_SENSITIVITY := 0.003
const SHOOT_COOLDOWN := 0.25
const MAX_HEALTH := 100

@export var player_color: Color = Color(0.2, 0.6, 1.0)

@onready var camera: Camera3D = $Camera3D
@onready var shoot_point: Marker3D = $Camera3D/ShootPoint
@onready var steve_body: Node3D = $SteveBody
@onready var fps_gun: Node3D = $Camera3D/FpsGun
@onready var world_gun: Node3D = $GunMount/WorldGun

var health: int = MAX_HEALTH
var shoot_timer: float = 0.0
var spawn_protection: float = 3.0
var is_local: bool = false

signal died(player: Node3D)
signal health_changed(current: int, maximum: int)

func _ready() -> void:
	_apply_color()
	spawn_protection = 3.0
	health_changed.emit(health, MAX_HEALTH)
	if is_multiplayer_authority():
		is_local = true
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		steve_body.visible = false
		fps_gun.visible = true
		world_gun.visible = false
	else:
		camera.current = false
		fps_gun.visible = false
		world_gun.visible = true

func _apply_color() -> void:
	if steve_body.has_method("apply_tint"):
		steve_body.apply_tint(player_color)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if event.is_action_pressed("shoot"):
		_try_shoot()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	shoot_timer = max(shoot_timer - delta, 0.0)
	if spawn_protection > 0.0:
		spawn_protection = max(spawn_protection - delta, 0.0)

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	move_and_slide()

	if multiplayer.multiplayer_peer and is_multiplayer_authority():
		_sync_transform.rpc(global_position, rotation.y, camera.rotation.x)

@rpc("any_peer", "call_local", "unreliable")
func _sync_transform(pos: Vector3, body_rot_y: float, cam_rot_x: float) -> void:
	if is_multiplayer_authority():
		return
	global_position = pos
	rotation.y = body_rot_y
	camera.rotation.x = cam_rot_x

func _try_shoot() -> void:
	if shoot_timer > 0.0:
		return
	shoot_timer = SHOOT_COOLDOWN
	if multiplayer.multiplayer_peer:
		_rpc_shoot.rpc()
	else:
		_rpc_shoot()

@rpc("any_peer", "call_local", "reliable")
func _rpc_shoot() -> void:
	if fps_gun.has_method("play_recoil"):
		fps_gun.play_recoil()
	if world_gun.has_method("play_recoil"):
		world_gun.play_recoil()
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var bullet: Area3D = bullet_scene.instantiate()
	bullet.shooter = self
	bullet.direction = -shoot_point.global_transform.basis.z
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = shoot_point.global_position

func take_damage(amount: int, attacker: Node3D = null) -> void:
	if spawn_protection > 0.0:
		return
	if multiplayer.multiplayer_peer:
		if is_multiplayer_authority():
			_apply_damage(amount, attacker)
		else:
			_request_damage.rpc_id(get_multiplayer_authority(), amount)
	else:
		_apply_damage(amount, attacker)

@rpc("any_peer", "call_remote", "reliable")
func _request_damage(amount: int) -> void:
	if is_multiplayer_authority():
		_apply_damage(amount)

func _apply_damage(amount: int, _attacker: Node3D = null) -> void:
	health -= amount
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_die()

func _die(_killer: Node3D = null) -> void:
	died.emit(self)
	if is_local:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if steve_body.has_method("set_hitboxes_enabled"):
		steve_body.set_hitboxes_enabled(false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	visible = false
	set_physics_process(false)
	set_process(false)
	if multiplayer.multiplayer_peer:
		_notify_death.rpc()

@rpc("any_peer", "call_local", "reliable")
func _notify_death() -> void:
	if steve_body.has_method("set_hitboxes_enabled"):
		steve_body.set_hitboxes_enabled(false)
	visible = false
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	set_physics_process(false)
	set_process(false)

func get_display_name() -> String:
	if name.begins_with("Player"):
		return "Player %s" % name.trim_prefix("Player")
	return name
