extends "res://tests/ride_wave_two_course.gd"
## Whole-course timing regression for both heroes, modes, mirrors and supported tick rates.
func checks() -> void:
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for hz in [30,60,120]:
				for seed_value in [0,2]:
					for offset in [-0.05,0.05]:
						run_extension(hero,mode,seed_value,hz,300,offset)
	print(JSON.stringify({"routes":routes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
