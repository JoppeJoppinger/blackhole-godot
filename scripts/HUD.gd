extends CanvasLayer

const G: float = 6.674e-11
const C: float = 299792458.0
const BH_MASS: float = 10.0 * 1.989e30
const SCHWARZSCHILD_RADIUS: float = 2.0 * 6.674e-11 * 10.0 * 1.989e30 / (299792458.0 * 299792458.0)
const SCALE: float = 1e6
const BH_RS_GAME: float = SCHWARZSCHILD_RADIUS / SCALE

var spaceship: Node3D = null
var black_hole: Node3D = null
var pulse_time: float = 0.0

@onready var lbl_distance: Label = $Panel/VBox/Distance
@onready var lbl_speed: Label = $Panel/VBox/Speed
@onready var lbl_escape: Label = $Panel/VBox/EscapeVelocity
@onready var lbl_can_escape: Label = $Panel/VBox/CanEscape
@onready var lbl_ship_time: Label = $Panel/VBox/ShipTime
@onready var lbl_univ_time: Label = $Panel/VBox/UniversalTime
@onready var lbl_integrity: Label = $Panel/VBox/Integrity
@onready var lbl_tidal: Label = $Panel/VBox/TidalStress
@onready var lbl_grav_accel: Label = $Panel/VBox/GravAccel
@onready var lbl_redshift: Label = $Panel/VBox/Redshift
@onready var lbl_warning: Label = $Warning
@onready var lbl_event_horizon: Label = $EventHorizonCountdown
@onready var integrity_bar: ProgressBar = $Panel/VBox/IntegrityBar

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hud"):
		$Panel.visible = not $Panel.visible

func _process(delta: float) -> void:
	if spaceship == null or black_hole == null:
		return

	pulse_time += delta

	var ship_pos = spaceship.global_position
	var r_game = (black_hole.global_position - ship_pos).length()
	var r_meters = r_game * SCALE
	var rs = SCHWARZSCHILD_RADIUS
	var dist_to_horizon_m = max(0.0, r_meters - rs)
	var dist_to_horizon_rs = max(0.0, r_game / BH_RS_GAME - 1.0)

	# Distance
	lbl_distance.text = "Distance to EH: %.1f km (%.2f rs)" % [dist_to_horizon_m / 1000.0, dist_to_horizon_rs + 1.0]

	# Speed
	var speed_kms = spaceship.get_speed_kms()
	var speed_frac = spaceship.get_speed_fraction()
	lbl_speed.text = "Speed: %.1f km/s (%.4f c)" % [speed_kms, speed_frac]

	# Escape velocity
	var v_esc = black_hole.get_escape_velocity(ship_pos)
	lbl_escape.text = "Escape velocity: %.0f km/s" % [v_esc / 1000.0]

	# Can escape?
	var current_speed_ms = spaceship.get_speed_kms() * 1000.0
	if r_meters <= rs:
		lbl_can_escape.text = "✗ BEYOND HORIZON"
		lbl_can_escape.add_theme_color_override("font_color", Color(1, 0, 0))
	elif current_speed_ms >= v_esc:
		lbl_can_escape.text = "✓ CAN ESCAPE"
		lbl_can_escape.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		lbl_can_escape.text = "✗ CANNOT ESCAPE"
		lbl_can_escape.add_theme_color_override("font_color", Color(1, 0.3, 0))

	# Time clocks
	var st = spaceship.ship_time
	var ut = spaceship.universal_time
	lbl_ship_time.text = "Ship time: %02d:%02d:%06.3f" % [int(st / 3600), int(fmod(st, 3600) / 60), fmod(st, 60)]
	lbl_univ_time.text = "Univ time: %02d:%02d:%06.3f" % [int(ut / 3600), int(fmod(ut, 3600) / 60), fmod(ut, 60)]

	# Structural integrity
	var integrity = spaceship.structural_integrity
	lbl_integrity.text = "Integrity: %.1f%%" % integrity
	if integrity_bar:
		integrity_bar.value = integrity
	if integrity < 25.0:
		lbl_integrity.add_theme_color_override("font_color", Color(1, 0, 0))
	elif integrity < 60.0:
		lbl_integrity.add_theme_color_override("font_color", Color(1, 0.7, 0))
	else:
		lbl_integrity.add_theme_color_override("font_color", Color(0, 1, 0.5))

	# Tidal stress
	var tidal = black_hole.get_tidal_acceleration(ship_pos, 50.0)
	lbl_tidal.text = "Tidal stress: %.2f g/m" % [tidal / 9.81]

	# Gravitational acceleration
	var grav_accel = black_hole.get_grav_acceleration(ship_pos).length()
	lbl_grav_accel.text = "Grav accel: %.4f g" % [grav_accel * SCALE / 9.81]

	# Redshift
	var z = black_hole.get_redshift_z(ship_pos)
	lbl_redshift.text = "Redshift z: %.4f" % z

	# Photon sphere warning
	var r_ps = 1.5 * BH_RS_GAME
	if r_game < r_ps:
		lbl_warning.visible = true
		var pulse = (sin(pulse_time * 4.0) + 1.0) * 0.5
		lbl_warning.modulate = Color(1, 0.2 + pulse * 0.8, 0, 0.5 + pulse * 0.5)
	else:
		lbl_warning.visible = false

	# Event horizon countdown
	if dist_to_horizon_m < 100000.0:  # Within 100,000 km
		lbl_event_horizon.visible = true
		lbl_event_horizon.text = "EVENT HORIZON IN %.1f km" % [dist_to_horizon_m / 1000.0]
	else:
		lbl_event_horizon.visible = false
