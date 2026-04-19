extends Node3D

const G: float = 6.674e-11
const C: float = 299792458.0
const SOLAR_MASS: float = 1.989e30
const BH_MASS: float = 10.0 * 1.989e30
const SCHWARZSCHILD_RADIUS: float = 2.0 * 6.674e-11 * 10.0 * 1.989e30 / (299792458.0 * 299792458.0)
const SCALE: float = 1e6
const BH_RS_GAME: float = SCHWARZSCHILD_RADIUS / SCALE
const PHOTON_SPHERE_R: float = 1.5 * SCHWARZSCHILD_RADIUS / SCALE
const ISCO_R: float = 3.0 * SCHWARZSCHILD_RADIUS / SCALE

var velocity: Vector3 = Vector3.ZERO
var structural_integrity: float = 100.0
var ship_time: float = 0.0
var universal_time: float = 0.0
var thrust_power: float = 50.0
var rotation_speed: float = 1.5
var is_cockpit_camera: bool = false
var black_hole: Node3D = null

@onready var chase_cam: Camera3D = $ChaseCamera
@onready var cockpit_cam: Camera3D = $CockpitCamera
@onready var ship_mesh: MeshInstance3D = $ShipMesh
@onready var exhaust_particles: GPUParticles3D = $ExhaustParticles

var mouse_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	chase_cam.current = true
	cockpit_cam.current = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	if event.is_action_pressed("switch_camera"):
		is_cockpit_camera = !is_cockpit_camera
		chase_cam.current = !is_cockpit_camera
		cockpit_cam.current = is_cockpit_camera
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
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("thrust"):
		thrust += -global_transform.basis.z * thrust_power
	if Input.is_action_pressed("move_back") or Input.is_action_pressed("brake"):
		thrust += global_transform.basis.z * thrust_power * 0.5
	if Input.is_action_pressed("move_up"):
		thrust += global_transform.basis.y * thrust_power * 0.3
	if Input.is_action_pressed("move_down"):
		thrust += -global_transform.basis.y * thrust_power * 0.3

	# Exhaust particles
	if exhaust_particles:
		exhaust_particles.emitting = thrust.length() > 1.0

	# Apply gravitational acceleration
	var grav_accel = black_hole.get_grav_acceleration(global_position)

	# Frame dragging (Kerr effect) - slight orbital push
	var frame_drag = black_hole.get_frame_dragging(global_position)
	var tangential = global_position.cross(Vector3.UP).normalized()
	var drag_force = tangential * frame_drag * 1e8

	velocity += (thrust + grav_accel + drag_force) * delta

	# Speed of light cap (99% c)
	var speed_ms = velocity.length() * SCALE
	if speed_ms > C * 0.99:
		velocity = velocity.normalized() * (C * 0.99 / SCALE)

	# Move ship
	global_position += velocity * delta

	# Time dilation
	var dilation = black_hole.get_time_dilation(global_position, velocity)
	ship_time += delta * dilation
	universal_time += delta

	# Tidal force - spaghettification
	var ship_length_m = 50.0  # 50 meter ship
	var tidal_accel = black_hole.get_tidal_acceleration(global_position, ship_length_m)
	var tidal_g = tidal_accel / 9.81

	# Deform mesh with tidal forces
	var r = (black_hole.global_position - global_position).length()
	if tidal_g > 10.0 and ship_mesh:
		var stretch = 1.0 + clamp((tidal_g - 10.0) * 0.001, 0.0, 5.0)
		var squish = 1.0 / sqrt(stretch)
		ship_mesh.scale = Vector3(squish, squish, stretch)
	else:
		if ship_mesh:
			ship_mesh.scale = Vector3.ONE

	# Structural damage
	if tidal_g > 100.0:
		structural_integrity -= (tidal_g - 100.0) * 0.01 * delta
		structural_integrity = max(0.0, structural_integrity)

	# Death inside event horizon
	if r < BH_RS_GAME:
		structural_integrity = 0.0

func get_speed_fraction() -> float:
	return velocity.length() * SCALE / C

func get_speed_kms() -> float:
	return velocity.length() * SCALE / 1000.0
