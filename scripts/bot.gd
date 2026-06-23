extends CharacterBody3D

const SPEED := 4.0
const SHOOT_COOLDOWN := 1.0
const MAX_HEALTH := 100
const DETECT_RANGE := 25.0
const SHOOT_RANGE := 18.0

@export var bot_color: Color = Color(1.0, 0.3, 0.3)

@onready var shoot_point: Marker3D = $ShootPoint
@onready var body_mesh: MeshInstance3D = $BodyMesh

var health: int = MAX_HEALTH
var shoot_timer: float = 0.0
var target: Node3D = null
var combat_delay: float = 2.5

signal died(bot: Node3D)

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = bot_color
	body_mesh.material_override = mat
	shoot_timer = SHOOT_COOLDOWN
	combat_delay = 2.5

func _physics_process(delta: float) -> void:
	if combat_delay > 0.0:
		combat_delay -= delta
		velocity.y = 0.0
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		move_and_slide()
		return

	shoot_timer = max(shoot_timer - delta, 0.0)
	_find_target()

	if target and is_instance_valid(target) and target.visible:
		var to_target := target.global_position - global_position
		to_target.y = 0
		if to_target.length() > 0.5:
			look_at(global_position + to_target.normalized(), Vector3.UP)

		var dist := global_position.distance_to(target.global_position)
		if dist <= SHOOT_RANGE and shoot_timer <= 0.0:
			_shoot()
			shoot_timer = SHOOT_COOLDOWN

		if dist > 2.0:
			var move_dir := to_target.normalized()
			velocity.x = move_dir.x * SPEED
			velocity.z = move_dir.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	move_and_slide()

func _find_target() -> void:
	var best_dist := DETECT_RANGE
	target = null
	for node in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(node) or not node.visible:
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			target = node

func _shoot() -> void:
	if not target:
		return
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var bullet: Area3D = bullet_scene.instantiate()
	bullet.shooter = self
	var aim_dir := (target.global_position + Vector3(0, 1, 0) - shoot_point.global_position).normalized()
	bullet.direction = aim_dir
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = shoot_point.global_position

func take_damage(amount: int, _attacker: Node3D = null) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	set_collision_layer_value(2, false)
	visible = false
	set_physics_process(false)
	queue_free()
