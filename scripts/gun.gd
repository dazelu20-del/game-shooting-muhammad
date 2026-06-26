extends Node3D

enum ViewMode { WORLD, FPS }

const BODY := Color(0.07, 0.07, 0.08)
const METAL := Color(0.14, 0.14, 0.15)
const METAL_LIGHT := Color(0.22, 0.22, 0.24)
const METAL_DARK := Color(0.1, 0.1, 0.11)

@export var view_mode: ViewMode = ViewMode.WORLD

var _model: Node3D
var _base_fps_pos := Vector3(0.2, -0.14, -0.32)
var _base_world_pos := Vector3.ZERO

func _ready() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_build_gun_model()
	match view_mode:
		ViewMode.FPS:
			_setup_fps_transform()
		ViewMode.WORLD:
			_setup_world_transform()

func _build_gun_model() -> void:
	# Barrel points along -Z (forward). Grip sits near the origin for easy mounting.
	_add_box("Slide", Vector3(0, 0.012, -0.055), Vector3(0.028, 0.034, 0.13), BODY, 0.75)
	_add_box("Frame", Vector3(0, -0.01, -0.02), Vector3(0.026, 0.028, 0.08), BODY, 0.7)
	_add_box("Barrel", Vector3(0, 0.008, -0.128), Vector3(0.012, 0.012, 0.03), METAL, 0.9)
	_add_box("Grip", Vector3(0, -0.048, 0.018), Vector3(0.03, 0.09, 0.036), BODY, 0.55)
	_add_box("Magwell", Vector3(0, -0.03, 0.0), Vector3(0.032, 0.02, 0.04), METAL_DARK, 0.8)
	_add_box("TriggerGuard", Vector3(0, -0.028, -0.01), Vector3(0.024, 0.03, 0.04), METAL, 0.85)
	_add_box("Trigger", Vector3(0, -0.03, -0.008), Vector3(0.006, 0.022, 0.01), METAL_LIGHT, 0.9)
	_add_box("Hammer", Vector3(0, 0.028, 0.03), Vector3(0.01, 0.018, 0.012), METAL, 0.9)
	_add_box("Beavertail", Vector3(0, 0.004, 0.04), Vector3(0.028, 0.038, 0.018), BODY, 0.7)
	_add_box("FrontSight", Vector3(0, 0.034, -0.108), Vector3(0.008, 0.01, 0.008), METAL_LIGHT, 0.95)
	_add_box("RearSight", Vector3(0, 0.034, -0.008), Vector3(0.014, 0.01, 0.01), METAL_LIGHT, 0.95)
	_add_box("Rail", Vector3(0, -0.026, -0.04), Vector3(0.022, 0.008, 0.08), METAL, 0.85)
	_add_box("MuzzleBrake", Vector3(0, 0.008, -0.145), Vector3(0.018, 0.018, 0.016), METAL_DARK, 0.9)

	for i in 3:
		_add_box("Port%d" % i, Vector3(0.015, 0.012, -0.09 - i * 0.018), Vector3(0.006, 0.01, 0.01), METAL_DARK, 0.9)

	for i in 4:
		var z := 0.01 - i * 0.012
		_add_box("GripStipple%d" % i, Vector3(0.016, -0.048, z), Vector3(0.003, 0.07, 0.008), METAL_DARK, 0.6)

	for i in 5:
		_add_box("SlideSerration%d" % i, Vector3(0.015, 0.012, 0.0 - i * 0.01), Vector3(0.004, 0.028, 0.006), METAL_DARK, 0.8)

func _add_box(part_name: String, pos: Vector3, size: Vector3, color: Color, metallic: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = part_name
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.35
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	_model.add_child(mesh_inst)
	return mesh_inst

func _setup_fps_transform() -> void:
	position = _base_fps_pos
	rotation_degrees = Vector3(-6, 0, 0)
	_model.scale = Vector3(1.2, 1.2, 1.2)

func _setup_world_transform() -> void:
	position = _base_world_pos
	rotation_degrees = Vector3(-14, 0, 10)
	_model.scale = Vector3(1.0, 1.0, 1.0)

func play_recoil() -> void:
	var base_pos := position
	var kick := Vector3(0, 0, 0.03) if view_mode == ViewMode.FPS else Vector3(0, 0, 0.02)
	var tween := create_tween()
	tween.tween_property(self, "position", base_pos + kick, 0.04)
	tween.tween_property(self, "position", base_pos, 0.08)
