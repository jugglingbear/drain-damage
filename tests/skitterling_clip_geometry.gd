extends SceneTree
const Body = preload("res://scripts/skitterling_roach_body.gd")
var failures := 0
var pieces := 0
var samples := 0
func _initialize() -> void:
	for radius in [Vector2(115,105),Vector2(64,9),Vector2(50,44)]:
		var mouth := Vector2(480,258)
		for index in range(Body.COUNT):
			for tick in range(121):
				var clock := tick/120.0
				var sample := Body.pipe_sample(index,Vector2(300,400),
					{"mouth":mouth,"radius":radius,"mode":"launch","arrival":true,"progress":clock})
				if not sample.get("clip",false): continue
				var angle := Body.insect_angle(index,clock)
				var size := Body.insect_size(index)*float(sample.scale)
				var transform := Transform2D(Vector2.from_angle(angle)*size.x,
					Vector2.from_angle(angle).orthogonal()*size.y,sample.position)
				samples += 1
				var output := Body.clipped_insect(transform,mouth,radius)
				var rendered_area := 0.0
				for polygon in output:
					pieces += 1
					var area := absf((polygon[1]-polygon[0]).cross(polygon[2]-polygon[0]))/2
					rendered_area += area
					if polygon.size() != 3 or area <= 0: failures += 1
					for vertex in polygon:
						var uv := transform.affine_inverse()*vertex+Vector2(0.5,0.5)
						if not Rect2(-0.001,-0.001,1.002,1.002).has_point(uv): failures += 1
						if ((vertex-mouth)/radius).length_squared() > 1.001: failures += 1
				var quad := PackedVector2Array()
				for corner in [Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]:
					quad.append(transform*corner)
				var aperture := PackedVector2Array()
				for edge in range(48): aperture.append(mouth+Vector2.from_angle(edge*TAU/48)*radius)
				var expected_area := 0.0
				for polygon in Geometry2D.intersect_polygons(quad,aperture):
					for vertex in range(1,polygon.size()-1):
						expected_area += (polygon[vertex]-polygon[0]).cross(polygon[vertex+1]-polygon[0])/2
				if absf(rendered_area-absf(expected_area)) > 0.01: failures += 1
	print("Clip geometry: ",samples," samples, ",pieces," polygons, ",failures," invalid")
	quit(0 if failures == 0 else 1)
