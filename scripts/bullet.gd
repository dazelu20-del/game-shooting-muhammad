extends Area3D

const SPEED := 55.0
const DAMAGE := 50
const LIFETIME := 3.0
const SWEEP_STEP := 0.08

var direction := Vector3.FORWARD
var shooter: Node3D = null

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
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
	var motion := direction * SPEED * delta
	var steps := maxi(1, ceili(motion.length() / SWEEP_STEP))
	var step := motion / float(steps)
	for _i in steps:
		if _sweep_for_hit(global_position + step):
			return
		global_position += step

func _get_exclude_rids() -> Array[RID]:
	var exclude: Array[RID] = [get_rid()]
	if shooter is CollisionObject3D:
		exclude.append((shooter as CollisionObject3D).get_rid())
	return exclude

func _sweep_for_hit(test_position: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = collision_shape.shape
	var xf := global_transform
	xf.origin = test_position
	params.transform = xf
	params.collision_mask = collision_mask
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = _get_exclude_rids()

	for hit in space_state.intersect_shape(params, 16):
		var collider: Object = hit.collider
		if collider is Area3D and (collider as Area3D).is_in_group("hitbox"):
			var target := _find_damageable(collider as Node)
			if target:
				global_position = test_position
				_handle_hit(target)
				return true
		elif collider is CharacterBody3D:
			var body := collider as CharacterBody3D
			if body != shooter and body.has_method("take_damage"):
				global_position = test_position
				_handle_hit(body)
				return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_handle_hit(body)
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
