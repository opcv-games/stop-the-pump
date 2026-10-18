# STOP. THE. PUMP. — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestone: **Vertical Slice** (see DESIGN.md §9)

## Now (committed, top = highest priority)
- [ ] `[innovation]` **Pour and stop on a target (one pump)**
  As a player, I want to hold a key to pour fuel and release it on a target amount so that I feel skillful (serves: Mastery).
  - Given a customer asks for $20.00 and the pump is idle, When I hold the pour key, Then the displayed amount climbs continuously.
  - Given the amount is climbing, When I release the key, Then the pump stops and the result is scored as Perfect, Good, OK or Miss by distance from the target.
- [ ] `[innovation]` **Rusty lever delay**
  As a player, I want the pump to keep pouring briefly after I release so that I must anticipate the stop (serves: Mastery).
  - Given the lever delay is 0.4 s, When I release at $19.50, Then the final amount is higher than $19.50 by the fuel poured during the delay.
  - Given the delay value is exposed as a tunable, When I change it in the editor, Then the pump feel changes without code changes.
- [ ] `[standard]` **Fuel economy for one customer**
  As a player, I want to earn the fuel price plus a tip so that precision and volume both pay (serves: Advancement).
  - Given I overshoot the target, When the customer pays, Then they pay only for the requested amount and I absorb the extra fuel cost.
  - Given I undershoot the target, When the customer pays, Then I earn for the amount sold, no tip, and the customer asks for a top-up.
- [ ] `[innovation]` **Second pump (hold 1 and 2 independently)**
  As a player, I want to run two pumps at once so that I must split my attention (serves: Mastery).
  - Given two customers are waiting, When I hold key 1 and key 2 together, Then both amounts climb independently.
  - Given I release key 1 only, Then pump 1 stops and pump 2 continues.
- [ ] `[innovation]` **Moving-target customer (Confused Grandpa)**
  As a player, I want a customer who changes their order mid-pour so that I stay alert (serves: Comedy, Mastery).
  - Given a customer asks for $50, When the pour passes $30, Then the target changes and the display updates.
- [ ] `[tech]` **Bot player harness**
  As the designer, I want scripted bots to play headless so that I can test economy and balance numbers.
  - Given a bot with fixed reaction time, When it plays 100 rounds, Then the run produces a report of income, rent paid and failures.

## Next (likely, not committed)
- [ ] Rent and round structure (8–10 rounds)
- [ ] Fire risk from overshoots
- [ ] Upgrade shop with downsides
- [ ] Customer queue and patience timer
- [ ] Impatient Businessman (time pressure) and $20 Guy (costly overshoot)
- [ ] Tutorial first 5 minutes

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

## Done
-
