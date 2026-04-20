extends Node3D
# Cockpit.gd - Elite Dangerous inspired cockpit

@onready var cockpit_camera: Camera3D = $CockpitCamera

var head_bob_time: float = 0.0
var head_bob_intensity: float = 0.0
var base_camera_pos: Vector3 = Vector3(0.0, 0.0, 0.0)
var throttle_fraction: float = 0.0

# All mesh instances for cockpit parts
var cockpit_root: Node3D = null

func _ready() -> void:
	cockpit_camera.near = 0.03
	cockpit_camera.fov = 90.0
	cockpit_root = Node3D.new()
	cockpit_root.position = Vector3(0.0, -0.18, -0.05)
	add_child(cockpit_root)
	_build_cockpit()

func _build_cockpit() -> void:
	# ── Main dashboard/console (low, wide, dark) ──
	_add_panel(Vector3(-1.2, -0.38, -0.5), Vector3(1.2, -0.22, 0.15), Color(0.07, 0.08, 0.09))

	# Dashboard slope (angled face toward pilot)
	_add_panel(Vector3(-1.2, -0.22, -0.5), Vector3(1.2, 0.02, -0.3), Color(0.06, 0.07, 0.08))

	# ── Center MFD display ──
	_add_panel(Vector3(-0.28, -0.20, -0.48), Vector3(0.28, 0.00, -0.31), Color(0.0, 0.06, 0.12))
	_add_emissive_panel(Vector3(-0.26, -0.19, -0.47), Vector3(0.26, -0.01, -0.32), Color(0.0, 0.3, 0.5), 0.8)

	# ── Left MFD ──
	_add_panel(Vector3(-0.75, -0.20, -0.46), Vector3(-0.38, 0.00, -0.32), Color(0.0, 0.06, 0.12))
	_add_emissive_panel(Vector3(-0.73, -0.19, -0.45), Vector3(-0.40, -0.01, -0.33), Color(0.0, 0.18, 0.35), 0.6)

	# ── Right MFD ──
	_add_panel(Vector3(0.38, -0.20, -0.46), Vector3(0.75, 0.00, -0.32), Color(0.0, 0.06, 0.12))
	_add_emissive_panel(Vector3(0.40, -0.19, -0.45), Vector3(0.73, -0.01, -0.33), Color(0.0, 0.18, 0.35), 0.6)

	# ── Windshield frame - bottom bar ──
	_add_panel(Vector3(-1.05, 0.02, -0.65), Vector3(1.05, 0.07, -0.32), Color(0.08, 0.09, 0.10))

	# ── Left A-pillar ──
	_add_panel(Vector3(-1.05, 0.02, -0.90), Vector3(-0.95, 0.65, -0.32), Color(0.08, 0.09, 0.10))

	# ── Right A-pillar ──
	_add_panel(Vector3(0.95, 0.02, -0.90), Vector3(1.05, 0.65, -0.32), Color(0.08, 0.09, 0.10))

	# ── Top frame bar ──
	_add_panel(Vector3(-1.05, 0.62, -0.90), Vector3(1.05, 0.70, -0.32), Color(0.08, 0.09, 0.10))

	# ── Left side console ──
	_add_panel(Vector3(-1.35, -0.5, -0.7), Vector3(-1.05, 0.3, 0.1), Color(0.07, 0.08, 0.09))
	# Left console face
	_add_panel(Vector3(-1.35, -0.3, -0.65), Vector3(-1.07, 0.25, -0.35), Color(0.06, 0.07, 0.08))
	# Left console screen
	_add_emissive_panel(Vector3(-1.30, -0.20, -0.62), Vector3(-1.10, 0.15, -0.38), Color(0.4, 0.15, 0.0), 0.7)

	# ── Right side console ──
	_add_panel(Vector3(1.05, -0.5, -0.7), Vector3(1.35, 0.3, 0.1), Color(0.07, 0.08, 0.09))
	# Right console face
	_add_panel(Vector3(1.07, -0.3, -0.65), Vector3(1.35, 0.25, -0.35), Color(0.06, 0.07, 0.08))
	# Right console screen
	_add_emissive_panel(Vector3(1.10, -0.20, -0.62), Vector3(1.30, 0.15, -0.38), Color(0.4, 0.15, 0.0), 0.7)

	# ── Orange accent strip along dashboard top ──
	_add_emissive_panel(Vector3(-1.18, 0.01, -0.49), Vector3(1.18, 0.03, -0.31), Color(0.9, 0.4, 0.0), 1.5)

	# ── Orange accent on A-pillars ──
	_add_emissive_panel(Vector3(-1.03, 0.05, -0.87), Vector3(-0.97, 0.60, -0.84), Color(0.9, 0.4, 0.0), 1.0)
	_add_emissive_panel(Vector3(0.97, 0.05, -0.87), Vector3(1.03, 0.60, -0.84), Color(0.9, 0.4, 0.0), 1.0)

	# ── Floor ──
	_add_panel(Vector3(-1.3, -0.55, -0.5), Vector3(1.3, -0.50, 0.3), Color(0.04, 0.04, 0.05))

	# ── Throttle lever (right of center) ──
	_add_panel(Vector3(0.18, -0.38, -0.42), Vector3(0.26, -0.36, -0.35), Color(0.12, 0.12, 0.14))  # base
	_add_emissive_panel(Vector3(0.20, -0.38, -0.40), Vector3(0.24, -0.22, -0.37), Color(0.9, 0.3, 0.0), 1.2)  # handle

	# ── Ambient lights ──
	_add_light(Vector3(-0.5, 0.05, -0.4), Color(0.9, 0.4, 0.05), 0.3, 1.2)  # left orange
	_add_light(Vector3(0.5, 0.05, -0.4),  Color(0.9, 0.4, 0.05), 0.3, 1.2)  # right orange
	_add_light(Vector3(0.0, 0.02, -0.4),  Color(0.0, 0.4, 0.8),  0.25, 0.8) # center blue MFD glow

