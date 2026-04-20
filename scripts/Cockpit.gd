extends Node3D
# Cockpit.gd - Builds procedural 3D cockpit mesh and manages cockpit camera

@onready var cockpit_camera: Camera3D = $CockpitCamera
@onready var cockpit_mesh: MeshInstance3D = $CockpitMesh

var head_bob_time: float = 0.0
var head_bob_intensity: float = 0.0
var base_camera_pos: Vector3 = Vector3(0.0, 0.12, 0.08)

func _ready() -> void:
	_build_cockpit_mesh()
	cockpit_camera.near = 0.05
	_build_throttle_lever()

func _build_cockpit_mesh() -> void:
	var arr_mesh = ArrayMesh.new()

	# We'll accumulate all cockpit geometry as a list of triangles
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()

	# ── Dashboard panel (in front of camera, below view line) ──
	_add_box(verts, normals, colors,
		Vector3(-0.8, -0.3, -0.3),  # min
		Vector3( 0.8, -0.05, 0.1),  # max
		Color(0.08, 0.09, 0.10))    # dark metal

	# Dashboard raised center section
	_add_box(verts, normals, colors,
		Vector3(-0.35, -0.05, -0.28),
		Vector3( 0.35,  0.05, 0.0),
		Color(0.06, 0.07, 0.09))

	# ── Left side panel ──
	_add_box(verts, normals, colors,
		Vector3(-1.1, -0.5, -0.5),
		Vector3(-0.75, 0.4, 0.2),
		Color(0.07, 0.08, 0.10))

	# ── Right side panel ──
	_add_box(verts, normals, colors,
		Vector3(0.75, -0.5, -0.5),
		Vector3(1.1, 0.4, 0.2),
		Color(0.07, 0.08, 0.10))

	# ── Windshield frame ──
	# top bar
	_add_box(verts, normals, colors,
		Vector3(-0.85, 0.45, -0.8),
		Vector3( 0.85, 0.55, -0.3),
		Color(0.1, 0.11, 0.12))
	# left pillar
	_add_box(verts, normals, colors,
		Vector3(-0.85, -0.1, -0.85),
		Vector3(-0.75, 0.55, -0.3),
		Color(0.1, 0.11, 0.12))
	# right pillar
	_add_box(verts, normals, colors,
		Vector3(0.75, -0.1, -0.85),
		Vector3(0.85, 0.55, -0.3),
		Color(0.1, 0.11, 0.12))
	# bottom frame bar
	_add_box(verts, normals, colors,
		Vector3(-0.85, -0.12, -0.85),
		Vector3( 0.85, -0.05, -0.3),
		Color(0.1, 0.11, 0.12))

	# ── Glowing screen panels on dashboard ──
	# Left screen
	_add_box(verts, normals, colors,
		Vector3(-0.65, -0.04, -0.25),
		Vector3(-0.38, 0.04, -0.05),
		Color(0.0, 0.15, 0.25))  # dark blue screen

	# Right screen
	_add_box(verts, normals, colors,
		Vector3(0.38, -0.04, -0.25),
		Vector3(0.65, 0.04, -0.05),
		Color(0.0, 0.15, 0.25))

	# Center display
	_add_box(verts, normals, colors,
		Vector3(-0.20, -0.04, -0.27),
		Vector3( 0.20,  0.04, -0.02),
		Color(0.0, 0.10, 0.20))

	# ── Buttons on side panels (little nubs) ──
	for bi in 6:
		var bx_l = -1.05
		var bx_r =  1.05
		var by = -0.3 + float(bi) * 0.1
		# left
		_add_box(verts, normals, colors,
			Vector3(bx_l, by, -0.2),
			Vector3(bx_l + 0.04, by + 0.04, -0.15),
			Color(0.3, 0.05 + float(bi) * 0.03, 0.05))
		# right
		_add_box(verts, normals, colors,
			Vector3(bx_r - 0.04, by, -0.2),
			Vector3(bx_r, by + 0.04, -0.15),
			Color(0.05, 0.05 + float(bi) * 0.03, 0.3))

	# ── Pilot seat headrest (visible at periphery bottom) ──
	_add_box(verts, normals, colors,
		Vector3(-0.25, -0.6, 0.3),
		Vector3( 0.25, -0.1, 0.5),
		Color(0.12, 0.10, 0.09))
	# seat back
	_add_box(verts, normals, colors,
		Vector3(-0.3, -0.9, 0.25),
		Vector3( 0.3, -0.6, 0.55),
		Color(0.10, 0.08, 0.08))

	# ── Floor ──
	_add_box(verts, normals, colors,
		Vector3(-1.0, -0.95, -0.3),
		Vector3( 1.0, -0.90, 0.6),
		Color(0.05, 0.05, 0.06))

	# ── Build ArrayMesh ──
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Material: vertex color + some emission on screens
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.6
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.08, 0.15)
	mat.emission_energy_multiplier = 1.2
	cockpit_mesh.mesh = arr_mesh
	cockpit_mesh.set_surface_override_material(0, mat)
	cockpit_mesh.position = Vector3(0, -0.1, -0.4)

	# Screen glow lights
	var light_colors = [Color(0.0, 0.5, 1.0), Color(0.0, 0.8, 0.5), Color(0.3, 0.0, 0.8)]
	var light_positions = [Vector3(-0.52, 0.1, -0.15), Vector3(0.52, 0.1, -0.15), Vector3(0.0, 0.15, -0.15)]
	for li in 3:
		var light = OmniLight3D.new()
		light.position = light_positions[li]
		light.light_color = light_colors[li]
		light.light_energy = 0.4
		light.omni_range = 0.8
		cockpit_mesh.add_child(light)

