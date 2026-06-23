extends Node3D

var floor_color: Color = Color(0.35, 0.35, 0.4)
var wall_color: Color = Color(0.5, 0.5, 0.55)
var accent_color: Color = Color(0.7, 0.3, 0.3)

func _ready() -> void:
	_configure_map_colors()
	_apply_colors()

func _configure_map_colors() -> void:
	match name:
		"MapArena":
			floor_color = Color(0.4, 0.35, 0.3)
			wall_color = Color(0.55, 0.45, 0.35)
			accent_color = Color(0.8, 0.5, 0.2)
		"MapForest":
			floor_color = Color(0.2, 0.45, 0.2)
			wall_color = Color(0.35, 0.25, 0.15)
			accent_color = Color(0.15, 0.5, 0.15)
		"MapCity":
			floor_color = Color(0.3, 0.3, 0.35)
			wall_color = Color(0.45, 0.45, 0.5)
			accent_color = Color(0.4, 0.4, 0.55)

func _apply_colors() -> void:
	if has_node("Floor/MeshInstance3D"):
		_set_mesh_color($Floor/MeshInstance3D, floor_color)
	if has_node("Walls"):
		for child in $Walls.get_children():
			var mesh_node := child.get_node_or_null("MeshInstance3D")
			if mesh_node:
				_set_mesh_color(mesh_node, wall_color)
	if has_node("Obstacles"):
		for child in $Obstacles.get_children():
			var mesh_node := child.get_node_or_null("MeshInstance3D")
			if mesh_node:
				_set_mesh_color(mesh_node, accent_color)

func _set_mesh_color(mesh_node: MeshInstance3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_node.material_override = mat

func get_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	if has_node("SpawnPoints"):
		for child in $SpawnPoints.get_children():
			if child is Marker3D:
				points.append(to_global(child.position))
	return points