func _add_panel(mn: Vector3, mx: Vector3, color: Color) -> void:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = mx - mn
	mi.mesh = bm
	mi.position = (mn + mx) * 0.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.4
	mi.set_surface_override_material(0, mat)
	cockpit_root.add_child(mi)

func _add_emissive_panel(mn: Vector3, mx: Vector3, color: Color, energy: float) -> void:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = mx - mn
	mi.mesh = bm
	mi.position = (mn + mx) * 0.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.9
	mi.set_surface_override_material(0, mat)
	cockpit_root.add_child(mi)

func _add_light(pos: Vector3, color: Color, energy: float, range_val: float) -> void:
	var light = OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_val
	cockpit_root.add_child(light)

func set_thrusting(is_thrusting: bool) -> void:
	if is_thrusting:
		head_bob_intensity = min(head_bob_intensity + 0.02, 1.0)
	else:
		head_bob_intensity = max(head_bob_intensity - 0.04, 0.0)

func set_thrust_visual(fraction: float) -> void:
	throttle_fraction = lerp(throttle_fraction, fraction, 0.1)

func update_camera_bob(delta: float, tidal_g: float) -> void:
	head_bob_time += delta * (2.0 + head_bob_intensity * 3.0)
	var bob_x = sin(head_bob_time * 1.1) * 0.002 * head_bob_intensity
	var bob_y = sin(head_bob_time * 2.0) * 0.003 * head_bob_intensity
	var shake = 0.0
	if tidal_g > 5.0:
		shake = min((tidal_g - 5.0) * 0.001, 0.03)
		bob_x += (sin(head_bob_time * 17.3) * cos(head_bob_time * 23.7)) * shake
		bob_y += (cos(head_bob_time * 19.1) * sin(head_bob_time * 29.3)) * shake
	cockpit_camera.position = base_camera_pos + Vector3(bob_x, bob_y, 0.0)

func get_camera() -> Camera3D:
	return cockpit_camera
