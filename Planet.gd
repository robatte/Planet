@tool
extends Node3D

@export var planet_data: PlanetData

var planet_mesh: PlanetMesh3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	planet_data.mesh_invalid.connect(on_mesh_invalid)
	planet_data.height_invalid.connect(on_height_invalid)
	$PlanetMesh3D.regenerate_mesh(planet_data)
	print("min: " + str(planet_data.min_height) + " max: " + str(planet_data.max_height))
	
func on_mesh_invalid():
	$PlanetMesh3D.regenerate_mesh(planet_data)
	
func on_height_invalid():
	planet_data.min_height = 99999.0
	planet_data.max_height = 0.0
	$PlanetMesh3D.set_mesh_height(planet_data)
	$PlanetMesh3D.update_mesh(planet_data)
