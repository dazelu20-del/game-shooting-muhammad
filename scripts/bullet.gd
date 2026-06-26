extends Area3D

const SPEED := 55.0
const DAMAGE := 50
const LIFETIME := 3.0

var direction := Vector3.FORWARD
var shooter: Node3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_apply_bullet_material()
	_align_to_direction()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)

func _apply_bullet_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.62, 0.15)
	mat.metallic = 0.85
	mat.roughness = 0.25
	mesh.material_override = mat

func _align_to_direction() -> void:
	if direction.length_squared() < 0.001:
		return
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		return
	_handle_hit(body)

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("hitbox"):
		return
	var target := _find_damageable(area)
	if target:
		_handle_hit(target)

func _find_damageable(node: Node) -> Node3D:
	var current: Node = node
	while current:
		if current is CharacterBody3D and current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
func _handle_hit(target: Node3D) -> void:
	if target == shooter:
		return
	if target.has_method("take_damage"):
		target.take_damage(DAMAGE, shooter)
		queue_free()
