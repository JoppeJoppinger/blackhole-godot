extends Node3D

func _ready() -> void:
	_spawn_starfield()
	_spawn_planets()
	_spawn_asteroids()
	_spawn_sun()

func _spawn_starfield() -> void:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "StarfieldMesh"
	var sphere = SphereMesh.new()
	sphere.radius = 800.0
	sphere.height = 1600.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_inst.mesh = sphere
	# Load starfield shader
	var mat = ShaderMaterial.new()
	var shader = load("res://shaders/starfield.gdshader")
	mat.shader = shader
	mesh_inst.set_surface_override_material(0, mat)
	# Flip normals inward
	mesh_inst.scale = Vector3(-1, -1, -1)
	add_child(mesh_inst)

func _spawn_sun() -> void:
	var light = OmniLight3D.new()
	light.position = Vector3(300, 80, 300)
	light.light_energy = 3.0
	light.light_color = Color(1.0, 0.95, 0.8)
	light.omni_range = 1000.0
	add_child(light)

func _spawn_planets() -> void:
	var planets = [
		{"pos": Vector3(120, 5, -80),   "radius": 8.0,  "color": Color(0.6, 0.4, 0.2)},  # rocky
		{"pos": Vector3(-150, -10, 60), "radius": 14.0, "color": Color(0.8, 0.6, 0.3)},  # gas giant
		{"pos": Vector3(80, 20, 180),   "radius": 6.0,  "color": Color(0.5, 0.7, 0.9)},  # ice
		{"pos": Vector3(-60, -5, -200), "radius": 5.0,  "color": Color(0.7, 0.2, 0.1)},  # lava
	]
	for p in planets:
		var mi = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = p["radius"]
		sm.height = p["radius"] * 2.0
		sm.radial_segments = 32
		sm.rings = 16
		mi.mesh = sm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = p["color"]
		mat.roughness = 0.8
		mat.metallic = 0.1
		mi.set_surface_override_material(0, mat)
		mi.position = p["pos"]
		add_child(mi)

func _spawn_asteroids() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in 50:
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(60.0, 100.0)
		var mi = MeshInstance3D.new()
		var sm = SphereMesh.new()
		var r = rng.randf_range(0.3, 1.5)
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 6
		sm.rings = 4
		mi.mesh = sm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(rng.randf_range(0.3, 0.5), rng.randf_range(0.25, 0.4), rng.randf_range(0.2, 0.35))
		mat.roughness = 0.95
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(cos(angle) * dist, rng.randf_range(-4.0, 4.0), sin(angle) * dist)
		mi.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		mi.scale = Vector3(rng.randf_range(0.7, 1.4), rng.randf_range(0.5, 1.2), rng.randf_range(0.7, 1.3))
		add_child(mi)
