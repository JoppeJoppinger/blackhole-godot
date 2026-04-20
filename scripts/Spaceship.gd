extends Node3D

const G: float = 6.674e-11
const C: float = 299792458.0
const SOLAR_MASS: float = 1.989e30
const BH_MASS: float = 10.0 * 1.989e30
const SCHWARZSCHILD_RADIUS: float = 2.0 * 6.674e-11 * 10.0 * 1.989e30 / (299792458.0 * 299792458.0)
const SCALE: float = 1e6
const BH_RS_GAME: float = SCHWARZSCHILD_RADIUS / SCALE
const PHOTON_SPHERE_R: float = 1.5 * SCHWARZSCHILD_RADIUS / SCALE

var velocity: Vector3 = Vector3.ZERO
var structural_integrity: float = 100.0
var ship_time: float = 0.0
var universal_time: float = 0.0
var thrust_power: float = 4.0
var rotation_speed: float = 0.8
var is_cockpit_camera: bool = false
var black_hole: Node3D = null
var sound_manager: Node = null
var is_thrusting: bool = false
var is_boosting: bool = false
var engines_killed: bool = false

# Mouse look for cockpit camera
var mouse_delta: Vector2 = Vector2.ZERO
var cockpit_yaw: float = 0.0
var cockpit_pitch: float = 0.0

@onready var chase_cam: Camera3D = $ChaseCamera
@onready var cockpit_node: Node3D = $CockpitNode
@onready var hull_mesh: MeshInstance3D = $HullMesh
@onready var engine_glow_l: OmniLight3D = $EngineGlowL
@onready var engine_glow_r: OmniLight3D = $EngineGlowR
@onready var exhaust_l: GPUParticles3D = $ExhaustL
@onready var exhaust_r: GPUParticles3D = $ExhaustR

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_build_hull_mesh()
	chase_cam.current = true
	if cockpit_node:
		cockpit_node.get_camera().current = false

func _build_hull_mesh() -> void:
	var arr_mesh = ArrayMesh.new()
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()

	# Fuselage: cylinder approximation using quads
	_add_cylinder(verts, normals, Vector3(0, 0, 0), 0.3, 0.3, 5.0, 12)
	# Nose cone
	_add_cone(verts, normals, Vector3(0, 0, -2.5), 0.3, 1.0, 12, true)
	# Tail cone
	_add_cone(verts, normals, Vector3(0, 0, 2.5), 0.3, 0.8, 12, false)

	# Cockpit bubble on top-front
	_add_sphere_cap(verts, normals, Vector3(0, 0.25, -1.8), 0.25, 8)

	# Wings: two swept-back flat boxes
	# Left wing
	_add_box_mesh(verts, normals, Vector3(-0.3, -0.05, 0.0), Vector3(-1.8, 0.04, 1.2))
	# Right wing
	_add_box_mesh(verts, normals, Vector3(0.3, -0.05, 0.0), Vector3(1.8, 0.04, 1.2))

	# Engine nacelles
	# Left nacelle
	_add_cylinder(verts, normals, Vector3(-1.2, -0.1, 0.5), 0.15, 0.15, 1.8, 8)
	_add_cone(verts, normals, Vector3(-1.2, -0.1, 1.4), 0.15, 0.4, 8, false)
	# Right nacelle
	_add_cylinder(verts, normals, Vector3(1.2, -0.1, 0.5), 0.15, 0.15, 1.8, 8)
	_add_cone(verts, normals, Vector3(1.2, -0.1, 1.4), 0.15, 0.4, 8, false)

	# Hull panel detail lines: thin raised strips
	for pi in 4:
		var pz = -1.5 + float(pi) * 0.8
		_add_box_mesh(verts, normals, Vector3(-0.31, 0.0, pz), Vector3(0.31, 0.03, pz + 0.05))

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.17, 0.20)
	mat.metallic = 0.85
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.2, 0.5)
	mat.emission_energy_multiplier = 0.3
	hull_mesh.mesh = arr_mesh
	hull_mesh.set_surface_override_material(0, mat)

func _add_box_mesh(verts: PackedVector3Array, normals: PackedVector3Array, a: Vector3, b: Vector3) -> void:
	var mn = Vector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))
	var mx = Vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
	var faces = [
		[Vector3(mn.x,mn.y,mx.z), Vector3(mx.x,mn.y,mx.z), Vector3(mx.x,mx.y,mx.z), Vector3(mn.x,mx.y,mx.z), Vector3(0,0,1)],
		[Vector3(mx.x,mn.y,mn.z), Vector3(mn.x,mn.y,mn.z), Vector3(mn.x,mx.y,mn.z), Vector3(mx.x,mx.y,mn.z), Vector3(0,0,-1)],
		[Vector3(mn.x,mx.y,mn.z), Vector3(mx.x,mx.y,mn.z), Vector3(mx.x,mx.y,mx.z), Vector3(mn.x,mx.y,mx.z), Vector3(0,1,0)],
		[Vector3(mn.x,mn.y,mx.z), Vector3(mx.x,mn.y,mx.z), Vector3(mx.x,mn.y,mn.z), Vector3(mn.x,mn.y,mn.z), Vector3(0,-1,0)],
		[Vector3(mx.x,mn.y,mn.z), Vector3(mx.x,mn.y,mx.z), Vector3(mx.x,mx.y,mx.z), Vector3(mx.x,mx.y,mn.z), Vector3(1,0,0)],
		[Vector3(mn.x,mn.y,mx.z), Vector3(mn.x,mn.y,mn.z), Vector3(mn.x,mx.y,mn.z), Vector3(mn.x,mx.y,mx.z), Vector3(-1,0,0)],
	]
	for face in faces:
		var n = face[4] as Vector3
		# two triangles per quad
		for idx in [[0,1,2], [0,2,3]]:
			for vi in idx:
				verts.append(face[vi] as Vector3)
				normals.append(n)

