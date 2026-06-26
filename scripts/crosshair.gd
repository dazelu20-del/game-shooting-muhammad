extends Control

const COLOR := Color(1, 1, 1, 0.9)
const LINE_LENGTH := 8.0
const LINE_THICKNESS := 2.0
const GAP := 3.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var half_thick := LINE_THICKNESS * 0.5

	draw_rect(Rect2(center.x - GAP - LINE_LENGTH, center.y - half_thick, LINE_LENGTH, LINE_THICKNESS), COLOR)
	draw_rect(Rect2(center.x + GAP, center.y - half_thick, LINE_LENGTH, LINE_THICKNESS), COLOR)
	draw_rect(Rect2(center.x - half_thick, center.y - GAP - LINE_LENGTH, LINE_THICKNESS, LINE_LENGTH), COLOR)
	draw_rect(Rect2(center.x - half_thick, center.y + GAP, LINE_THICKNESS, LINE_LENGTH), COLOR)
