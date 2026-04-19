extends Node3D

var black_hole: Node3D
var spaceship: Node3D
var post_process_rect: ColorRect

func _ready() -> void:
	black_hole = $BlackHole
	spaceship = $Spaceship
	post_process_rect = $PostProcess/LensRect

	# Connect spaceship to black hole
	spaceship.black_hole = black_hole

	# Connect HUD
	var hud = $HUD
	hud.spaceship = spaceship
	hud.black_hole = black_hole

func _process(_delta: float) -> void:
	# Update gravitational lens shader with BH screen position
	if post_process_rect and spaceship:
		var cam: Camera3D
		if spaceship.is_cockpit_camera:
			cam = spaceship.get_node("CockpitCamera")
		else:
			cam = spaceship.get_node("ChaseCamera")

		if cam and cam.is_inside_tree():
			var bh_world_pos = black_hole.global_position
			var screen_pos = cam.unproject_position(bh_world_pos)
			var viewport_size = get_viewport().get_visible_rect().size
			var uv_pos = screen_pos / viewport_size
			var mat = post_process_rect.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("bh_screen_pos", uv_pos)

		# Update starfield shader with ship velocity
		var starfield_mesh = $SpaceEnvironment/StarfieldMesh
		if starfield_mesh:
			var vel = spaceship.velocity
			var speed_frac = spaceship.get_speed_fraction()
			var vel_dir = vel.normalized() if vel.length() > 0.001 else Vector3(0, 0, -1)
			var mat2 = starfield_mesh.get_surface_override_material(0) as ShaderMaterial
			if mat2:
				mat2.set_shader_parameter("ship_speed_fraction", speed_frac)
				mat2.set_shader_parameter("ship_velocity_dir", vel_dir)
