# Level two flush and log ride proposal

**Date:** October 20, 2026 (America/Los_Angeles)

**Owner:** Storyboarding owns narrative; Engineering owns the authorized flush and first ride slice.

**Status:** October 24: short playable flush delivered in Prototype 98, with swimming and presentation revisions
through Prototype 100.
October 25: Engineering relays PM authorization for the first 30–60 seconds of the ride. Full ride and level three
remain deferred. New dialogue requires Sean’s review before integration.

## Current production scope

On October 24, PM relayed Sean's explicit start of the short level-two flush. Engineering may implement the roughly
45-second playable bowl sequence, both hero radio routes, safe one-time overlay relocation gag and log landing.
The [final flush script and event contract](../handoffs/level-two-flush-story.json) supersedes the draft arrival/gag
examples below for this delivery. Exact runtime implementation remains Engineering's responsibility.

Sean's Prototype 98 playtest revised the flush to chest-deep swimming and dodging only: Tony uses freestyle,
Sean uses breaststroke, and no weapons, firing or jumping are available during the flush. Animated water accelerates,
nine kinds of objects fall with shadow warnings. The final descent into the drain uses occlusion and fading burbling.
Prototype 100 adds a recessed funnel, persistent floating-object damage, a shrinking movement area and 26/48/85
falling objects on Easy/Normal/Hard. Control and damage end together at 35 seconds. Sean lands seated astride a short
board; Tony stands in a surfing pose. The partner's chat window moves during the partner's response. The selected
45-second “Air Running Out” arrangement follows the flush clock and ends at the landing.
The [current integration record](../handoffs/first-call-integration.json) documents validation and limitations.
Live animation, listening, human balance review and occasional planning hitches remain open.
The October 25 authorization below covers only the first movement-and-dodging ride slice.

Only the selected hero enters. Support stays outside on radio; portal origin and BJ involvement remain unresolved.
The harmless landing completes the flush and preserves its checkpoint. The existing landing exchange leads into the
first ride slice; a ride retry returns here without replaying the flush. Full-course waves and level three remain deferred.
Earlier first-level portal authorization remains in effect. No game-opening permission follows from this scope.

## October 25 authorized ride slice

Engineering relays Sean’s approval through PM for 30–60 seconds of forced-forward riding after the flush.
The slice covers movement and dodging: steer around tall supports, jump low barriers and clear gaps. Preserve the
landing checkpoint so a ride failure does not repeat the flush. Only the selected hero rides; the partner remains on
radio. Use calm teaching stretches and the existing compact overlay, with no new overlay gag.

This authorization supersedes the ride hold above only for this short slice. The full 3–4-minute ride, level three
and combat remain deferred; weapon behavior beyond this slice is undecided. Earlier combat and wave suggestions
below are future proposals, not requirements for this delivery.

Sean requested review before any dialogue changes. The
[ride dialogue proposal](../handoffs/level-two-ride-story.json) is explicitly unapproved and must not be integrated
until he approves it. Existing landing and flush dialogue remains unchanged. Teaching cues must also be readable
through the environment; no obstacle may require reading a radio line to survive.

## October 25 playtest revision

Prototype 103 doubles all 15 existing flush dialogue durations without changing wording. Calm staging moves hazard
onset to 34 seconds, automatic drain to 61, and landing to 71; the landing line lasts six seconds and the ride begins
at 77. The original 45-second physics/score timeline runs after a 26-second calm prelude, without faster hazards or music.

The same ride course now runs at 225 pixels/second instead of 180, taking 36 seconds instead of 45. Steering remains
160 horizontally and 140 between banks for both heroes. Obstacle counts remain 8/12/16. Each obstacle traversal can
cost one HP, with shared immunity and a contact latch; nonlethal gap contact recovers in place. Only depleted HP causes
normal death and landing-checkpoint retry. Human review of pace and recovery feedback remains pending.

## October 26 pace and HUD revision

Prototype 104 increases the ride to 280 pixels/second, completing the same 8,100-pixel course in 28.93 seconds.
Ride-only steering increases to 200 horizontally and 175 between banks; jump timing and collision geometry remain
unchanged. The tightest authored bank transfer retains 0.174 seconds of spare time. Warning leads remain
2.4/2.0/1.6 seconds for Easy/Normal/Hard, recalculated against the faster approach. Damage and recovery rules remain.
Flush timing and music are unchanged. Shared health markers and selected-hero life portraits now serve all gameplay,
including flush, landing and ride; numeric-only substitutes require Sean's explicit approval.

## October 26 double-speed request

