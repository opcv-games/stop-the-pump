# Gas Bar Blues — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [x] `[innovation]` **God-pump prototype: a giant nozzle pours from the sky onto cars driving around the lot** (#36, kept: this is the game now)
- [x] `[art]` **Scene view for the god pump: isometric tried, three-quarter top-down kept; dépanneur, neon, regulars, vintage pump, tip jar** (#36, v0.32.0, awaiting playtest)
- [ ] `[standard]` **Move the god pump into the real game: night shop (tree, station tab, fuel order), opening hours, intro, simulator** (after the isometric test)
- [ ] `[standard]` **15-second days and an HOURS branch (Dad only opened mornings)** (#35, v0.30.0, awaiting playtest)
- [ ] `[juice]` **Piggy-bank car: the car swells as it fills, pops on the stop, and coins of different values fly to your cash** (next)
- [x] `[tech]` **Balance pass with the simulator** (#34, v0.29.0, kept; superseded by #35's numbers)
- [x] `[standard]` **"Your station" tab in the night shop: build pumps, expand the lot and improve each pump on the station itself** (#33)
- [x] `[standard]` **Bills-style upgrade tree: one radial tree branching from the station in the centre** (#31, v0.27.0, kept; pumps move to a station tab in #33)
- [x] `[standard]` **Fuel order between days: choose whether to refill the tank and by how much** (#32, v0.27.0, kept; balance later)
- [x] `[standard]` **Story intro: you inherit your late father's run-down station in Saint-Clin-Clin-des-Meuh-Meuh, Québec** (#29, v0.26.0, kept; to be improved)
- [x] `[standard]` **Start the run with one pump; Pump 2 is the first PUMPS upgrade** (#30, v0.26.0, kept)
- [x] `[juice]` **Juice pass: pour stream, Perfect sparkle, cash pops, cars from the road, world shake** (#26, v0.23.0, kept)
- [x] `[juice]` **Cars serve only once parked, drive smoothly; glug + crick-crack-crock sounds; new pumps pop out of the ground** (#27, v0.24.0, kept)
- [x] `[art]` **Cosmetic prop for every upgrade, popping in the next morning; per-pump props on their pump; billboard shows the name** (#28, v0.25.1, kept; billboard moved beside the road) (tanks, billboard, radio antenna, jukebox, squeegee bucket, tip jar, card reader on self-serve pumps...)
- [x] `[art]` **Look test: Hopper station kit in Blender, isometric renders at morning, afternoon, night** (#21, approved)
- [x] `[art]` **Look test in Godot: isometric 3D station behind the HUD, light from the day clock, rain** (#22, v0.20.0; painterly filter rejected)
- [x] `[art]` **Lanes kit (Blender): parallel lanes, modular pump/island/car props, footprint expansion, decor** (#23, approved)
- [ ] `[art]` **Lanes in Godot: remove the painterly filter, one lane per pump, cars drive in top right and out bottom left, footprint expansion upgrade (paves the vacant lot), player names the station on the pylon** (#24, v0.21.0, kept)
- [ ] `[art]` **Anchor each pump's HUD (order, meter, bubble, result) to its 3D lane; drop the grey panels and 2D cars** (#25, v0.22.0, kept; 10x speed in v0.22.1)
- [x] `[standard]` **Endless mode and auto on/off per pump** (#20, v0.19.0, kept; endless parked until balance)
  - Given day 10 is survived, When I press E, Then the run keeps going (endless) with rising rent.
  - Given pump 1 has Self-service, When I press Shift+1, Then it switches to manual (and back).
- [x] `[standard]` **Run arc: 10-day run with a finish line, 1x/2x/3x speed, full automation allowed** (#19, v0.18.0, kept)
  - Given day 10 ends and I'm not evicted, Then the run-complete screen shows my run and Enter starts a new run.
  - Given I click 2x, Then the whole game runs twice as fast.
  - Given every pump is self-service, Then the station still runs (no pump has to stay manual).
- [x] `[standard]` **Upgrade tree per pump** (#18, v0.16.1, kept): PUMPS branch builds pumps 3–5; Tab opens "Your pumps", each with Self-service > Faster self-serve > Card deal; the last played pump can't convert.
- [x] `[innovation]` **Self-service pumps** (#17, v0.15.2; freeze bug fixed, awaiting a clean playtest; replaces Turbo in the Pumps branch): a pump you convert runs on its own with a 3% card fee, slower pumping and slow customers; upgrades raise its speed and lower the fee. Guardrails: earns less than a played pump, no tips, no combo or XP
- [x] `[innovation]` **Customers with rules: Confused Grandpa, Impatient Businessman; grey car + speech bubble** (#5, v0.17.0, kept; $20 Guy retired; refine later)
  As a player, I want a customer who changes their order mid-pour so that I stay alert (serves: Comedy, Mastery).
  - Given a customer asks for $50, When the pour passes $30, Then the target changes and the display updates.
- [x] `[tech]` **Bot player harness** (#6, done: `tools/sim/run_balance.gd`, report in docs/balance/REPORT.md)
  As the designer, I want scripted bots to play headless so that I can test economy and balance numbers.
  - Given a bot with fixed reaction time, When it plays 100 rounds, Then the run produces a report of income, rent paid and failures.

## Next (likely, not committed)
- [ ] More cars per short day (a day serves only 2–4 cars): cars queue and pull in at once, or smaller orders. Then shrink Dad's 400 L tank so the fuel order matters again (docs/balance/REPORT.md)
- [ ] `[juice]` Combo gauge catches fire at high combos
- [ ] Upgrade shop with downsides
- [ ] Customer queue and patience timer
- [ ] Impatient Businessman (time pressure) and $20 Guy (costly overshoot)
- [ ] Tutorial first 5 minutes
- [ ] `[juice]` Musical meter clicks: accent every 4th dollar like a beat (playtest 3: clicks are too fast to count at $4/s, so this needs rethinking)

## Later (deliberately vague)
- Balance: stations stay at 2–2.5 pumps in the simulator; Expand ($350) and Pump 4 ($400) are rarely reached (docs/balance/REPORT.md)
- HUD: the left gauge partly covers the fuel tanks on a fully upgraded station (move the tanks or slim the gauge)
- Scale past 5 pumps (10 and beyond): camera pulls back as the station grows; lane cards switch to a one-line compact mode past ~6 pumps
- Station looks upgrades in later levels (clean up the run-down station: paint, repair the sign, fix potholes)
- New characters to replace the $20 Guy; customers that matter to automated pumps too
- Balance the run arc: manual clearly worth it on days 1–3, mostly automated by day 4 (bot harness #6)
- `[art]` Phase 4: isometric impressionist station after Hopper's *Gas*; light follows the day clock (morning, afternoon, night); rain cycles; cars drive in from the street
- Permanent upgrades between runs
- Ten-pump ladder tuning
- Between-day costs: inspections, pump calibration
- XP upgrade tree between runs (Bills-style), bought on the eviction screen
- Rethink the gauge: the player has no time to watch it mid-day (playtest 7)
- Gas price variation
- On-release procs

## Parked (good ideas that are out of scope until the core loop is proven)
- Future phase: car types (diesel, electric, environmentalist, ...) with their own rules (designer, 2026-10-20)
- Pump as a character (Roger Rabbit style)
- Receipts and invoices
- Hiring attendants (replaces skill); see Self-service pumps for the guarded version
- Police callback, Rich Guy, other special customers
- Fuel types (ethanol, diesel, premium)
- Mobile version
- Fire risk from overshoots (cut from the slice: the cleaning delay does that job)
- Bonus for completing a full 12-bar blues chorus (12 good stops in a row)
- Tony Hawk-style combo chains (variety and timing windows feed the chain)
- `[art]` Cars drive in from the end of the street (Phase 4 animation)
- Visible per-pump quirks (e.g. a pump labeled "sticky" with a shown delay): the only fair way a release delay could return
- Bribing a government inspector between days (comedy)
- Tips as a third, personal currency for the attendant's own things (company money vs. personal money)

## Done
- [x] SFX + background music only (#16), v0.14.0 (designer decision; not yet listened to)
- [x] Upgrade tree, cash-only costs (#15), v0.13.0, playtest 2026-10-19: kept
- [x] ~~Night shop with random offers and gameplay downsides (#14)~~, reworked into the tree (#15) after playtest 11
- [x] Designer tools: dev mode, tuning panel, on-the-beat clicks, audio inbox (#13), v0.11.0
- [x] Super Perfect tier and backing band (#12), v0.10.0, playtest 2026-10-19: kept
- [x] Gas Bar Blues rename and 12-bar blues (#11), v0.9.0, playtest 2026-10-19: kept
- [x] Random car arrivals and chord progression (#10), v0.8.0, playtest 2026-10-19: kept; core loop declared fun
- [x] Car-cleaning delay, merged gauge (#9), v0.7.0, playtest 2026-10-19: kept
- [x] A full day: tank, clock, end-of-day costs, cash + XP (#8, #3), v0.6.0, playtest 2026-10-19: kept
- [x] Second pump with shared combo (#4), playtest 2026-10-19: strategy emerged, kept
- [x] ~~Rusty lever delay (#2)~~, cut after playtest 2026-10-18
- [x] Combo multiplier and placeholder sound (#7), playtest 2026-10-18: both clear improvements
- [x] Pour and stop on a target (one pump) (#1), playtest 2026-10-18: core loop alive
