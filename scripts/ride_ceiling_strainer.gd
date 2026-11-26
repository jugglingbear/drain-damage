extends RefCounted
## The basket follows the fixed footprint through the channel floor.
const START_HEIGHT := 600.0
const FALL_SECONDS := 1.65

static func height(age: float, impact: float) -> float:
	var elapsed := maxf(0,age-impact+FALL_SECONDS)
	return START_HEIGHT*(1.0-pow(elapsed/FALL_SECONDS,2))

static func assembly(manifest: Dictionary, point: Vector2, depth: float, age: float) -> Dictionary:
	var elevation := height(age,float(manifest.strainer_timeline.impact))
	if elevation >= START_HEIGHT or elevation < -650:
		return {"parts":[]}
	var bottom := point+Vector2(0,depth*0.5-elevation)
	return {"parts":[{"id":manifest.strainer_parts.basket,"transform":Transform2D(0,bottom),"alpha":1.0}]}