func _add_box(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray,
		mn: Vector3, mx: Vector3, col: Color) -> void:
	# 6 faces × 2 triangles × 3 verts = 36 verts
	var faces = [
		# front (z = mx.z)
		[Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mx.z), Vector3(mx.x, mx.y, mx.z),
		 Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z),
		 Vector3(0, 0, 1)],
		# back (z = mn.z)
		[Vector3(mx.x, mn.y, mn.z), Vector3(mn.x, mn.y, mn.z), Vector3(mn.x, mx.y, mn.z),
		 Vector3(mx.x, mn.y, mn.z), Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mn.z),
		 Vector3(0, 0, -1)],
		# top (y = mx.y)
		[Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mn.z), Vector3(mx.x, mx.y, mx.z),
		 Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z),
		 Vector3(0, 1, 0)],
		# bottom (y = mn.y)
		[Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mx.z), Vector3(mx.x, mn.y, mn.z),
		 Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mn.z), Vector3(mn.x, mn.y, mn.z),
		 Vector3(0, -1, 0)],
		# right (x = mx.x)
		[Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mn.y, mx.z), Vector3(mx.x, mx.y, mx.z),
		 Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mx.y, mx.z), Vector3(mx.x, mx.y, mn.z),
		 Vector3(1, 0, 0)],
		# left (x = mn.x)
		[Vector3(mn.x, mn.y, mx.z), Vector3(mn.x, mn.y, mn.z), Vector3(mn.x, mx.y, mn.z),
		 Vector3(mn.x, mn.y, mx.z), Vector3(mn.x, mx.y, mn.z), Vector3(mn.x, mx.y, mx.z),
		 Vector3(-1, 0, 0)],
	]
	for face in faces:
		var n = face[6] as Vector3
		for vi in 6:
			verts.append(face[vi] as Vector3)
			normals.append(n)
			colors.append(col)

func set_thrusting(is_thrusting: bool) -> void:
	if is_thrusting:
		head_bob_intensity = min(head_bob_intensity + 0.02, 1.0)
	else:
		head_bob_intensity = max(head_bob_intensity - 0.04, 0.0)

func update_camera_bob(delta: float, tidal_g: float) -> void:
	head_bob_time += delta * (2.0 + head_bob_intensity * 3.0)

	# Smooth bob
	var bob_x = sin(head_bob_time * 1.1) * 0.003 * head_bob_intensity
	var bob_y = sin(head_bob_time * 2.0) * 0.004 * head_bob_intensity

	# Tidal shake (random noise when under stress)
	var shake = 0.0
	if tidal_g > 5.0:
		shake = min((tidal_g - 5.0) * 0.001, 0.04)
		bob_x += (sin(head_bob_time * 17.3) * cos(head_bob_time * 23.7)) * shake
		bob_y += (cos(head_bob_time * 19.1) * sin(head_bob_time * 29.3)) * shake

	cockpit_camera.position = base_camera_pos + Vector3(bob_x, bob_y, 0.0)

func get_camera() -> Camera3D:
	return cockpit_camera

var throttle_lever: MeshInstance3D = null
var throttle_fraction: float = 0.0

func _build_throttle_lever() -> void:
	throttle_lever = MeshInstance3D.new()
	var arr_mesh = ArrayMesh.new()
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	# lever base
	_add_box(verts, normals, colors, Vector3(0.82, -0.28, -0.15), Vector3(0.90, -0.26, -0.05), Color(0.15, 0.15, 0.15))
	# lever handle
	_add_box(verts, normals, colors, Vector3(0.84, -0.28, -0.12), Vector3(0.88, -0.10, -0.08), Color(0.8, 0.2, 0.1))
	var arrays = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	throttle_lever.mesh = arr_mesh
	throttle_lever.set_surface_override_material(0, mat)
	add_child(throttle_lever)

func set_thrust_visual(fraction: float) -> void:
	throttle_fraction = lerp(throttle_fraction, fraction, 0.1)
	if throttle_lever:
		throttle_lever.position.z = lerp(0.0, -0.15, throttle_fraction)
