# Gas Bar Blues — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [x] `[art]` **Look test: Hopper station kit in Blender, isometric renders at morning, afternoon, night** (#21, approved)
- [x] `[art]` **Look test in Godot: isometric 3D station behind the HUD, light from the day clock, rain** (#22, v0.20.0; painterly filter rejected)
- [x] `[art]` **Lanes kit (Blender): parallel lanes, modular pump/island/car props, footprint expansion, decor** (#23, approved)
- [ ] `[art]` **Lanes in Godot: remove the painterly filter, one lane per pump, cars drive in top right and out bottom left, footprint expansion upgrade (paves the vacant lot), player names the station on the pylon** (#24, v0.21.0, awaiting playtest)
- [ ] `[art]` **Anchor each pump's HUD (order, meter, bubble, result) to its 3D lane; drop the grey panels and 2D cars** (#25, v0.22.0, awaiting playtest)
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
- [ ] `[tech]` **Bot player harness** (#6)
  As the designer, I want scripted bots to play headless so that I can test economy and balance numbers.
  - Given a bot with fixed reaction time, When it plays 100 rounds, Then the run produces a report of income, rent paid and failures.

## Next (likely, not committed)
- [ ] `[juice]` Combo gauge catches fire at high combos
- [ ] Upgrade shop with downsides
- [ ] Customer queue and patience timer
- [ ] Impatient Businessman (time pressure) and $20 Guy (costly overshoot)
- [ ] Tutorial first 5 minutes
- [ ] `[juice]` Musical meter clicks: accent every 4th dollar like a beat (playtest 3: clicks are too fast to count at $4/s, so this needs rethinking)

## Later (deliberately vague)
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
