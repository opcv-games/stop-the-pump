# Gas Bar Blues — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [ ] `[innovation]` **Super Perfect tier and backing band** (#12, v0.10.0, awaiting playtest)
  - Given a target of $20.00, When the pump stops at $20.03, Then the tier is Super Perfect and the display shows $20.00.
  - Given the band is on bar 5, When I stop with a Good, Then one note of D7 plays.
- [ ] `[innovation]` **Moving-target customer (Confused Grandpa)** (#5)
  As a player, I want a customer who changes their order mid-pour so that I stay alert (serves: Comedy, Mastery).
  - Given a customer asks for $50, When the pour passes $30, Then the target changes and the display updates.
- [ ] `[tech]` **Bot player harness** (#6)
  As the designer, I want scripted bots to play headless so that I can test economy and balance numbers.
  - Given a bot with fixed reaction time, When it plays 100 rounds, Then the run produces a report of income, rent paid and failures.

## Next (likely, not committed)
- [ ] Run structure: 8–10 days with rising rent
- [ ] `[juice]` Combo gauge catches fire at high combos
- [ ] Fire risk from overshoots
- [ ] Upgrade shop with downsides
- [ ] Customer queue and patience timer
- [ ] Impatient Businessman (time pressure) and $20 Guy (costly overshoot)
- [ ] Tutorial first 5 minutes
- [ ] `[juice]` Musical meter clicks: accent every 4th dollar like a beat (playtest 3: clicks are too fast to count at $4/s, so this needs rethinking)

## Later (deliberately vague)
- Permanent upgrades between runs
- Ten-pump ladder tuning
- Between-day costs: inspections, pump calibration
- Spending XP on permanent upgrades
- Marketing upgrade branch: more cars at once; shorter min–max wait between cars
- Rethink the gauge: the player has no time to watch it mid-day (playtest 7)
- Shop upgrade ideas: bigger tank (downside: bigger refill bill), faster pour (built-in downside: harder to stop precisely)
- Gas price variation
- On-release procs

## Parked (good ideas that are out of scope until the core loop is proven)
- Pump as a character (Roger Rabbit style)
- Receipts and invoices
- Hiring attendants (replaces skill)
- Police callback, Rich Guy, other special customers
- Fuel types (ethanol, diesel, premium)
- Mobile version
- Bonus for completing a full 12-bar blues chorus (12 good stops in a row)
- `[art]` Cars drive in from the end of the street (Phase 4 animation)
- Visible per-pump quirks (e.g. a pump labeled "sticky" with a shown delay): the only fair way a release delay could return
- Bribing a government inspector between days (comedy)
- Tips as a third, personal currency for the attendant's own things (company money vs. personal money)

## Done
- [x] Gas Bar Blues rename and 12-bar blues (#11), v0.9.0, playtest 2026-10-19: kept
- [x] Random car arrivals and chord progression (#10), v0.8.0, playtest 2026-10-19: kept; core loop declared fun
- [x] Car-cleaning delay, merged gauge (#9), v0.7.0, playtest 2026-10-19: kept
- [x] A full day: tank, clock, end-of-day costs, cash + XP (#8, #3), v0.6.0, playtest 2026-10-19: kept
- [x] Second pump with shared combo (#4), playtest 2026-10-19: strategy emerged, kept
- [x] ~~Rusty lever delay (#2)~~, cut after playtest 2026-10-18
- [x] Combo multiplier and placeholder sound (#7), playtest 2026-10-18: both clear improvements
- [x] Pour and stop on a target (one pump) (#1), playtest 2026-10-18: core loop alive
