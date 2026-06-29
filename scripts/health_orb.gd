extends Area3D
class_name HealthOrb

const ORB_SCENE := "res://scenes/health_orb.tscn"
const HEAL_AMOUNT := 50
const LIFETIME := 45.0
const BOB_SPEED := 2.5
const BOB_HEIGHT := 0.15
const SPIN_SPEED := 1.8

@onready var mesh: MeshInstance3D = $MeshInstance3D

var _base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	_apply_material()
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)

func _apply_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.85, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.6, 0.2)
	mat.emission_energy_multiplier = 1.8
	mat.roughness = 0.2
	mat.metallic = 0.1
	mesh.material_override = mat

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_HEIGHT
	mesh.rotate_y(SPIN_SPEED * delta)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	if not body.has_method("heal"):
		return
	if body.heal(HEAL_AMOUNT):
		queue_free()

static func spawn_at(world_position: Vector3) -> void:
	var orb_scene: PackedScene = load(ORB_SCENE) as PackedScene
	if orb_scene == null:
		return
	var orb: Area3D = orb_scene.instantiate() as Area3D
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	tree.current_scene.add_child(orb)
	orb.global_position = world_position + Vector3(0, 0.6, 0)
