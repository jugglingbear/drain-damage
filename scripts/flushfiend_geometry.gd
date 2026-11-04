extends RefCounted
## Feet stay stable while legacy top-left storage remains compatible with spawns and corpses.
const SCALE := 1.2
const LEGACY_FEET := Vector2(19,36)
const BODY_SIZE := Vector2(38,36)*SCALE
const BODY_OFFSET := Vector2(-BODY_SIZE.x*0.5,-BODY_SIZE.y)
const RENDER_HEIGHT := 43.0*SCALE

static func feet(position: Vector2) -> Vector2:
	return position+LEGACY_FEET

static func body_at_feet(anchor: Vector2) -> Rect2:
	return Rect2(anchor+BODY_OFFSET,BODY_SIZE)

static func body(position: Vector2) -> Rect2:
	return body_at_feet(feet(position))

static func projectile_rect(anchor: Vector2) -> Rect2:
	return Rect2(anchor+Vector2(-BODY_SIZE.x*0.5,-RENDER_HEIGHT),Vector2(BODY_SIZE.x,RENDER_HEIGHT))

static func legacy_from_body(position: Vector2) -> Vector2:
	return position-BODY_OFFSET-LEGACY_FEET