func _add_cylinder(verts: PackedVector3Array, normals: PackedVector3Array,
		center: Vector3, r: float, _r2: float, length: float, segs: int) -> void:
	var half = length * 0.5
	for i in segs:
		var a0 = TAU * float(i) / float(segs)
		var a1 = TAU * float(i + 1) / float(segs)
		var x0 = cos(a0) * r; var y0 = sin(a0) * r
		var x1 = cos(a1) * r; var y1 = sin(a1) * r
		var p0f = center + Vector3(x0, y0, -half)
		var p1f = center + Vector3(x1, y1, -half)
		var p0b = center + Vector3(x0, y0,  half)
		var p1b = center + Vector3(x1, y1,  half)
		var n0 = Vector3(x0, y0, 0).normalized()
		var n1 = Vector3(x1, y1, 0).normalized()
		# two triangles
		verts.append(p0f); normals.append(n0)
		verts.append(p1f); normals.append(n1)
		verts.append(p1b); normals.append(n1)
		verts.append(p0f); normals.append(n0)
		verts.append(p1b); normals.append(n1)
		verts.append(p0b); normals.append(n0)

func _add_cone(verts: PackedVector3Array, normals: PackedVector3Array,
		base_center: Vector3, base_r: float, length: float, segs: int, forward: bool) -> void:
	var tip = base_center + Vector3(0, 0, -length if forward else length)
	for i in segs:
		var a0 = TAU * float(i) / float(segs)
		var a1 = TAU * float(i + 1) / float(segs)
		var x0 = cos(a0) * base_r; var y0 = sin(a0) * base_r
		var x1 = cos(a1) * base_r; var y1 = sin(a1) * base_r
		var p0 = base_center + Vector3(x0, y0, 0)
		var p1 = base_center + Vector3(x1, y1, 0)
		var n_mid = ((p0 + p1) * 0.5 - tip).normalized()
		verts.append(p0); normals.append(n_mid)
		verts.append(p1); normals.append(n_mid)
		verts.append(tip); normals.append(n_mid)

