@tool
class_name PlanetMesh3D extends MeshInstance3D

const VERTEX_PAIRS: Array[int] = [0, 1, 0, 2, 0, 3, 0, 4, 1, 2, 2, 3, 3, 4, 4, 1, 5, 1, 5, 2, 5, 3, 5, 4]
const EDGE_TRIPLETS: Array[int] = [0, 1, 4, 1, 2, 5, 2, 3, 6, 3, 0, 7, 8, 9, 4, 9, 10, 5, 10, 11, 6, 11, 8, 7]
const BASE_VERTICES: Array[Vector3] = [Vector3.UP, Vector3.LEFT, Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.DOWN]

var num_divisions: int = 1
var vertices: PackedVector3Array = []
var vertices_with_height: PackedVector3Array = []
var triangles: PackedInt32Array = []
var edges: Array[Edge] = []


func set_mesh_height(planet_data: PlanetData):
	vertices_with_height.clear()
	for v in range(0, vertices.size()):
		vertices_with_height.append( planet_data.get_height_at_point(vertices[v]))
		
func recalculate_normals() -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices_with_height.size())
	normals.fill(Vector3(0.0, 0.0, 0.0))
	for i in range(0, triangles.size(), 3):
		var vertex_0: Vector3 = vertices_with_height[triangles[i]]
		var vertex_1: Vector3 = vertices_with_height[triangles[i + 1]]
		var vertex_2: Vector3 = vertices_with_height[triangles[i + 2]]
		var normal: Vector3 = (vertex_1 - vertex_0).cross(vertex_2 - vertex_0).normalized()
		normals[triangles[i]] = (normals[triangles[i]] + normal).normalized()
		normals[triangles[i + 2]] = (normals[triangles[i + 1]] + normal).normalized()
		normals[triangles[i + 2]] = (normals[triangles[i + 2]] + normal).normalized()
	return normals
	
func update_mesh(planet_data: PlanetData):
	print("update mesh")
	var material: Material = get_active_material(0)
		
	var _mesh = ArrayMesh.new()
	var _mesh_arrays: Array = []
	_mesh_arrays.resize(Mesh.ARRAY_MAX)
	_mesh_arrays.fill(null)
	_mesh_arrays[Mesh.ARRAY_VERTEX] = vertices_with_height
	_mesh_arrays[Mesh.ARRAY_INDEX] = triangles
	_mesh_arrays[Mesh.ARRAY_NORMAL] = recalculate_normals()
	
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _mesh_arrays)
	self.mesh = _mesh
	material.set_shader_parameter("min_height", planet_data.min_height)
	material.set_shader_parameter("max_height", planet_data.max_height)
	material.set_shader_parameter("height_color", planet_data.planet_color)
	set_surface_override_material(0, material)
	
	
func regenerate_mesh(planet_data: PlanetData):
	num_divisions = max(0, planet_data.resolution)
	vertices.clear()
	triangles.clear()
	edges.clear()
	

	generate_vertices()
	generate_faces()
	
	set_mesh_height(planet_data)
	call_deferred("update_mesh", planet_data)

func generate_vertices():
	# verts per face = (n^2 - n) / 2
	for v in range(0, BASE_VERTICES.size()):
		vertices.append(BASE_VERTICES[v])
	
	# Create 12 Edges and add num_divisions times vertices along them
	edges.resize(12)
	
	for i in range(0, VERTEX_PAIRS.size(), 2):
		var start_vertex: Vector3 = vertices[VERTEX_PAIRS[i]]
		var end_vertex: Vector3 = vertices[VERTEX_PAIRS[i + 1]]
		
		var edge_vertex_indices: Array[int] = []
		edge_vertex_indices.resize(num_divisions + 2)
		# First Vertex = start-vertex from VERTEX_PAIRS
		edge_vertex_indices[0] = VERTEX_PAIRS[i]
		
		for division_index in range(0, num_divisions):
			# interpolate vertices between start_vertex and end_vertex
			var t: float = (division_index + 1.0) / (num_divisions + 1.0)
			# add the last + 1 index to index-list
			edge_vertex_indices[division_index + 1] = vertices.size() 
			# calculate a spherical fraction vertex to vertex-list
			vertices.append(start_vertex.slerp(end_vertex, t))
	
		# last vertex = end-vertex from VERTEX_PAIRS
		edge_vertex_indices[num_divisions + 1] = VERTEX_PAIRS[i + 1]
		var edge_index: int = i / 2
		edges[edge_index] = Edge.new(edge_vertex_indices)



func generate_faces():
	for i in range(0, EDGE_TRIPLETS.size(), 3):
		var face_index: int = i / 3
		var reverse: bool = face_index >= 4
		create_face(edges[EDGE_TRIPLETS[i]], edges[EDGE_TRIPLETS[i + 1]], edges[EDGE_TRIPLETS[i + 2]], reverse)
		
	
	
func create_face(side_a: Edge, side_b: Edge, bottom: Edge, reverse: bool):
	var num_points_in_egde: int = side_a.vertex_indices.size()
	var vertex_map: Array[int] = []
	#vertex_map.resize(num_verts_per_face)
	# triangles top
	vertex_map.append(side_a.vertex_indices[0])
	
	for i in range(1, num_points_in_egde - 1):
		# Vertex side A
		vertex_map.append(side_a.vertex_indices[i])
		
		# add vertices between side A and B
		var side_a_vertex: Vector3 = vertices[side_a.vertex_indices[i]]
		var side_b_vertex: Vector3 = vertices[side_b.vertex_indices[i]]
		
		var num_inner_points: int = i - 1
		for j in range(0, num_inner_points):
			var t: float = (j + 1.0) / (num_inner_points + 1.0)
			vertex_map.append(vertices.size())
			vertices.append(side_a_vertex.slerp(side_b_vertex, t))
		
		# Vertex side B
		vertex_map.append(side_b.vertex_indices[i])
		
	# add bottom side vertices
	for i in range(0, num_points_in_egde):
		vertex_map.append(bottom.vertex_indices[i])

	# Triangulate
	var num_rows: int = num_divisions + 1
	for row in range(0, num_rows):
		# vertices down left edge follow quadratic sequence: 0, 1, 3, 6, 10, 15 ...
		# the nth term can be calculated with: (n^2 -n ) / 2
		var top_vertex: int = ((row + 1) * (row + 1) - row - 1) / 2
		var bottom_vertex: int = ((row + 2) * (row + 2) - row - 2) / 2
		
		var num_triangles_in_row: int = 1 + 2 * row
		for column in range(0, num_triangles_in_row):
			var v0: int
			var v1: int	
			var v2: int
			
			if column % 2 == 0:
				v0 = top_vertex
				v1 = bottom_vertex + 1
				v2 = bottom_vertex
				top_vertex += 1
				bottom_vertex += 1
			else:
				v0 = top_vertex
				v1 = bottom_vertex
				v2 = top_vertex - 1
				
			triangles.append(vertex_map[v0])
			triangles.append(vertex_map[v2 if reverse else v1])
			triangles.append(vertex_map[v1 if reverse else v2])

class Edge:
	var vertex_indices: Array[int]
	func _init(vert_indices: Array[int]):
		self.vertex_indices = vert_indices
		
