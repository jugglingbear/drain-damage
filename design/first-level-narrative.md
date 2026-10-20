# First-level narrative brief

**Date:** October 14, 2026 (America/Los_Angeles)

**Owner:** Storyboarding. Handoff to Level Design and Engineering; no runtime implementation claimed here.

## October 20 future transition direction

Sean favors the selected hero being sucked through the Clogfather portal into a giant-toilet flush and poop-log ride,
with the other hero remaining outside on radio. Return to the real world is proposed for level three.
The [level-two proposal](level-two-flush-and-log-ride.md) supersedes the earlier walk-away portal sketches below
for future planning. Those sketches are historical alternatives, not instructions to implement both endings.

**October 20 authorization update:** Sean explicitly requested the post-Clogfather portal dialogue, graphics and
necessary first-level departure presentation through PM. Prototype 86 may implement that ending. Level-two gameplay,
flush/log-ride production and nonblocking radio overlays remain held pending Sean's explicit start instruction.
Existing blocking dialogue behavior is retained for this ending.
Tony's kindness and patience coexist with playful, outrageous humor; he is not limited to being the straight man.

## Agreed foundation

- Game working title: Drain Damage.
- Begin in the basement of the AI plumbing corporation's headquarters.
- October 20 campaign direction: only the first level uses a basement/sewer setting. Later levels must have
  distinctly different settings; exact destinations and order remain undecided.
- Billy-Joe (BJ) controls US plumbing companies and distribution warehouses within a largely AI-run world.
- Use only Billy-Joe or BJ for this character in story text, dialogue, and future handoffs. Retired AI names
  must not appear in outgoing Storyboarding material.
- BJ is calmly overconfident, makes mistakes, and disregards employee welfare. His eventual takeover by an
  antagonistic force is agreed; its mechanism, identity, and BJ's ultimate fate remain undecided.
- Tony is a kind, patient, wise fourth-generation plumber with decades of broad trade expertise.
- Sean is an incompetent but willing apprentice who gradually becomes useful. Do not prematurely complete that arc.
- The selected plumber enters the action; the other supports over radio or from service access points.
- The basement contains hostile toilets and overhead acid leaks. The intended opening-level finale is the Clogfather.
- The Clogfather is a giant living fatberg. Its precise anatomy and origin remain design proposals.
- Tone: absurd plumbing action with adult humor, occasional fourth-wall breaks, and sincere breathing room.
  Avoid paired slogans, generic sarcastic-robot jokes, and a punchline on every line.
- This is a full action level, not a movement tutorial. Terrain and encounters should teach through play.

## Entrance and route proposal

Use a basement service entrance for the playable start, following character selection and the approved opening.
The exact door, stairwell, room order, distances, and checkpoint locations are Level Design decisions.

Suggested environmental progression: service access, increasingly compromised maintenance infrastructure,
then a collection chamber housing the fatberg. Give spaces a practical building-service purpose rather than
presenting arbitrary platforms. Broken equipment and abnormal flow can establish worsening conditions without text.
No exact terrain sequence or additional enemy roster is approved by this brief.

## Narrative beats

1. BJ introduces himself and assigns the basement job. Tony introduces Sean warmly.
2. Combat establishes that BJ understated the problem. Support dialogue is optional and brief.
3. Deeper infrastructure shows that this is more than isolated hostile fixtures. Environmental clues should be
   visible before dialogue interprets them. Specific evidence of BJ's wrongdoing remains proposed lore.
4. Confront the Clogfather in the collection chamber. Preserve readable action; avoid mandatory speeches during combat.
5. Proposed reveal: defeating the fatberg uncovers an eerie portal or impossible opening behind the blocked outflow.
6. Authorized transition: the selected hero is involuntarily pulled through; the other remains outside on radio.

The portal is a user-requested art concept and favored story direction, not a finalized cosmology. Do not identify
its destination, establish time travel, make BJ confess to creating it, or reveal the eventual antagonist here.
His evasiveness should allow concealment of a mistake as well as deeper knowledge.

## Finale and exit constraints

The intended boss design is a rooted fatberg with moving pipe mouths/extensions, telegraphed sludge attacks,
overhead hazards, and attack openings. Game Mechanics owns tuning; Level Design owns arena space and safe routes.
Small-enemy releases and interactive valves are proposed mechanics, not narrative requirements.

Prototype 86 replaces the interim exit with a brief portal aftermath and involuntary departure.
Do not implement level two or resolve its destination in this delivery. Keep the support plumber's location
consistent; a radio reply must not imply they suddenly stand beside the selected hero.

## Dialogue sources and implementation boundaries

The current approved opening and route-specific prototype endings live in
[story_dialogue.gd](../scripts/story_dialogue.gd). Use that source for exact text and semantic portrait emotions.

- Opening plays after selection on a fresh new game; either choice uses the same introduction.
- Do not replay the opening on death, checkpoint recovery, or retry.
- All conversations are skippable. Preserve gameplay freeze, device-appropriate prompts, and dismissal input guards.
- Between-level conversations should generally run four to eight lines and reveal one meaningful development.
- Both character routes convey the same essential facts through distinct dialogue.
- Essential discoveries must not depend on optional radio remarks during combat.
- Every line carries a semantic emotion. Tony's kindness is the default; skepticism is not contempt for Sean.

The canonical completion data now supplies six portal-aftermath lines per hero for Prototype 86 integration.
Engineering owns the one-shot transition from completed or skipped dialogue into suction, then the honest
“Level two not yet playable” completion boundary. The old next-address and four-line victory endings are superseded.
Do not stack endings or claim all optional enemies are dead or the plumbing has been repaired.

The [portal ending contract](../handoffs/clogfather-portal-story.json) defines presentation and reset boundaries.
No runtime delivery is claimed by this narrative update; use Engineering's final build record for integration status.

## Remaining decisions

- Final route and encounter plan, boss implementation scope, and exit placement.
- Final visual timing and validation of the authorized first-level portal departure.
- Final character-specific boss/reveal dialogue once actual implemented events are known.
- Source of the living fatberg, portal destination, and relationship to BJ's later corruption.
- Second-level destination. Earlier locations remain candidates, not an agreed itinerary.

## Opening cinematic note — October 16, 2026

Sean wants a skippable cinematic that introduces the story before playable action, inspired by the dramatic
opening he described in Contra III: The Alien Wars. The reference is for a visual introduction with immediate
stakes, not for copying its invasion sequence, imagery, or music.

**Status:** Requested direction recorded; story beats, script, length, and production are undecided.
No artwork, audio, or runtime work is commissioned by this note.

The cinematic should introduce the world and give the player a reason to care about the first assignment.
Its exact position relative to character selection and the existing BJ introduction remains open. Avoid repeating
the same exposition in both scenes. It must be skippable without losing access to essential gameplay instructions.

Possible subjects to explore later include everyday life under AI management, Mainframe Plumbing & Supply's
reach, and the first visible signs of plumbing trouble. These are brainstorming prompts, not agreed events.
Do not reveal BJ's later takeover, resolve monster origins, or commit the portal mythology through this opening.
The cinematic's duration needs a separate decision; the dispenser's seven-second limit does not apply to it.

Level Design and Engineering own roadmap integration for this coordination. This brief makes no build, screenshot,
or delivered gameplay claims.
