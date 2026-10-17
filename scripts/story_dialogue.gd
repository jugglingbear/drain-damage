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
	{"who": "tony", "emotion": "neutral", "text": "I’m at the exit. Sean, you still on the radio?", "radio": false},
	{"who": "sean", "emotion": "worried", "text": "Yeah. I was trying not to distract you. Are you coming out?", "radio": true},
	{"who": "tony", "emotion": "happy", "text": "On my way, buddy. Thanks for staying with me.", "radio": false},
	{"who": "bj", "emotion": "neutral", "text": "Before you leave, I have another service call.", "radio": false},
	{"who": "tony", "emotion": "skeptical", "text": "Does the customer know what’s happening down here?", "radio": false},
	{"who": "bj", "emotion": "neutral", "text": "The customer reported a toilet moving across the bathroom.", "radio": false},
	{"who": "sean", "emotion": "worried", "text": "Can we tell them to shut the door?", "radio": true},
	{"who": "tony", "emotion": "neutral", "text": "Good thinking. BJ, tell them to stay out. We’ll call when we’re on our way.", "radio": false},
	{"who": "bj", "emotion": "neutral", "text": "I’ll mark you as available.", "radio": false},
]

const COMPLETION_SEAN: Array[Dictionary] = [
	{"who": "sean", "emotion": "worried", "text": "Tony, I found the exit. Please tell me you’re outside.", "radio": false},
	{"who": "tony", "emotion": "happy", "text": "I’m here, buddy. Come on out. We’ll check you over.", "radio": true},
	{"who": "sean", "emotion": "neutral", "text": "I thought plumbing would involve fewer teeth.", "radio": false},
	{"who": "tony", "emotion": "neutral", "text": "It usually does. You did well to get through that.", "radio": true},
	{"who": "bj", "emotion": "neutral", "text": "There’s another customer waiting. Their toilet has moved into the hallway.", "radio": false},
	{"who": "sean", "emotion": "surprised", "text": "Can’t we wait for it to leave the building?", "radio": false},
	{"who": "tony", "emotion": "neutral", "text": "Someone could get hurt. BJ, tell them to keep clear. Give us a minute.", "radio": true},
	{"who": "sean", "emotion": "worried", "text": "You’ll stay on the radio?", "radio": false},
	{"who": "tony", "emotion": "happy", "text": "Of course I will.", "radio": true},
]

static func completion(employee_id: String) -> Array[Dictionary]:
	return COMPLETION_TONY if employee_id == "tony" else COMPLETION_SEAN
