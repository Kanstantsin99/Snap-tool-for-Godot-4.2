# Snap-tool
Snap tool is an EditorPlugin that allows to snap Node3D instances to CollisionShape3D surfaces.


## Installation
1. Drag and drop addons folder to your project.
2. Go to AssetLib -> Plugins... and enable the plugin.
3. Select 3D object and use shortcut Alt-W.
If everything was done correct you'll see a message in your debugger window ("Snap mode is ON")

## Shortcuts
- Snap to Surface (Alt+ W)
- Positions nodes relative to each other. To confirm use (Left Click), to abort use (ESC)
- Orient by normal specifies whether the node should be oriented by the surface normal or not. To toggle use (Right Click). 


## Future functionality
- Offset from surface specifies the distance from the node's pivot point to the surface (in units): use (Wheel Up) to increase, or (Wheel Down) to decrease, to reset use (Middle Click).
- Use (Ctri) to temporarily invert all current snapping controls.
