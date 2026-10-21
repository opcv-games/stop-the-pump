# Playtest Log

One entry per hypothesis. Newest first.

## 2026-10-21 — Round 8 design session  (#37)
Hypothesis: A deeper tree, a living lot and a newspaper that tells the story make the loop worth many more runs.
Variable: round 8 (docs/ROUND_8_PLAN.md)
Sessions: design session with the designer (no playtest yet)
Observed: "The gameplay is tight. The tension between refuelling now to get an upgrade and refuelling later to buy more gas at a lower price is crazy good." Asked for: the GAS TANK as an industrial tank and a truck animation; many more upgrades, some needing two; a tube man perk (grab, siphon, spit, drop); perks as lot props; bling worn on the nozzle; animated regulars going in and out; a built-out lot; reports and lore in a newspaper and on the menu ("rumours about the kid, that his dad ain't dead, he's getting good at this, wonder if he's single"); Misses split into Overfilled and Unserved; better art (people, cars, night UI).
Biggest weakness: not playtested yet.
Decision: BUILT in v0.43.0; awaiting the designer's playtest.

## 2026-10-21 — GOD PUMP v0.40: the overnight build  (#37)
Hypothesis: The full GOD PUMP loop (days, fuel truck and cards, night tree, car types, Papa's Garage, intro and ending) makes a game worth replaying.
Variable: v0.40.0 (the whole overnight batch)
Sessions: 1 (self: 1, others: 0)
Observed: Lost a run by forgetting to refuel: stretched the tank, invested in upgrades, then couldn't afford a delivery. New car types read as a difficulty ladder that adds variety (intended). Wants day 50 to be impossible at first and to take about two hours of permanent upgrades. Asked for a dev mode with a configurator (free money, skip to the next night), credits to OPCV Games, and a 45 s demo video.
Biggest weakness: the forgotten-truck dead end (a run lost to a missing warning, not to skill).
Decision: KEPT the loop. Fixed the dead end (warning, second-click buy, partial deliveries); F1 dev panel; balance retuned with a campaign bot (v0.41.0).

## 2026-10-20 — God pump, round 6: HD-2D  (#36)
Hypothesis: Pixel art in a lit 3D scene (HD-2D) gives the gaz bar the look it deserves.
Variable: three-quarter pixel view → HD-2D (shadows, bloom, tilt-shift)
Sessions: 1 (self: 1, others: 0)
Observed: "The HD-2D art direction is good" (satellite photos of real Québec gas stations for reference). The tilt-shift is too strong. The regulars should applaud on Perfect too. Wants dust, cars both ways on the road, no $ on the gas pump dial, a rundown car, a tire pile, a garbage container, a darker patchy ground with grass and texture, a tree, and the lot surrounded.
Then the brief for the overnight batch: nozzle upgrades (auto-aim, drone nozzles; drones are the automation, the auto-battler arc is dropped); marketing queues cars at opening; attractions bring cars (traffic light, car wash, mini grocery); many car types unlocked over time; permanent XP upgrades (nozzles, bling, procs, first-car, cheaper, refunds, luck); an end-of-day report; a Bills-style bill with a choose-one-of-three card (maybe through when you refill the tank, gas prices rising each refill, the clock limiting the day); about 50 runs to the ultimate, an ending where Dad drives in; the game titled GOD PUMP with a tongue-in-cheek intro. OK to retire the key-per-pump game.
Decision: KEPT HD-2D. The overnight plan is docs/GOD_PUMP_PLAN.md.

## 2026-10-20 — God pump, round 5: three-quarter view, regulars, jar  (#36)
Hypothesis: The three-quarter camera, the regulars, the pinball neon and the tip jar make the gaz bar alive and the payoff richer.
Variable: isometric → three-quarter; cash counter → tip jar + bill pile; + regulars, neon flash, vintage pump, gauges
Sessions: 1 (self: 1, others: 0)
Observed: "The three quarter angle is wonderful." "The regulars and the neon make the place feel alive." "The jar and bill pile are more rewarding even." Not happy with the aesthetic overall: wants to try HD-2D. Remove the tip when you overfill. Remove the hand on the nozzle (keep its animation). Remove the funnels. Let coins and bills lie 3 seconds longer.
Biggest weakness: the overall look.
Decision: KEPT the camera, regulars, neon and till. Next (v0.33): the four tweaks, then an HD-2D try as a switchable view.

## 2026-10-20 — God pump, round 4: isometric try and neon  (#36)
Hypothesis: An isometric pixel view with the dépanneur, neon and stacked sedans makes the gaz bar feel like a place.
Variable: top-down → isometric; new references (neon, orange hatchback, dépanneur interior)
Sessions: 1 (self: 1, others: 0)
Observed (requests): the camera wanted is a high-angle, three-quarter top-down view, not isometric. Give cars a cartoon fuel funnel and a fuel gauge instead of a bar. Put the music back on. The nozzle looks weird: make it a real nozzle (reference photo) with a hand that squeezes the handle to pour. Animate the gas pump itself, showing the gas level (reference: a vintage pump with a clock-face dial). Tips go to a tip jar; don't count sales during the round, show the bills piling up next to the jar. Add the regulars by the dépanneur: make the gaz bar alive. The neon flashes joyfully on Super, Perfect or Good, like a pinball machine. Spilled gas stays for the whole round. A clock with an Ouvert/Fermé sign: opens at 7 h, closes at 13 h, the round length unchanged.
Decision: all in one pass (v0.32).

## 2026-10-20 — God pump, round 3: cash drop, $75 gas, pixel art  (#36)
Hypothesis: Cash that drops and flies to the counter, a shorter gas tank and pixel art make the god pump feel finished enough to commit to.
Variable: coins on result → bills (sale) and coins (tip) dropped on the lot; $150 → $75 of gas; greybox → claude-pxl pixel art
Sessions: 1 (self: 1, others: 0)
Observed: "Cash drop is incredible now." The gas amount is right. The pixel-art style is working. "God Pump is 1000% the right direction."
Biggest weakness: none blocking; wants to try an isometric view. Art reference: a photo of regulars in front of a small-town Québec dépanneur (plaid flannel, denim, browns and beiges, an aluminium storefront with shelves of oil cans, a red curb, a boxy 80s sedan).
Decision: KEPT. The god pump becomes the game. Next: try isometric (toggle to compare), styled after the reference.

## 2026-10-20 — God pump, round 2: 80% rule and tips  (#36)
Hypothesis: Leaving at 80% with tips growing toward 100%, overflow as waste and gas as the round limit make juggling feel good and make Perfects desirable.
Variable: exact-stop tiers → 80% rule + tip curve; clock → round gas
Sessions: 1 (self: 1, others: 0)
Observed: "Makes the juggling feel good and the animation makes you want to hit perfects." "Excellent round of upgrades." Running out of gas took too long. Movement patterns weren't readable yet, but that's expert-level play.
Biggest weakness: rounds too long ($150 of gas).
Decision: KEPT. Gas halved to $75. Next: cars drop their cash (bills for the sale, coins for the tip), and a pixel-art juice pass with claude-pxl.

## 2026-10-20 — God-pump prototype, first look  (#36)
Hypothesis: Aiming a giant nozzle at cars driving around the lot is more fun than holding keys, and multi-car juggling deepens Mastery.
Variable: hold keys per pump → aim and pour with the mouse (separate greybox scene)
Sessions: 1 (self: 1, others: 0)
Observed: "Aiming is much better." Juggling cars, and learning their movement to fuel many at once, is a big part of the fun; car types could move differently. But the tier animations don't make you want the next Super Perfect: it isn't clear what a Perfect achieved. With continuous flow and moving cars, exact-stop scoring fights the play (you pour car 1, then 3, then 11, then 5, then back to 3 and 1).
Biggest weakness: scoring built for single exact stops.
Decision: KEEP the god pump. Change: a car leaves once it's 80% full; tips grow toward 100% ("topped off" pays the most); overflow just spills as wasted gas; the round ends when the gas runs out (the clock is a safeguard); cars follow readable patterns.

## 2026-10-20 — v0.28–v0.29 Station tab and balance pass  (#33, #34)
Hypothesis: Pumps on a station tab and a simulator-balanced economy make the run feel fair and readable.
Variable: per-pump branches → station tab; economy → simulator pass
Sessions: 1 (self: 1, others: 0)
Observed: The game "feels extremely tedious now. The days are too long." In Bills, rounds start at 15 s and grow to 45 s at most. The smash animation is what makes Bills fun: the pigs absorb hits until they break, then release coins of different values that fly to your cash.
Biggest weakness: day length.
Decision: KEPT the station tab and balance pass. Next (v0.30): 15-second days and an HOURS branch (Dad only opened mornings). Then the "piggy-bank car" juice: the car fills, pops, and coins fly to your cash.

## 2026-10-19 — v0.27.0 Bills-style tree and nightly fuel order  (#31, #32)
Hypothesis: One radial tree and a nightly fuel order make the night shop beautiful and add a real cash decision between rounds.
Variable: branch cards + pumps page → one radial tree; automatic refill → fuel order
Sessions: 1 (self: 1, others: 0)
Observed: "This made the game much better. The tree looks great." But a branch per pump is the wrong design: pumps should be bought and improved in a gas-station view tab. The fuel order matters: you can play it just in time and min-max it (balance later).
Biggest weakness: per-pump branches clutter the tree.
Decision: KEPT both. Next (v0.28): a "Your station" tab where you build and improve pumps on the station itself; the tree keeps the station-wide branches. Then a balance simulator (bot harness #6) with an even share of Super/Perfect/Good/OK/Miss.

## 2026-10-19 — v0.26.0 Story intro and a one-pump start  (#29, #30)
Hypothesis: A short inheritance story and a single starting pump make the first minutes clearer and give the run somewhere to grow from.
Variable: no intro → captioned intro (Saint-Clin-Clin-des-Meuh-Meuh, Québec); 2 starting pumps → 1; day-1 rent $100 → $60
Sessions: 1 (self: 1, others: 0)
Observed: "The intro is fine for now", to be improved later. One pump on day 1 is boring, but that's expected for the genre: you quickly want to automate, and permanent power will make starts less boring. Survival and balance don't matter yet (balance pass later).
Biggest weakness: the night upgrade shop "looks so bad": it should be a beautiful Bills-style tree branching from the centre. Also wants to decide between rounds whether to refill the tank, and by how much.
Decision: KEPT. Next (v0.27): Bills-style radial upgrade tree; fuel order between days.

## 2026-10-19 — v0.24–v0.25 Natural cars, glug sounds, pop-ins, upgrade props  (#27, #28)
Hypothesis: Cars that park before service, softer pour sounds and props that pop in after each upgrade make the station feel alive and purchases feel rewarding.
Variable: instant cars → curved, braking cars gated on parking; clicky nozzle → glug loop + counter knocks; static station → every upgrade pops in a prop the next morning
Sessions: 1 (self: 1, others: 0)
Observed: Cars arrive smoothly and can only be served once parked. "The pouring sound is pretty funny now." "The new pump animations are great." The billboard was misplaced: it stood on the road.
Decision: KEPT all. Billboard moved onto the sand beside the road and shrunk so it clears the road and the COMBO/XP display (v0.25.1).

## 2026-10-19 — v0.23.0 Juice pass  (#26)
Hypothesis: Stream, sparkle, cash pops, road cars and world shake make stops feel better without hurting readability.
Variable: no juice → five juice effects (each switchable in F2)
Sessions: 1 (self: 1, others: 0)
Observed: "Feels much better." "The shake is fun." Cars don't feel natural: you can pump a car as soon as it enters the frame, before it reaches the pump; cars turn at 90° without slowing. The nozzle sound is extremely annoying and clicky: wants a glug-glug fuel sound and a crick-crack-crock counter. Wants upgrade juice: a new pump should rise from the ground and pop out like an inflatable; every upgrade should change how the station looks.
Decision: KEPT all five effects. Next (v0.24): cars gate service and drive smoothly; glug and counter sounds; pumps pop in. Then a Blender step for cosmetic props per upgrade.

## 2026-10-19 — v0.21–v0.22 Lanes, cars, station name, HUD pinned to lanes  (#24, #25)
Hypothesis: A 3D station with one lane per pump and each pump's HUD pinned to its lane stays readable while looking like a real place.
Variable: grey 2D panels → 3D lanes + compact lane cards
Sessions: 1 (self: 1, others: 0)
Observed: "The art looks good." Pumps read fine; card-to-pump mapping is obvious; the staircase looks good, but it is unclear how it scales to 10 pumps and beyond. Wants a 10x speed.
Decision: KEPT (Phase 4 art direction for the slice). Added 10x speed (v0.22.1). Scaling past 5 pumps goes to Later (camera pulls back, compact cards).

## 2026-10-19 — v0.19.0 Endless mode, auto on/off per pump  (#20)
Hypothesis: Switching a pump between auto and manual lets the player push for combos when a day is at risk (9 Kings' manual attack).
Variable: auto locked on → auto on/off per pump; endless mode after day 10
Sessions: 1 (self: 1, others: 0)
Observed: Switching to manual is worth it "when it feels like you'll lose the round"; making that true is a balance question. Endless mode is for later.
Decision: KEPT. **Phase 3 complete**: core declared fun (playtest 8) and confirmed through playtest 17. Move to Phase 4 (art).

## 2026-10-19 — v0.18.0 Run arc: 10 days, speed, full automation  (#19)
Hypothesis: Manual early, automated later, with speed control, gives the run an arc (9 Kings).
Variable: endless days → 10-day run; 1x/2x/3x; full automation allowed
Sessions: 1 (self: 1, others: 0)
Observed: "Speeding up does make it feel like the machine is running." Automated days "feel like you automated... just like an auto-battler. Make the right decision, let it run, hope you didn't overstretch." Wants an endless mode, and to switch a pump between auto and manual to chase combos.
Decision: KEPT. Next (v0.19): endless mode after day 10; auto on/off per pump.

## 2026-10-19 — v0.17.0 Customers with rules  (#5)
Hypothesis: Customers who each change one variable of the stop (overshoot from your pocket, a changing order, a patience timer) add Comedy and make the player adapt.
Variable: Regulars only → Regular, $20 Guy, Confused Grandpa, Impatient Businessman; grey car + speech bubble
Sessions: 1 (self: 1, others: 0)
Observed: The $20 Guy makes no sense (everyone pays cash). Customers don't change how the player plays: the game is too fast and a single fill doesn't count enough to stop and adapt. Reference: 9 Kings: manual attacking matters early, then becomes annoying and gets automated.
Biggest weakness: per-fill decisions don't matter at this pace; the run has no arc from manual to automated.
Decision: KEPT customers (refine later), $20 Guy retired. Pivot (v0.18): manual early, mostly automated by a third of the run, 1x/2x/3x speed, 10-day run with a finish line.

## 2026-10-19 — v0.16.0 Upgrade tree per pump  (#18)
Hypothesis: Giving every pump its own tree makes building the station feel personal (Advancement).
Variable: station-wide pump upgrades → a tree per pump (Tab page)
Sessions: 1 (self: 1, others: 0)
Observed: "The auto pumps work fine." Bug: "End day" on day 2 with two self-service pumps never reached the summary (the dev button's release was ignored by self-service pumps). Fixed in v0.16.1 with a regression test.
Decision: KEPT. Next: customers with rules, with a grey car and a speech bubble per pump.

## 2026-10-19 — v0.15.1 Self-service pumps  (#17)
Hypothesis: A self-service pump turns expansion into a business decision instead of a finger problem (Advancement), without replacing skill.
Variable: Turbo nozzle → self-service branch
Sessions: 1 (self: 1, others: 0)
Observed: A self-service customer froze at $5.40 for 2 minutes. Cause: releasing the pump's key (by habit) cut the customer's fuel; the customer then waited forever. Fixed in v0.15.2 with regression tests. Designer wants pump upgrades as a tree **per pump**. "The core loop works, the upgrades are ok, but we should get into making it visually engaging soon."
Biggest weakness: freeze bug (fixed); pump upgrades are station-wide instead of per pump.
Decision: KEPT self-service (pending a clean playtest). Next: per-pump upgrade trees; plan the move to Phase 4 (visuals).

## 2026-10-19 — v0.13.0 Upgrade tree, cash-only costs, Roadside At Two  (#15)
Hypothesis: A Bills-style tree with cash-only upgrades gives the player a plan across days (Advancement).
Variable: random 3-offer shop → 5-branch tree; no gameplay downsides; real backing track
Sessions: 1 (self: 1, others: 0)
Observed: "The tree def gives you a plan, you start building the just one more turn logic." Turbo nozzle makes combos harder the faster it gets. Balance is out of scope for now. The music engineering (tier notes, chord tracking, beat-synced clicks) should go: just SFX + background music.
Biggest weakness: Turbo works against Mastery; the music system is complexity the designer doesn't want.
Decision: KEPT the tree. v0.14 removes the music engineering (SFX + BGM only). Next candidate: self-service pumps replacing Turbo.
Ideas raised: self-service pumps (card fee 3%, slower pumping, slow customers; upgrades: speed, lower card fee).

## 2026-10-19 — v0.12.0 Night shop, random offers  (#14)
Hypothesis: 3 random cash upgrades each night, each with a gameplay downside, make each run's station different (Advancement).
Variable: no shop → random 3-offer shop
Sessions: 1 (self: 1, others: 0)
Observed: Designer prefers an upgrade tree like Bills Must Be Paid over random offers, and wants upgrades whose only downside is their price (no gameplay malus). Supplied a real backing track ("Roadside At Two", 92 BPM, 120 s loop).
Biggest weakness: downsides made upgrades feel like punishments; random offers don't give a plan to work toward.
Decision: REWORKED (v0.13): a 5-branch upgrade tree, cash-only cost; design rule 1 rewritten; real track as the backing.

## 2026-10-19 — v0.10.0 Super Perfect, backing band  (#12)
Hypothesis: A Super Perfect tier gives the best players a ceiling; a backing band with stops as melody keeps the song going between stops.
Variable: new tier (±$0.03, display snaps to target); backing band + per-tier melody notes
Sessions: 1 (self: 1, others: 0)
Observed: Super Perfect count visible; the 60 fps fix is invisible to players (fine). The dollar clicks don't follow the band's tempo. The placeholder loop feels like it restarts after under 10 s (it is 32 s, but the bass repeats every bar). Notes still feel isolated, not like playing over the band.
Biggest weakness: the designer can't test outcomes or tune numbers without asking Claude.
Decision: KEPT. Next (v0.11): dev mode (forced outcomes), tuning panel, on-the-beat click option. Real backing track to come from the designer.
Ideas raised: riffs that grow with the tier (Parked until real audio), Tony Hawk-style combo chains (Parked), clicks on the beat (Now).

## 2026-10-19 — v0.9.0 Gas Bar Blues: 12-bar blues on good stops  (#11)
Hypothesis: If good stops walk a 12-bar blues, the music carries the theme and a chain feels like playing the song.
Variable: pop chord loop → 12-bar blues in A
Sessions: 1 (self: 1, others: 0)
Observed: The blues direction is right. But stops can be many seconds apart, which breaks the song. Wants tiers to map to how many notes play.
Biggest weakness: the music has gaps; it only exists when the player stops a pump.
Decision: KEPT the blues. Next (v0.10): a continuous backing band (walking bass + hi-hat) with the player's stops as melody; Super Perfect tier (3 notes), Perfect 2, Good 1, OK none, Miss a sour note.
Ideas raised: Super Perfect tier for stopping on the dot (Now).

## 2026-10-19 — v0.8.0 Random arrivals, chord progression  (#10)
Hypothesis: If cars arrive after a random 1–5 s, then the rhythm can't be memorized and the player stays alert, increasing Mastery. Juice: good stops walk C–G–Am–F; a break falls apart.
Variable: fixed 1.5 s arrivals → random 1–5 s; octave combo → chord progression
Sessions: 1 (self: 1, others: 0)
Observed: Arrival rhythm "great"; cars arriving together is fine; randomness is good. Chord progression great, but it should be the blues. "This game is clearly becoming more and more fun."
Biggest weakness: none blocking in the core loop. Music should carry the theme (blues).
Decision: KEPT. Game renamed **Gas Bar Blues**. Next: 12-bar blues progression (v0.9).
**Phase 3 gate:** the player reports the core interaction is genuinely fun, backed by playtests 1–8.
Ideas raised: cars drive in from the end of the street (Phase 4 animation); marketing upgrades shorten the min–max arrival wait.

## 2026-10-19 — v0.7.0 Car-cleaning delay, merged gauge, octave combo  (#9)
Hypothesis: If overshooting past the OK window locks that pump for 4 s (car cleaning), then overshoot costs time and finally feels costly, increasing Mastery.
Variable: cleaning off → on (4 s); two gauges → one; combo sound pitch → octaves
Sessions: 1 (self: 1, others: 0)
Observed: Only two overshoots; the player is "getting good at this game". Cleaning made play more engaged and attentive, "wanting to stop on the button". No time to watch the gauge during play. Octaves fine but a chord progression would be better.
Biggest weakness: arrivals are too regular (fixed 1.5 s), so there is no surprise in the rhythm.
Decision: KEPT cleaning delay (necessary). Gauge kept but not watched (rethink later). Octaves replaced by a chord progression in v0.8.
Ideas raised: random arrivals (Now), marketing upgrade branch: more cars, more often (Later), chord progression that breaks on a fail (Now).

## 2026-10-19 — v0.6.0 A full day: tank, clock, cash + XP  (#8)
Hypothesis: If the day has hard limits (400 L tank, 7am–11pm in 3 minutes) and costs land at day end, then overshoots become visibly costly and each day becomes a unit of progress, increasing Advancement.
Variable: v0.5 per-stop economy → v0.6 full day
Sessions: 1 (self: 1, others: 0), several days
Observed: Tank and clock ran out at about the same time (good). Survived and "thrived" on day 1. XP climbing was noticed. Overshoot still does not feel costly enough. Separate cash and tank gauges hide the trade-off.
Biggest weakness: overshoot is not costly enough.
Decision: KEPT. Next: car-cleaning delay (C toggles it), one merged fuel-to-cash gauge, an octave per combo step.
Ideas raised: merged gauge (Now), tips as a personal currency (Parked), upgrades: bigger tank and faster pour (Later, shop).

## 2026-10-19 — Fuel economy, first draft  (#3)
Hypothesis: If each stop earns money (margin on fuel + combo-multiplied tips, overshoot fuel given away), then precision and volume both pay, increasing Advancement.
Variable: score → cash (v0.5)
Sessions: 1 (self: 1, others: 0)
Observed: Money changed play: excited to finish the turn to spend it. But combo-multiplied tips make no sense in the fiction, and per-stop fuel costs hid the real cost of overshooting (still not painful). UI text too small to read.
Biggest weakness: overshoot cost is invisible and too forgiving.
Decision: REWORKED into #8: two currencies (cash + XP), full payout at the pump, costs between days, shared tank, day clock, gauges, bigger UI, version number. Cleaning delay queued as the next single-variable test.
Ideas raised: car-cleaning delay after overshoot (Now, next), combo fire animation (Next), inspections, calibration, bribes (Later / Parked).

## 2026-10-19 — Second pump, shared combo  (#4)
Hypothesis: If two pumps run at once (keys 1 and 2) with their own customers and one shared combo, then splitting attention creates depth a single pump cannot, increasing Mastery.
Variable: pump_count 1 → 2
Sessions: 1 (self: 1, others: 0), about 5 minutes
Observed: A real difficulty layer: it took about 5 minutes to chain a combo. The player invented a strategy ("like piano classes"): start both pumps together, stop the smallest target first, then the larger one. More demanding, more rewarding (more points, faster high combos). Releasing two keys at once was not a problem. Global combo is right.
Biggest weakness: the strategy may become a fixed recipe once learned (same risk that killed the rusty lever). Customers that change the plan mid-pour are the counter.
Decision: KEPT. Combo stays global.

## 2026-10-18 — Rusty lever  (#2)
Hypothesis: If the pump keeps pouring 0.4 s after release, then stopping becomes anticipation instead of reaction, deepening Mastery.
Variable: release_delay 0 → 0.4 s
Sessions: 1 (self: 1, others: 0)
Observed: It felt like learning a skill at first, getting more accurate. But a fixed delay is just "aim $1.60 short" once learned, so there is no long-term depth; a random delay would feel unfair. The dollar clicks were too fast to use for timing.
Biggest weakness: no lasting depth; the skill is a constant offset.
Decision: REVERTED. Branch deleted. Depth must come from juggling pumps and customer modifiers.
Ideas raised: visible per-pump quirks (Parked).

## 2026-10-18 — Combo multiplier + placeholder sound  (#7)
Hypothesis: If chained Good-or-better stops build a multiplier that resets on OK/Miss, then every stop carries stakes, increasing Mastery. Sound tested in the same cycle behind a mute toggle.
Variable: combo off → on (x1–x5); sound off → on
Sessions: 1 (self: 1, others: 0), with and without sound
Observed: Both clear improvements, each on its own. Strong pressure when holding x5, then missing. Dollar clicks are great for timing.
Biggest weakness: none blocking; next is depth of the skill itself (rusty lever, #2).
Decision: KEPT both.
Ideas raised: musical clicks with an accent every 4th dollar (Next, juice).

## 2026-10-18 — Pour and stop, one pump  (#1)
Hypothesis: If a climbing number and Perfect/Good/OK/Miss scoring are shown, then a single stop feels skillful on its own, increasing Mastery.
Variable: baseline (flow $4/s, windows ±0.10 / ±0.50 / ±1.00)
Sessions: 1 (self: 1, others: 0), 14 pours
Observed: 1 Perfect, 8 Good, 5 OK, 0 Miss. Misses were readable ("just kind of fast, not impossible"). Speed felt right; slower would be boring. Player wanted another go to hit more Perfects.
Biggest weakness: "Kind of boring": stops carry no stakes, so skill does not build up into anything.
Decision: KEPT. Core loop is alive. Next hypothesis: combo multiplier (#7).
Ideas raised: chains (testing now), XP currency (Parked), tank size as stamina (Next, with round structure).

<!--
## YYYY-MM-DD — <hypothesis name>  (#issue)
Hypothesis: If ..., then ..., increasing <form of fun>.
Variable: <name> <old> → <new>
Sessions: <n> (self: x, others: y)
Observed:
Biggest weakness:
Decision: KEPT / REVERTED — why
-->
