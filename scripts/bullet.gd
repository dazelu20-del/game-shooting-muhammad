extends Area3D

const SPEED := 30.0
const DAMAGE := 25
const LIFETIME := 3.0

var direction := Vector3.FORWARD
var shooter: Node3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var timer := get_tree().create_timer(LIFETIME)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area3D) -> void:
	if area.get_parent() is CharacterBody3D:
		_handle_hit(area.get_parent())

func _handle_hit(target: Node3D) -> void:
	if target == shooter:
		return
	if target.has_method("take_damage"):
		target.take_damage(DAMAGE, shooter)
		queue_free()