Prototype 105 runs at exactly twice Prototype 104's ride speed: 560 pixels/second over the same 8,100-pixel course,
completing in 14.46 seconds. Ride steering increases to 400 horizontally and 350 between banks. Obstacles and world
geometry remain intact. All 18 source routes pass with staggered takeoffs and unchanged 1.2-second jumps,
72-pixel height and 0.15-second cooldown. Bank-transfer spare time narrows to 0.087 seconds. The opening cue starts
immediately, with 1.6625 seconds before earliest contact; later warning leads remain unchanged.
The final jump cue uses actual approach speed for a 0.2-second lead and respects jump cooldown.
All 19 packaged suites pass. Flush, audio, shared vitals and
one-HP contact damage with gap recovery remain unchanged.

## Selected direction

- Alternate Earth levels (odd-numbered) with fantastical levels (even-numbered), as decided October 26.
  Alternate gameplay formats remain the selected direction; exact later mechanics and locations are open.
- Level two begins with a short flush micro-level, approximately 30–60 seconds, followed by a poop-log ride.
- The ride uses forced forward progression, water as its surface, up/down and left/right movement, jumps,
  obstacles to dodge or attack, raised platforms and triggered enemy waves.
- Sean supplied Battletoads riding-stage screenshots as a reference for the feel and layout of the obstacle course.
  Develop original environments, patterns, characters and assets rather than copying those images.
- Only the selected hero enters the strange world. The other remains outside as radio support.
- Preserve the radio connection for frantic dialogue. The reason it still works need not be explained immediately.
- Tony is kind, patient and capable, but also funny, playful and capable of outrageous remarks and bad ideas.
- Radio dialogue uses a smaller portrait and timed text overlay without stopping gameplay.
- A one-time misplaced overlay gag animates the portrait and dialogue from the center to the bottom of the screen.
  Sean rejected “Bring your face”; do not use that line.

## Story treatment

