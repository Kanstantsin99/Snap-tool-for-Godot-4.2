@tool
extends EditorPlugin

const RAY_LENGTH: int = 1000

var snap_mode_toggle := false
var by_normal := true
var undo_transform: Transform3D
var selection := EditorInterface.get_selection()
var selected: Node3D

@onready var undo_redo := get_undo_redo()


func _enter_tree() -> void:
	selection.connect("selection_changed", _on_selection_changed)


func _exit_tree() -> void:
	pass


func _handles(object):
	if object is Node3D:
		return true
	return false


func _forward_3d_gui_input(camera, event):	
	if selected == null:
		return false
	
	if Input.is_key_pressed(KEY_W) and Input.is_key_pressed(KEY_ALT) and not snap_mode_toggle:
		snap_mode_toggle = true
		print("snap_mode is ON")
		hide_gizmo()
	
	if event.is_action_pressed("ui_cancel") and snap_mode_toggle:
		snap_mode_toggle = false
		print("snap_mode is OFF")
		show_gizmo()
		selected.global_transform = undo_transform
	
	if snap_mode_toggle and event is InputEventMouse:
		var surface = get_surface(camera)
		if not surface:
			return
		var face_normal = surface.normal
		selected.position = surface.position
		if by_normal:
			var scale = selected.scale
			selected.global_transform = align_with_y(selected.global_transform, face_normal)
			selected.scale = scale
	
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and snap_mode_toggle:
		snap_mode_toggle = false
		print("snap_mode is OFF")
		show_gizmo()
		undo_redo.create_action("Snapping to surface")
		undo_redo.add_do_property(selected, "global_transform", selected.global_transform)
		undo_redo.add_undo_property(selected, "global_transform", undo_transform)
		undo_redo.commit_action()
		undo_transform = selected.global_transform
	
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and snap_mode_toggle:
		by_normal = not by_normal
		selected.global_transform = undo_transform


func get_surface(camera) -> Dictionary:
	# Ray cast to mouse pos
	var mouse_pos = EditorInterface.get_editor_viewport_3d().get_mouse_position()
	var editor_viewport = EditorInterface.get_editor_viewport_3d()
	var editor_camera = editor_viewport.get_camera_3d()
	var projected_ray_normal = camera.project_ray_normal(mouse_pos)
	var query = PhysicsRayQueryParameters3D.create(camera.position, camera.position + projected_ray_normal * RAY_LENGTH)
	var collisions: Array
	collision_search(selected, collisions)
	query.exclude = collisions
	var ray_result = selected.get_world_3d().direct_space_state.intersect_ray(query)
	return ray_result


# BUG: Rotation is changing
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


# Array of node children -> returns collision node path
func collision_search(node, arr:=[]) -> Array:
	arr.push_back(node)
	for child in node.get_children():
		arr = collision_search(child, arr)
	return arr.filter(func(x): return x is CollisionObject3D)


func hide_gizmo():
	selected.set_meta("_edit_lock_", true)


func show_gizmo():
	selected.remove_meta("_edit_lock_")


# Takes parent and assigns it to selected variable
func _on_selection_changed():
	var nodes = selection.get_selected_nodes()
	if nodes.size() > 0 and nodes[0] is Node3D:
		selected = nodes[0]
		undo_transform = selected.transform
		by_normal = true
	elif not selected:
		selected = null
