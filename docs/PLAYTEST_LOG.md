# Playtest Log

One entry per hypothesis. Newest first.

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