The confirmed October 26 structure alternates Earth and fantastical levels. BJ assigns the Earth-basement job in
level one; the Clogfather aftermath pulls the selected hero into the fantastical flush and poop-board ride in level two.
The ending of level two returns the hero to Earth for level three. Exact return events and location remain open.
Subsequent levels continue alternating dimensions. A possible collision of the dimensions at the finale is tentative,
not established lore. This decision adds no dialogue or implementation authorization.
See the [campaign structure decision](first-level-narrative.md#october-26-campaign-structure-decision).

Proposed sequence:

1. Defeating the Clogfather exposes an impossible opening behind its mass.
2. Water and debris begin moving toward it. The selected hero is pulled through; support stays outside.
3. The radio briefly cuts out, then reconnects after the hero lands on a vast curved porcelain surface.
4. The enormous toilet becomes recognizable just before its flush begins.
5. The flush carries the hero into a chute and deposits them on the log for the downstream ride.
6. A final jump or discharge ejects the hero into the real world, somewhere unexpected, for level three.

A closed restaurant kitchen is one possible return destination, connecting to Tony's optional kitchen ideas.
It is not a selected level-three location. The portal's origin, the world's nature and BJ's knowledge remain unresolved.
Do not establish BJ as its creator or reveal the eventual antagonistic force through this transition.

The giant toilet and fantastical ride should feel distinct from level one's basement/sewer, not like another sewer map.
Support hears events but has no automatic visual access to the hero's surroundings. The interface gag is a deliberate
fourth-wall exception, not evidence of an in-world video feed.

## Flush micro-level

Proposed target: about 45 seconds within Sean's 30–60-second range.
Survival, not killing every enemy, drives completion.
Use a fixed oblique overhead camera. The current carries the hero around the bowl while the player steers inward or
outward and can modestly resist or accelerate the flow. Keep the camera steady rather than rotating the entire screen.

- First 8 seconds: arrival, recognition and gentle movement. Establish scale with a familiar oversized object.
- Next 12 seconds: dropped debris has visible landing warnings; hard objects require dodging and soft plugs can break.
- Next 15 seconds: one small enemy wave arrives while the current strengthens and clear paths narrow.
- Final 10 seconds: the full flush pulls everything toward the drain; clear a final obstruction and enter the chute.

Durations, enemies, objects and controls are proposed tuning, not locked requirements.
A forward/tangential attack
with limited aiming may keep this short section readable; Mechanics must resolve controls after release.
Remaining enemies can be swept down with the hero. Avoid a mandatory last-enemy hunt.

Place a checkpoint at the log landing so a ride failure does not force another flush. Keep the initial overlay gag
separate from dense debris or demanding steering. If needed, stage it in the calm arrival before the flush timer begins.

## Log ride

Proposed duration: 3–4 minutes, subject to playtesting. Side-on presentation includes enough water depth to support
near-bank/far-bank steering. The current forces progression while the player moves within the visible screen.

- Up/down steers across the water; left/right adjusts position within the scrolling view.
- Jump lifts the hero and log above the water. A clear shadow communicates their landing position.
- Attack uses the selected hero's weapon identity; final firing and aiming behavior needs a ride-specific decision.
- Solid porcelain and pipe supports require steering; low bars and gaps require jumping.
- Fragile paper or grease obstructions can be attacked. Their appearance must distinguish them from solid barriers.
- Ramps and short raised routes provide optional platform riding without turning the stage into ordinary platforming.

Proposed progression: an open practice stretch, a pursuit wave, a slalom and clear jump, an optional raised route,
then a faster final surge combining familiar patterns. Enemy waves trigger at authored points. Separate demanding
obstacle stretches from dense combat until the player understands both, and never obscure a required jump warning.

Seek the excitement of an arcade obstacle course with readable first-attempt warnings. Reserve the hardest combinations
for Hard. Proposed recovery: normal collisions cost health and knock the hero back; gaps use quick checkpoint recovery.
Exact damage, lives, checkpoint spacing, difficulty differences and failure rules remain undecided.

## Radio presentation

Introduce transmissions with a brief static chirp. Use compact portrait-and-text overlays at the bottom by default,
with a top placement available when necessary to preserve important action and HUD visibility.

Proposed line duration is 3–6 seconds, adjusted for text length and reading accessibility. Gameplay continues during
radio lines. Schedule exchanges in calmer stretches, prevent overlapping text and discard stale optional reactions
rather than building a backlog. Essential progress instructions must also be visible through the environment.

After release, resolve readable text size, contrast, portrait emotions, audio levels, mute behavior, pause behavior,
retry repetition and an option for longer reading time. Existing blocking dialogue keeps its own behavior; this proposal
introduces a separate radio presentation rather than silently converting every conversation.

### One-time overlay gag

Against one manageable monster, a transmission initially appears too large in the center. The hero complains and
the entire portrait/text group shrinks and slides to its normal bottom position while the exchange continues.
Keep the obstruction brief, about two seconds as a starting target, and give the enemy a readable windup or safe
staging so the joke cannot force an unavoidable hit. Do not replay the full gag on every checkpoint retry.

Revised draft for Tony as the playable hero:

> Sean: Tony! I've got the connection working!
>
> Tony: Good. Now get your head out of the line of fire.
>
> Sean: I'm not even in there!
>
> Tony: Your face is. Bottom of the screen, please.
>
> [The portrait and text shrink and slide down.]
>
> Sean: Better?
>
> Tony: Much. Now I can see what's eating me.

Draft for Sean as the playable hero:

> Tony: There you are! Can you hear me?
>
> Sean: I can hear you. I can also see your entire head where the teeth were.
>
> Tony: Where do you want me?
>
> Sean: Bottom of the screen. Make yourself short.
>
> [The portrait and text shrink and slide down.]
>
> Tony: Better?
>
> Sean: Visually, yes. Emotionally, we're behind.

These are script candidates, not approved final lines. The animated relocation is selected direction.

## Character voice and dialogue candidates

Sean tries to reason with the impossible, then panics when it ignores him. Tony notices professional details,
responds practically and sometimes enjoys an outrageous situation. Kindness does not make him a permanent straight man.
Keep longer exchanges away from difficult jumps; do not put a joke on every action.

### Arrival with Sean playing

> Sean: Tony? I'm standing in a toilet.
>
> Tony: How big?
>
> Sean: There's weather.
>
> Tony: Get out before it rains.

### Arrival with Tony playing

> Tony: Sean, you should see the porcelain in here. Beautiful work.
>
> Sean: Where are you?
>
> Tony: Inside a toilet. Absolutely no complaints about the finish.

### Flush with Tony playing

> Tony: Somebody pulled the handle!
>
> Sean: Can you stop it?
>
> Tony: With what? My professional reputation?!

### Log reveal with Tony playing

> Tony: I'm riding a turd, Sean.
>
> Sean: I heard you the first time.
>
> Tony: You didn't sound impressed. I'm standing up now.

### Ramp with Tony playing

> Tony: Oh, somebody built a jump.
>
> Sean: Please go around it.
>
> Tony: I've already bent my knees.

These examples preserve the tone Sean liked; final scripts need both playable routes, event triggers and emotions.

## Authorized first-level ending exception

Prototype 86 replaces the interim Clogfather victory exchange with route-specific portal aftermath and suction.
The opening remains unchanged. Only the selected hero enters; the support hero remains outside on radio.
After departure, the completion UI must truthfully say level two is not yet playable. No flush, ride or arrival scene
is authorized by this exception. Portal cause, destination details and BJ's involvement remain unresolved.

See [the ending contract](../handoffs/clogfather-portal-story.json) and canonical
[dialogue data](../scripts/story_dialogue.gd). Earlier dialogue examples in this proposal remain future candidates.

## Responsibilities for current and future work

PM coordinates scope and Engineering owns the flush and first ride slice. The responsibilities below apply to
those authorized slices; full ride, combat and level-three work still require a later start instruction.

- Storyboarding: final route-specific aftermath, radio scripts, triggers and story continuity.
- Level Design: bowl geometry, ride layout, obstacle patterns, wave triggers and checkpoints.
- Game Mechanics: steering, jumping, aiming, collision/recovery rules and difficulty tuning.
- Engineering: integrate approved systems, transitions and nonblocking radio UI; build and verify.
- Art: all new environments, portraits if needed, log, props, sprites and overlay artwork after constraints are agreed.
- Audio: licensed/provenanced radio static, flush/current/ride cues and intelligible mixing.
- Storyboarding and Engineering: preserve actual iteration captures and source studies with honest labels.

Existing art, launch-permission, build delivery and storybook rules continue to apply. This handoff creates no new
artwork, runtime build, playtest request or specialist delivery deadline.

## Decisions for the later design session

- Final duration and control mapping for each segment.
- How literal or surreal the strange world looks, and the level-three return location.
- Weapon behavior while riding and whether alternate melee interactions are needed.
- Enemy roster, obstacle vocabulary, wave counts, checkpoints and failure rules.
- Final dialogue, overlay timing, reading/accessibility settings and placement constraints.
- Scope of the first-level ending revision and acceptance criteria for the Clogfather prerequisite.

## References

- [First-level narrative and current implementation boundaries](first-level-narrative.md).
- [Tony's optional source ideas](tony-idea-bank.json), including crawlspace, bathroom, kitchen and sewer-line notes.
- [Preserved riding-stage references](idea-sources/level-two-2026-10-20/manifest.json).

The supplied reference images are internal design references, not original artwork or game deliverables.

## Prototype 106 isolated encounter showcase

The ride now presents the ten approved obstacle concepts in order at 560 pixels/second, with three full
hazard-free seconds after each encounter clears. Checkpoints and `LEVEL=2-01` through `LEVEL=2-10` support testing.
Regular jumps last 0.6 seconds with a 54-pixel apex and 0.1-second cooldown. The final grounded ramp automatically
launches a 1.25-second flight with a nominal 93.33-pixel apex; bank steering remains available.
Only the mandatory-ramp long pit forces death on failure. Ordinary obstacles retain one-HP damage and recovery.
The authoritative course is `levels/level-two-ride-showcase.json`. These isolated tests do not establish final pacing.
Runtime visual review and actual gameplay captures remain pending; nominal support geometry tests cannot prove
pixel-perfect contact with the irregular board artwork. Flush dialogue and timing remain unchanged.

## Prototype 107 feedback integration

Sean's October 26 feedback supersedes the earlier nonlethal ordinary-gap rule: every actual pit or unsupported-gap
fall costs one life through the checkpoint death flow. Solid, overhead and spike hits remain one HP. Normal riding
water remains safe. The hero and board descend at the failed position before the death menu, with island surfaces
and faces occluding the fall. All existing poses are retained.

The approved ramp ascent, pitch and launch remain unchanged. Its bank-axis depth is now 100 pixels, leaving a visible
lane from 280 to 380 and a full-board center range from 294 to 366. Misalignment cannot snap onto or acquire a boost.
Cap islands and broken basins have revised dimensional faces; their landable top rectangles remain unchanged.
Departing artwork persists independently of collision cleanup through the three-second safe rest.

Screenshot freeze is opt-in through `SCREENSHOT_MODE=1`; controller Y freezes without adding pause UI.
These changes are included in Prototype 107; the preserved Prototype 106 app retains its earlier behavior.
Actual visual review of the revised platforms, pit occlusion and screenshot mode remains pending.

## Prototype 108 slalom, breach and rest jumps

The slalom now uses visibly connected far-wall and near-wall baffles plus a center blocker at 520-pixel spacing.
The original implementation reused identical frontal pedestal images and lacked the center blocker. Its abstract
lane-coverage checks did not establish visible wall attachment. Imported texture coverage and actual input routes
now supplement the collision checks.

Elbow-Pipe Breach uses a supported pipe stump followed by a 700-pixel lower-channel pit with cascading water.
The safe route is along the far bank. Pipe contact costs one HP; unsupported pit contact causes one normal death.
The rest branch now accepts grounded jump presses and advances flight/cooldown continuously, including across the
three-second rest boundary. It does not repeat held input or buffer airborne presses.

The approved float-arm wall mount is a follow-up, separate from the frozen Prototype 108 export. Mixed-course,
brush-curtain and giant hungry-head boss work remain plans rather than implemented gameplay.
