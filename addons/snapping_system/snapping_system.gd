@tool
extends EditorPlugin

const RAY_LENGTH = 1000

@onready var undo_redo = get_undo_redo()
var undo_position = null
var snap_mode_toggle = false
var by_normal = true

var selection = EditorInterface.get_selection()
var selected : Node3D = null
var dragging = false


func _enter_tree() -> void:
	selection.connect("selection_changed", _on_selection_changed)


func _exit_tree() -> void:
	pass


func _handles(object):
	if object is Node3D:
		return true
	return false


func _forward_3d_gui_input(camera, event):
	# Test block
	#if Input.is_key_pressed(KEY_T):
		#var camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
		#var mouse_pos = get_viewport().get_mouse_position()
		#var editor_viewport = EditorInterface.get_editor_viewport_3d()
		#var editor_camera = editor_viewport.get_camera_3d()
		#var projected_ray_origin = camera.project_ray_origin(mouse_pos)
		#var projected_ray_normal = camera.project_ray_normal(mouse_pos)
		#var query = PhysicsRayQueryParameters3D.create(projected_ray_origin, projected_ray_origin + projected_ray_normal * 400)
		#var ray = selected.get_world_3d().direct_space_state.intersect_ray(query)
		#print("Camera position: " + str(editor_camera.global_position))
		#print("Mouse position: " + str(mouse_pos))
		#print("Object position: " + str(selected.global_position))
		#print("Object rotation: " + str(selected.rotation))
		#print("Projected ray origin " + str(projected_ray_origin))
		#print("Projected ray normal " + str(projected_ray_normal))
		#print("Ray " + str(ray) + '\n')
	
	if selected == null:
		return false
	
	
	if Input.is_key_pressed(KEY_W) and Input.is_key_pressed(KEY_ALT) and not snap_mode_toggle:
		snap_mode_toggle = true
		print("snap_mode is " + str(snap_mode_toggle))
	
	if event.is_action_pressed("ui_cancel") and snap_mode_toggle:
		snap_mode_toggle = false
		
	# BUG: Undo Works only in forward direction (ctrl + shift + z)
	if not dragging and snap_mode_toggle:
		undo_redo.create_action("Snapping to surface")
		undo_redo.add_do_property(selected, "global_transform", selected.global_transform)
		undo_redo.add_undo_property(selected, "global_transform", undo_position)
		undo_redo.commit_action()
	dragging = snap_mode_toggle
	
	if dragging and event is InputEventMouse:
		var surface = get_surface(camera)
		if not surface:
			return
		var face_normal = surface.normal
		selected.position = surface.position
		if by_normal:
			selected.global_transform = align_with_y(selected.global_transform, face_normal)
	
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		snap_mode_toggle = false
		dragging = false
	
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and snap_mode_toggle:
		by_normal = not by_normal


# BUG: Sees CollisionShape3D of a selected Node3D and lagging
func get_surface(camera) -> Dictionary:
	#Ray cast to object
		#var ray_origin = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_position
		#var ray_direction = ray_origin.direction_to(selected.global_position)
		#var ray_length = 300
		#var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
		#var ray_result = selected.get_world_3d().direct_space_state.intersect_ray(query)
	
	# Ray cast to mouse pos
	var mouse_pos = EditorInterface.get_editor_viewport_3d().get_mouse_position()
	var editor_viewport = EditorInterface.get_editor_viewport_3d()
	var editor_camera = editor_viewport.get_camera_3d()
	var projected_ray_normal = camera.project_ray_normal(mouse_pos)
	var query = PhysicsRayQueryParameters3D.create(camera.position, camera.position + projected_ray_normal * RAY_LENGTH)
	var ray_result = selected.get_world_3d().direct_space_state.intersect_ray(query)
	return ray_result


#func snap_to_surface():
	#var ray_origin = selected.position
	#var ray_direction = Vector3.DOWN
	#var ray_length = 100
	#var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	#
	#var ray_result = selected.get_world_3d().direct_space_state.intersect_ray(query)
	#print(ray_result)
	#if ray_result:
		#var surface_point = ray_result.position
		#selected.position = surface_point
		#
	#else:
		#pass


# BUG: Rotation is changing
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


# Takes parent and assigns it to selected variable
func _on_selection_changed():
	var nodes = selection.get_selected_nodes()
	if nodes.size() > 0 and nodes[0] is Node3D:
		selected = nodes[0]
	elif not selected:
		selected = null
		snap_mode_toggle = false
		by_normal = true
