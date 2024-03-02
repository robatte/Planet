@tool
extends Resource

class_name PlanetData

signal mesh_invalid
signal height_invalid

var min_height: float = 99999.0
var max_height: float = 0.0

@export_range(0.1, 1000, 0.1, "or_greater", "exp") 
var radius = 1.0:
	set(val):
		radius = val
		height_invalid.emit()
	
@export_range(0, 100, 1, "or_greater", "exp") 
var resolution: int = 1:
	set(val):
		resolution = val
		mesh_invalid.emit()

@export
var biomes: Array[PlanetBiome]:
	set(val):
		biomes = val
		emit_changed()
		for biome in biomes:
			if biome != null and not biome.is_connected("change", Callable(self, "on_planet_height_changed")):
				biome.connect("change", Callable(self, "on_planet_height_changed"))

@export 
var planet_noise: Array[PlanetNoise]:
	set(val):
		planet_noise = val
		emit_changed()
		for noise in planet_noise:
			if noise != null and not noise.is_connected("changed", Callable(self, "on_planet_height_changed")):
				noise.connect("changed", Callable(self, "on_planet_height_changed"))

func on_planet_height_changed():
	height_invalid.emit()
	
func get_height_at_point(point_on_sphere: Vector3) -> Vector3:
	var elevation: float = 0.0 
	var base_elevation = 0.0
	if planet_noise.size() > 1:
		base_elevation = planet_noise[0].noise_map.get_noise_3dv(point_on_sphere * 100.0)
		base_elevation = (base_elevation + 1) / 2.0 * planet_noise[0].amplitude
		base_elevation = max(0.0, base_elevation - planet_noise[0].min_height)
	for n in planet_noise:
		var mask: float = base_elevation if n.use_first_layer_as_mask else 1.0
		var level_elevation = n.noise_map.get_noise_3dv(point_on_sphere * 100.0)
		level_elevation = (level_elevation + 1) / 2.0 * n.amplitude
		level_elevation = max(0.0, level_elevation - n.min_height) * mask
		elevation += level_elevation
	
	var point = point_on_sphere * radius * (elevation + 1.0)
	var length = point.length()
	if length > max_height:
		max_height = length
	if length < min_height:
		min_height = length
	return point

