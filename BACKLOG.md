# STOP. THE. PUMP. — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [ ] `[standard]` **A full day: tank, clock, end-of-day costs, cash + XP** (#8, continues #3)
  As a player, I want each day to end when my tank or the clock runs out and then pay my costs so that every day feels like progress (serves: Advancement).
  - Given the tank runs empty mid-pour, Then the pour stops at once.
  - Given the clock reaches 11pm or the tank is empty, When all pumps are idle, Then the end-of-day screen shows earnings, refill cost, rent and net cash.
  - Given a Perfect at combo x3, Then cash gets the sale + $5 tip and XP gets 100 x 3.
- [ ] `[innovation]` **Overshoot cleaning delay** (next hypothesis, judged against #8)
  As a player, I want an overshoot to lock the pump for a few seconds while I clean the car so that overshooting costs time (serves: Comedy, Mastery).
  - Given I overshoot by more than the OK window, When the pump stops, Then that pump is out of service for a few seconds.
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
- Bribing a government inspector between days (comedy)

## Done
- [x] Second pump with shared combo (#4), playtest 2026-10-19: strategy emerged, kept
- [x] ~~Rusty lever delay (#2)~~, cut after playtest 2026-10-18
- [x] Combo multiplier and placeholder sound (#7), playtest 2026-10-18: both clear improvements
- [x] Pour and stop on a target (one pump) (#1), playtest 2026-10-18: core loop alive
