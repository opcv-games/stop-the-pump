# STOP. THE. PUMP. — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [ ] `[standard]` **Fuel economy for one customer** (#3)
  As a player, I want to earn the fuel price plus a tip so that precision and volume both pay (serves: Advancement).
  - Given I overshoot the target, When the customer pays, Then they pay only for the requested amount and I absorb the extra fuel cost.
  - Given I undershoot the target, When the customer pays, Then I earn for the amount sold, no tip, and the customer asks for a top-up.
- [ ] `[innovation]` **Second pump (hold 1 and 2 independently)** (#4)
  As a player, I want to run two pumps at once so that I must split my attention (serves: Mastery).
  - Given two customers are waiting, When I hold key 1 and key 2 together, Then both amounts climb independently.
  - Given I release key 1 only, Then pump 1 stops and pump 2 continues.
- [ ] `[innovation]` **Moving-target customer (Confused Grandpa)** (#5)
  As a player, I want a customer who changes their order mid-pour so that I stay alert (serves: Comedy, Mastery).
  - Given a customer asks for $50, When the pour passes $30, Then the target changes and the display updates.
- [ ] `[tech]` **Bot player harness** (#6)
  As the designer, I want scripted bots to play headless so that I can test economy and balance numbers.
  - Given a bot with fixed reaction time, When it plays 100 rounds, Then the run produces a report of income, rent paid and failures.

## Next (likely, not committed)
- [ ] Rent and round structure (8–10 rounds). Candidate round limiter: **tank size as stamina**, the round ends when the tank runs dry (like stamina in Bills Must Be Paid)
- [ ] Fire risk from overshoots
- [ ] Upgrade shop with downsides
- [ ] Customer queue and patience timer
- [ ] Impatient Businessman (time pressure) and $20 Guy (costly overshoot)
- [ ] Tutorial first 5 minutes
- [ ] `[juice]` Musical meter clicks: accent every 4th dollar like a beat (playtest 3: clicks are too fast to count at $4/s, so this needs rethinking)

## Later (deliberately vague)
- Permanent upgrades between runs
- Ten-pump ladder tuning
- Calibration and inspections
- Gas price variation
- On-release procs

## Parked (good ideas that are out of scope until the core loop is proven)
- Pump as a character (Roger Rabbit style)
- Receipts and invoices
- Hiring attendants (replaces skill)
- Police callback, Rich Guy, other special customers
- Fuel types (ethanol, diesel, premium)
- Mobile version
- Visible per-pump quirks (e.g. a pump labeled "sticky" with a shown delay): the only fair way a release delay could return
- Experience as a second currency earned from chains (revisit after the economy is proven)

## Done
- [x] ~~Rusty lever delay (#2)~~, cut after playtest 2026-10-18
- [x] Combo multiplier and placeholder sound (#7), playtest 2026-10-18: both clear improvements
- [x] Pour and stop on a target (one pump) (#1), playtest 2026-10-18: core loop alive
