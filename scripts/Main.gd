extends Node3D

var black_hole: Node3D
var spaceship: Node3D
var post_process_rect: ColorRect
var sound_manager: Node

func _ready() -> void:
	black_hole = $BlackHole
	spaceship = $Spaceship
	post_process_rect = $PostProcess/LensRect
	sound_manager = $SoundManager

	# Wire up
	spaceship.black_hole = black_hole
	spaceship.sound_manager = sound_manager

	var hud = $HUD
	hud.spaceship = spaceship
	hud.black_hole = black_hole

func _process(_delta: float) -> void:
	if post_process_rect == null or spaceship == null:
		return

	# Pick active camera
	var cam: Camera3D
	if spaceship.is_cockpit_camera and spaceship.has_node("CockpitNode"):
		cam = spaceship.get_node("CockpitNode/CockpitCamera")
	else:
		cam = spaceship.get_node("ChaseCamera")

	if cam and cam.is_inside_tree():
		var bh_world_pos = black_hole.global_position
		var screen_pos = cam.unproject_position(bh_world_pos)
		var viewport_size = get_viewport().get_visible_rect().size
		var uv_pos = screen_pos / viewport_size

		# How big does the BH appear on screen?
		var bh_edge_world = bh_world_pos + cam.global_transform.basis.x * (black_hole.BH_RS_GAME if black_hole.get("BH_RS_GAME") != null else 0.03)
		var edge_screen = cam.unproject_position(bh_edge_world)
		var bh_screen_radius = (edge_screen - screen_pos).length() / viewport_size.x

		var mat = post_process_rect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("bh_screen_pos", uv_pos)
			mat.set_shader_parameter("bh_radius_screen", bh_screen_radius)
			mat.set_shader_parameter("photon_sphere_screen", bh_screen_radius * 1.5)

			# Lensing intensifies as you approach
			var r = (black_hole.global_position - spaceship.global_position).length()
			var rs = 0.02955  # BH_RS_GAME approx
			var lens_str = clamp(rs * 3.0 / max(r, rs * 0.5), 0.1, 5.0)
			mat.set_shader_parameter("lens_strength", lens_str)

	# Update starfield
	var starfield_mesh = get_node_or_null("SpaceEnvironment/StarfieldMesh")
	if starfield_mesh:
		var vel = spaceship.velocity
		var speed_frac = spaceship.get_speed_fraction()
		var vel_dir = vel.normalized() if vel.length() > 0.001 else Vector3(0, 0, -1)
		var mat2 = starfield_mesh.get_surface_override_material(0) as ShaderMaterial
		if mat2:
			mat2.set_shader_parameter("ship_speed_fraction", speed_frac)
			mat2.set_shader_parameter("ship_velocity_dir", vel_dir)

	# Keep starfield centered on ship
	if starfield_mesh:
		starfield_mesh.global_position = spaceship.global_position
