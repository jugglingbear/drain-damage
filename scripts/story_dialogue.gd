extends RefCounted
## Approved scenes are shared across routes; movement tutorials are deliberately absent.
const DEATH_LINES: Array[Dictionary] = [
	{"who": "bj", "emotion": "neutral", "text": "I’ll put you down as unavailable."},
	{"who": "bj", "emotion": "skeptical", "text": "Your replacement will be briefed on whatever that was."},
	{"who": "bj", "emotion": "worried", "text": "I had you scheduled until five."},
	{"who": "bj", "emotion": "neutral", "text": "Please clock out before decomposing."},
	{"who": "bj", "emotion": "happy", "text": "I’m beginning to understand the appeal of unpaid internships."},
	{"who": "bj", "emotion": "skeptical", "text": "You were specifically hired to reduce the number of things in that drain."},
	{"who": "bj", "emotion": "surprised", "text": "Oh. That was a load-bearing organ."},
	{"who": "bj", "emotion": "worried", "text": "That looked expensive. Let me check what you were carrying."},
	{"who": "bj", "emotion": "happy", "text": "Good news. Your performance review has been canceled."},
	{"who": "bj", "emotion": "worried", "text": "Nobody move. Some of those tools are still under warranty."},
	{"who": "bj", "emotion": "happy", "text": "You may be eligible for retraining, depending on what we recover."},
	{"who": "bj", "emotion": "skeptical", "text": "For the record, I said ‘clear the drain.’"},
]
static var last_death_line := -1

static func choose_death_line() -> Dictionary:
	var index := randi_range(0, DEATH_LINES.size() - 1)
	if last_death_line >= 0:
		index = randi_range(0, DEATH_LINES.size() - 2)
		if index >= last_death_line: index += 1
	last_death_line = index
	return DEATH_LINES[index]

const OPENING: Array[Dictionary] = [
	{"who": "bj", "emotion": "happy", "text": "Welcome. I’m Billy-Joe. I manage Mainframe Plumbing & Supply. You can call me BJ."},
	{"who": "tony", "emotion": "happy", "text": "Morning, BJ. I’m Tony, and this is Sean, my new apprentice. What have you got for us?"},
	{"who": "bj", "emotion": "neutral", "text": "Something in the basement is eating company property. I need you to stop it."},
	{"who": "sean", "emotion": "happy", "text": "I brought a wrench."},
	{"who": "tony", "emotion": "neutral", "text": "That’s a tire iron, buddy. We’ll get you sorted."},
	{"who": "tony", "emotion": "worried", "text": "BJ, is there anyone down there?"},
	{"who": "bj", "emotion": "happy", "text": "Not yet. Head on down."},
]

const COMPLETION_TONY: Array[Dictionary] = [
	{"who": "tony", "emotion": "neutral", "text": "It’s down. I’m still here.", "radio": false},
	{"who": "sean", "emotion": "worried", "text": "Are you hurt?", "radio": true},
	{"who": "tony", "emotion": "happy", "text": "I’ll check when I find a clean bit.", "radio": false},
	{"who": "sean", "emotion": "neutral", "text": "I’ll get the hose.", "radio": true},
]

const COMPLETION_SEAN: Array[Dictionary] = [
	{"who": "sean", "emotion": "surprised", "text": "Tony? I think I got it.", "radio": false},
	{"who": "tony", "emotion": "worried", "text": "Are you still in one piece?", "radio": true},
	{"who": "sean", "emotion": "neutral", "text": "Yes. None of it’s clean.", "radio": false},
	{"who": "tony", "emotion": "happy", "text": "We can work with that. You did well, buddy.", "radio": true},
]

static func completion(employee_id: String) -> Array[Dictionary]:
	return COMPLETION_TONY if employee_id == "tony" else COMPLETION_SEAN
