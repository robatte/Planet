@tool
extends Resource
class_name PlanetNoise

signal height_invalid

@export_range(0, 1.0, 0.01, "or_greater") 
var min_height: float = 0.0:
	set(val):
		min_height = val
		emit_changed()
	
@export_range(0, 1.0, 0.01, "or_greater") 
var amplitude: float = 1.0:
	set(val):
		amplitude = val
		emit_changed()

@export
var use_first_layer_as_mask: bool = 0:
	set(val):
		use_first_layer_as_mask = val
		emit_changed()

@export 
var noise_map: FastNoiseLite:
	set(val):
		noise_map = val
		if noise_map != null and not noise_map.is_connected("changed", Callable(self, "on_noise_map_changed")):
			noise_map.connect("changed", Callable(self, "on_noise_map_changed"))

func on_noise_map_changed():
	emit_changed()
