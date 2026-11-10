extends RefCounted
## Reuse approved machinery and entry artwork at the campaign's collision footprints.
const Level = preload("res://scripts/first_call.gd")
const MANIFEST := "res://assets/world/three-screen-trial/manifest.json"
var parts: Dictionary = {}
var support: Dictionary = {}
var pit_water := preload("res://scripts/pit_water_art.gd").new()

func prepare(host: Node, yield_frame := Callable()) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for item: Dictionary in manifest.parts: parts[item.id] = item
	await host.load_trial_textures(manifest,yield_frame)
	support = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/three-screen-trial/campaign-support-slices-v1.json"))
	support.path = support.source
	await host.load_trial_textures(support,yield_frame)
	await host.campaign.level.platforms.prepare(host,yield_frame)
	await pit_water.prepare(host,yield_frame)

func draw_support(host: Node2D, rect: Rect2) -> void:
	var caps: Dictionary = support.destination_caps
	var widths := [float(caps.left),rect.size.x-caps.left-caps.right,float(caps.right)]
	var heights := [float(caps.top),rect.size.y-caps.top-caps.bottom,float(caps.bottom)]
	assert(widths[1] >= 0 and heights[1] >= 0,"Campaign support cannot fit intact brace caps")
	for patch: Dictionary in support.patches:
		var column: int = patch.column
		var row: int = patch.row
		var origin := rect.position
		for index in range(column): origin.x += widths[index]
		for index in range(row): origin.y += heights[index]
		var source: Rect2 = host.region(patch.source_rect)
		var native := source.size*Vector2(250.0/604.0,120.0/349.0)
		var y := 0.0
		while y < heights[row]-0.0001:
			var height := minf(native.y,heights[row]-y)
			var x := 0.0
			while x < widths[column]-0.0001:
				var width := minf(native.x,widths[column]-x)
				var crop := Rect2(source.position,source.size*Vector2(width/native.x,height/native.y))
				# Shaft cuts keep the lower material that joins the separate foot cap.
				if row == 1: crop.position.y = source.end.y-crop.size.y
				var asset: Dictionary = support.duplicate()
				asset.source_rect = [crop.position.x,crop.position.y,crop.size.x,crop.size.y]
				host.draw_asset(asset,Rect2(origin+Vector2(x,y),Vector2(width,height)),Color(0.65,0.65,0.65))
				x += width
			y += height

func draw_part(host: Node2D, id: String, destination: Rect2) -> void:
	host.draw_asset(parts[id],destination)

func draw_deck(host: Node2D, rect: Rect2) -> void:
	# Preserve both complete brace/post/foot caps; only straight middle pieces change length.
	draw_support(host,Rect2(rect.position,Vector2(rect.size.x,440-rect.position.y)))
	var offset := 0.0
	while offset < rect.size.x:
		var width := minf(250,rect.size.x-offset)
		var deck: Dictionary = parts["access-deck"].duplicate(true)
		deck.source_rect[2] *= width/250.0
		host.draw_asset(deck,Rect2(rect.position+Vector2(offset,0),Vector2(width,16)),
			Color(1.15,1.15,1.15))
		offset += width

func draw(host: Node2D) -> void:
	if parts.is_empty(): return
	var view := Rect2(host.camera_x-32,0,1024,540)
	for floor_rect: Rect2 in host.campaign.level.floor_solids():
		var x := floor_rect.position.x
		while x < floor_rect.end.x:
			var width := minf(480,floor_rect.end.x-x)
			var destination := Rect2(x,440,width,100)
			if destination.intersects(view):
				var fascia: Dictionary = host.part("floor-fascia").duplicate(true)
				fascia.source_rect[2] *= width/480.0
				host.draw_asset(fascia,destination)
			x += width
	for section: Dictionary in host.campaign.contract.sections:
		for item: Dictionary in section.get("geometry",[]):
			var rect: Rect2 = host.region(item.rect)
			if not rect.grow(120).intersects(view): continue
			match item.kind:
				"solid":
					# Includes the native tall asset and existing right-edge crop for narrow stairs.
					if host.campaign.level.platforms.placements.has(item.id):
						host.campaign.level.platforms.draw(host,item.id)
					else: Level.draw_prop(host,rect)
				"one_way": draw_deck(host,rect)
				"pit":
					draw_part(host,"pit-depth",rect)
					draw_part(host,"pit-left-rim",Rect2(rect.position-Vector2(32,0),Vector2(32,32)))
					draw_part(host,"pit-right-rim",Rect2(rect.end.x,rect.position.y,32,32))
				"background_opening": draw_part(host,"pipe-back",rect)
				"ceiling_rail":
					host.devil_spider_art.draw_support(host,{
						"home":Vector2(item.socket[0],item.socket[1]),
						"bounds":Vector2(item.crawl_range[0],item.crawl_range[1])})
	# Run-owned supports persist after their occupant dies; authored devil rail stays separate.
	for fixture: Dictionary in host.campaign.variant_supports:
		var support_bounds := Rect2(fixture.bounds.x - 60, fixture.home.y - 17,
			fixture.bounds.y - fixture.bounds.x + 120, 18)
		if support_bounds.intersects(view): host.devil_spider_art.draw_support(host, fixture)
	# Concealed entry doors belong to actual occupants, never future encounter locations.
	draw_fixtures(host,false)

func draw_fixtures(host: Node2D, front: bool) -> void:
	if not front:
		for spec: Dictionary in host.campaign.specs:
			if spec.get("entry",{}).get("mode","") == "ceiling": host.draw_ceiling_entry_support(spec.feet)
	for actor: Dictionary in host.actors:
		host.entry_door_art.draw(host,actor,host.entry_door_open_fraction(actor),front)

func draw_opening_lips(host: Node2D) -> void:
	# Call after clipped background arrivals, before ordinary actors crossing the opening.
	for section: Dictionary in host.campaign.contract.sections:
		for item: Dictionary in section.get("geometry",[]):
			if item.kind != "background_opening": continue
			var rect: Rect2 = host.region(item.rect)
			draw_part(host,"pipe-front-lip",Rect2(rect.position+Vector2(0,rect.size.y*0.5),
				Vector2(rect.size.x,rect.size.y*0.5)))

func draw_pit_cutaways(host: Node2D) -> void:
	# The old continuous wastewater strip must not paint a traversable surface across new pits.
	for opening: Vector2 in host.campaign.level.pits:
		draw_part(host,"pit-depth",Rect2(opening.x,440,opening.y-opening.x,100))
		draw_part(host,"pit-left-rim",Rect2(opening.x-32,440,32,32))
		draw_part(host,"pit-right-rim",Rect2(opening.y,440,32,32))
		pit_water.draw(host,opening)
