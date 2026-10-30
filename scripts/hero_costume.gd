extends RefCounted
## Costume identity is independent of difficulty-specific dialogue and gameplay rules.
static func mode(value: Variant) -> String:
	# Legacy callers and diagnostic fixtures still pass the former Hard boolean.
	if value is bool: return "hard" if value else "normal"
	var result := str(value)
	assert(result in ["easy", "normal", "hard"], "Unknown hero costume: " + result)
	return result
