extends Node3D

const SKIN := Color(0.776, 0.612, 0.427)
const HAIR := Color(0.361, 0.251, 0.216)
const SHIRT := Color(0.0, 0.667, 0.667)
const PANTS := Color(0.180, 0.180, 0.541)
const EYE := Color(0.15, 0.1, 0.08)

const SCALE_Y := 0.9

var _shirt_parts: Array[MeshInstance3D] = []
var _hitboxes: Array[Area3D] = []

func _ready() -> void:
	_build_steve()

func _build_steve() -> void:
	var leg_w := 0.25
	var leg_h := 0.75 * SCALE_Y
	var body_w := 0.5
	var body_h := 0.75 * SCALE_Y
	var body_d := 0.25
	var arm_w := 0.25
	var arm_h := 0.75 * SCALE_Y
	var head_s := 0.5 * SCALE_Y

	var leg_y := leg_h * 0.5
	var body_y := leg_h + body_h * 0.5
	var head_y := leg_h + body_h + head_s * 0.5
	var arm_upper_h := arm_h * 0.5
	var arm_lower_h := arm_h * 0.5
	var arm_x_left := -(body_w * 0.5 + arm_w * 0.5)
	var arm_x_right := body_w * 0.5 + arm_w * 0.5
	var arm_upper_y := leg_h + body_h - arm_upper_h * 0.5
	var arm_lower_y := leg_h + body_h - arm_upper_h - arm_lower_h * 0.5

	_add_box("LeftLeg", Vector3(-leg_w * 0.5, leg_y, 0), Vector3(leg_w, leg_h, leg_w), PANTS)
	_add_box("RightLeg", Vector3(leg_w * 0.5, leg_y, 0), Vector3(leg_w, leg_h, leg_w), PANTS)
	_shirt_parts.append(_add_box("Body", Vector3(0, body_y, 0), Vector3(body_w, body_h, body_d), SHIRT))
	_shirt_parts.append(_add_box("LeftArmUpper", Vector3(arm_x_left, arm_upper_y, 0), Vector3(arm_w, arm_upper_h, arm_w), SHIRT))
	_shirt_parts.append(_add_box("RightArmUpper", Vector3(arm_x_right, arm_upper_y, 0), Vector3(arm_w, arm_upper_h, arm_w), SHIRT))
	_add_box("LeftArmLower", Vector3(arm_x_left, arm_lower_y, 0), Vector3(arm_w, arm_lower_h, arm_w), SKIN)
	_add_box("RightArmLower", Vector3(arm_x_right, arm_lower_y, 0), Vector3(arm_w, arm_lower_h, arm_w), SKIN)
	_add_box("Head", Vector3(0, head_y, 0), Vector3(head_s, head_s, head_s), SKIN)
	_add_box("Hair", Vector3(0, head_y + head_s * 0.35, 0), Vector3(head_s * 1.05, head_s * 0.3, head_s * 1.05), HAIR)

	var eye_z := head_s * 0.5 + 0.01
	var eye_y_offset := head_s * 0.05
	_add_box("LeftEye", Vector3(-head_s * 0.18, head_y + eye_y_offset, eye_z), Vector3(0.06, 0.06, 0.02), EYE)
	_add_box("RightEye", Vector3(head_s * 0.18, head_y + eye_y_offset, eye_z), Vector3(0.06, 0.06, 0.02), EYE)

func _add_box(part_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = part_name
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.metallic = 0.0
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	add_child(mesh_inst)
	_add_hitbox(part_name + "Hitbox", pos, size)
	return mesh_inst

func _add_hitbox(part_name: String, pos: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = part_name
	area.collision_layer = 8
	area.collision_mask = 4
	area.monitorable = true
	area.monitoring = false
	area.add_to_group("hitbox")
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size * 1.1
	collision.shape = box_shape
	area.add_child(collision)
	area.position = pos
	add_child(area)
	_hitboxes.append(area)

func set_hitboxes_enabled(enabled: bool) -> void:
	for area in _hitboxes:
		if is_instance_valid(area):
			area.set_collision_layer_value(4, enabled)

func apply_tint(tint: Color) -> void:
	var tinted := SHIRT.lerp(tint, 0.35)
	for part in _shirt_parts:
		if is_instance_valid(part):
			var mat := part.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = tinted
