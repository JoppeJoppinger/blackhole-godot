extends Node3D

# Physics constants
const G: float = 6.674e-11
const C: float = 299792458.0
const SOLAR_MASS: float = 1.989e30
const BH_MASS: float = 10.0 * 1.989e30
const SCHWARZSCHILD_RADIUS: float = 2.0 * 6.674e-11 * 10.0 * 1.989e30 / (299792458.0 * 299792458.0)
const SCALE: float = 1e6
const BH_RS_GAME: float = SCHWARZSCHILD_RADIUS / SCALE
const PHOTON_SPHERE_R: float = 1.5 * SCHWARZSCHILD_RADIUS / SCALE
const ISCO_R: float = 3.0 * SCHWARZSCHILD_RADIUS / SCALE
const SPIN_PARAM: float = 0.9

func get_grav_acceleration(world_pos: Vector3) -> Vector3:
	var r_vec = global_position - world_pos
	var r = r_vec.length()
	if r < BH_RS_GAME * 0.01:
		return Vector3.ZERO
	var a_mag = G * BH_MASS / (SCALE * SCALE * r * r)
	return r_vec.normalized() * a_mag

func get_time_dilation(world_pos: Vector3, velocity: Vector3) -> float:
	var r = (global_position - world_pos).length() * SCALE
	var rs = SCHWARZSCHILD_RADIUS
	if r <= rs:
		return 0.0
	var grav_factor = sqrt(1.0 - rs / r)
	var v = velocity.length() * SCALE
	var kinematic_factor = sqrt(max(0.0, 1.0 - (v * v) / (C * C)))
	return grav_factor * kinematic_factor

func get_tidal_acceleration(world_pos: Vector3, ship_length_m: float) -> float:
	var r = (global_position - world_pos).length() * SCALE
	return 2.0 * G * BH_MASS * ship_length_m / (r * r * r)

func get_escape_velocity(world_pos: Vector3) -> float:
	var r = (global_position - world_pos).length() * SCALE
	return sqrt(2.0 * G * BH_MASS / r)

func get_frame_dragging(world_pos: Vector3) -> float:
	var r = (global_position - world_pos).length() * SCALE
	var a = SPIN_PARAM * G * BH_MASS / (C * C)
	return 2.0 * G * BH_MASS * a / (C * C * r * r * r)

func get_redshift_z(world_pos: Vector3) -> float:
	var r = (global_position - world_pos).length() * SCALE
	var rs = SCHWARZSCHILD_RADIUS
	if r <= rs:
		return 999999.0
	return 1.0 / sqrt(1.0 - rs / r) - 1.0