func _add_sphere_cap(verts: PackedVector3Array, normals: PackedVector3Array,
		center: Vector3, r: float, segs: int) -> void:
	for lat in segs / 2:
		var phi0 = PI * float(lat) / float(segs / 2)
		var phi1 = PI * float(lat + 1) / float(segs / 2)
		for lon in segs:
			var th0 = TAU * float(lon) / float(segs)
			var th1 = TAU * float(lon + 1) / float(segs)
			var p = [
				center + Vector3(sin(phi0)*cos(th0), cos(phi0), sin(phi0)*sin(th0)) * r,
				center + Vector3(sin(phi0)*cos(th1), cos(phi0), sin(phi0)*sin(th1)) * r,
				center + Vector3(sin(phi1)*cos(th1), cos(phi1), sin(phi1)*sin(th1)) * r,
				center + Vector3(sin(phi1)*cos(th0), cos(phi1), sin(phi1)*sin(th0)) * r,
			]
			var n = [(p[0]-center).normalized(), (p[1]-center).normalized(),
					 (p[2]-center).normalized(), (p[3]-center).normalized()]
			for idx in [[0,1,2],[0,2,3]]:
				for vi in idx:
					verts.append(p[vi])
					normals.append(n[vi])

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	if event.is_action_pressed("switch_camera"):
		is_cockpit_camera = !is_cockpit_camera
		chase_cam.current = !is_cockpit_camera
		if cockpit_node:
			cockpit_node.get_camera().current = is_cockpit_camera
		# reset mouse look
		cockpit_yaw = 0.0
		cockpit_pitch = 0.0
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if black_hole == null:
		return

	# Mouse rotation
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if is_cockpit_camera:
			# Mouse look: move virtual camera, limited to ±30°
			cockpit_yaw   = clamp(cockpit_yaw   - mouse_delta.x * 0.002, -PI/6.0, PI/6.0)
			cockpit_pitch = clamp(cockpit_pitch - mouse_delta.y * 0.002, -PI/6.0, PI/6.0)
			if cockpit_node:
				cockpit_node.get_camera().rotation = Vector3(cockpit_pitch, cockpit_yaw, 0)
		else:
			rotate_y(-mouse_delta.x * 0.002)
			rotate_object_local(Vector3.RIGHT, -mouse_delta.y * 0.002)
	mouse_delta = Vector2.ZERO

	# Keyboard roll
	if Input.is_action_pressed("move_left"):
		rotate_object_local(Vector3.FORWARD, rotation_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_object_local(Vector3.FORWARD, -rotation_speed * delta)

	# Thrust
	var thrust = Vector3.ZERO
	is_boosting = Input.is_action_pressed("boost")
	var thrust_mult = 3.0 if is_boosting else 1.0

	if not engines_killed:
		if Input.is_action_pressed("move_forward") or Input.is_action_pressed("thrust"):
			thrust += -global_transform.basis.z * thrust_power * thrust_mult
		if Input.is_action_pressed("move_back") or Input.is_action_pressed("brake"):
			thrust += global_transform.basis.z * thrust_power * 0.5 * thrust_mult
		if Input.is_action_pressed("strafe_left"):
			thrust += -global_transform.basis.x * thrust_power * 0.5
		if Input.is_action_pressed("strafe_right"):
			thrust += global_transform.basis.x * thrust_power * 0.5

	if Input.is_action_pressed("kill_engines"):
		engines_killed = true
	else:
		engines_killed = false

	is_thrusting = thrust.length() > 1.0

	# Engine glow & exhaust
	var glow_energy = 1.0 + (3.0 if is_boosting else 0.0) + (2.0 if is_thrusting else 0.0)
	if engine_glow_l:
		engine_glow_l.light_energy = lerp(engine_glow_l.light_energy, glow_energy, 0.1)
	if engine_glow_r:
		engine_glow_r.light_energy = lerp(engine_glow_r.light_energy, glow_energy, 0.1)
	if exhaust_l:
		exhaust_l.emitting = is_thrusting
	if exhaust_r:
		exhaust_r.emitting = is_thrusting

	# FOV change on boost (cockpit camera)
	if cockpit_node:
		var cam = cockpit_node.get_camera()
		var target_fov = 100.0 if is_boosting else 90.0
		cam.fov = lerp(cam.fov, target_fov, 0.05)

	# Cockpit head bob & tidal shake
	var tidal_g = 0.0
	if black_hole:
		var tidal_accel = black_hole.get_tidal_acceleration(global_position, 50.0)
		tidal_g = tidal_accel / 9.81
	if cockpit_node:
		cockpit_node.set_thrusting(is_thrusting)
		cockpit_node.update_camera_bob(delta, tidal_g)

	# Sound
	if sound_manager:
		var thrust_factor = clamp(thrust.length() / (thrust_power * 3.0), 0.0, 1.0)
		sound_manager.set_engine_thrust(thrust_factor, is_boosting)

		var r = (black_hole.global_position - global_position).length()
		var near_photon = r < PHOTON_SPHERE_R * 1.5
		sound_manager.play_proximity_alarm(near_photon)

		var stress = clamp((tidal_g - 10.0) / 200.0, 0.0, 1.0)
		sound_manager.set_structural_stress(stress)

		var at_horizon = r < BH_RS_GAME * 2.0
		sound_manager.play_horizon_warning(at_horizon)

	# Apply gravitational acceleration
	var grav_accel = black_hole.get_grav_acceleration(global_position)

	# Frame dragging
	var frame_drag = black_hole.get_frame_dragging(global_position)
	var tangential = global_position.cross(Vector3.UP).normalized()
	var drag_force = tangential * frame_drag * 1e8

	velocity += (thrust + grav_accel + drag_force) * delta

	# Speed of light cap
	var speed_ms = velocity.length() * SCALE
	if speed_ms > C * 0.99:
		velocity = velocity.normalized() * (C * 0.99 / SCALE)

	velocity *= 0.998
	global_position += velocity * delta

	# Time dilation
	var dilation = black_hole.get_time_dilation(global_position, velocity)
	ship_time += delta * dilation
	universal_time += delta

	# Tidal deformation
	if tidal_g > 10.0:
		var stretch = 1.0 + clamp((tidal_g - 10.0) * 0.001, 0.0, 5.0)
		var squish = 1.0 / sqrt(stretch)
		if hull_mesh:
			hull_mesh.scale = Vector3(squish, squish, stretch)
	else:
		if hull_mesh:
			hull_mesh.scale = Vector3.ONE

	# Structural damage
	if tidal_g > 100.0:
		structural_integrity -= (tidal_g - 100.0) * 0.01 * delta
		structural_integrity = max(0.0, structural_integrity)

	var r2 = (black_hole.global_position - global_position).length()
	if r2 < BH_RS_GAME:
		structural_integrity = 0.0

func get_speed_fraction() -> float:
	return velocity.length() * SCALE / C

func get_speed_kms() -> float:
	return velocity.length() * SCALE / 1000.0
