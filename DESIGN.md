# Gas Bar Blues — Design Document

> **Current phase:** 3 — Ugly Prototype
> **Last updated:** 2026-10-18
> This file is the Committee's memory. Read it before every Godot or Blender action. Update it after every approved decision.

## 1. Pitch
**Gas Bar Blues is a 15-minute roguelite for Mac and PC where you run ever more fuel pumps at once, stopping each on the exact amount to earn tips and margins that pay your rent, while absurd customers and your own overshoots set the station on fire.**

<details><summary>Pitch iterations</summary>

| Round | Pitch | What changed |
|---|---|---|
| 1 | A timing game where you stop a pump on the exact dollar amount, upgrading your unreliable pump between customers. | First idea |
| 2 | A 5-minute roguelite where you hold pump levers and release them at exact dollar amounts to pay rent. | Run length, rent, hold mechanic |
| 3 | A 5-minute roguelite where you juggle ever more fuel pumps at once, releasing each on the exact amount to pay rent, while absurd customers and your own overshoots set the station on fire. | Multi-pump juggling, customer chaos, fire risk |
| 4 | See above. | Mac/PC only, 15-minute run, economy = fuel margin + tips |
| 5 | Same pitch, new title: **Gas Bar Blues** (working title was STOP. THE. PUMP.) | The blues gives the game its mood; good stops play a 12-bar blues |

</details>

## 2. MDA
### Aesthetics (target forms of fun, ranked)
1. **Mastery (application of an ability)**: the player stops a pump on the exact amount, then loses and immediately wants another go at the pump that beat them.
2. **Advancement & completion**: the station grows run after run (more pumps, better equipment) to survive rising rent.
3. **Comedy**: unreliable pumps, absurd customers and fire-risk mishaps interrupt the plan.

### MDA chain
| Aesthetic (feel) | ← Dynamic (emergent behavior) | ← Mechanic (rule) |
|---|---|---|
| Mastery | The player gets precise on one pump, then splits attention across many and plans the order of stops (e.g. start both, stop the smallest target first) | Hold a key to pour, release to stop. Visible number and target. Tiered scoring. Combo multiplier. Keys 1–0 for up to ten pumps. |
| Advancement | The player builds a better station to survive rising rent | Rent each round. Upgrade shop. Permanent upgrades. Every helpful upgrade has a downside. On-release procs. |
| Comedy | Customers and mishaps break the player's plan | Customer modifiers (moving target, time pressure, unreliable display, costly overshoot). Overshoots build fire risk. |

## 3. Core Loops
- **Micro (1–5 s):** hold a key to pour, release at the target. Closer means a better tier and a bigger tip.
- **Mid (15–30 s):** a customer arrives with a modifier; the player serves them, often alongside other pumps.
- **Macro (~90 s per round, 8–10 rounds per ~15-minute run):** serve customers, restock fuel, pay rent, shop for upgrades.
- **Meta (between runs):** permanent upgrades (e.g. calibrated pumps, an extra starting pump).
- **How macro feeds back into micro:** upgrades add pumps and change how each pump feels (precision, drift, procs), so the same micro action is played differently each run.

### Economy (revised after playtest 5)
Two currencies, kept separate so the fiction holds (a customer doesn't pay more because the previous one got a Perfect):
- **Cash, earned at the pump:** the full sale (never more than the customer asked for) + a tip by tier (Perfect $5, Good $2, OK/Miss $0). The combo does **not** change cash.
- **XP, earned from skill:** tier points (Perfect 100, Good 50, OK 10) × the combo multiplier. Kept across days and runs; spent on permanent upgrades (later).
- **Money out, between days only:** refill the fuel used at wholesale (80% of the $2/L pump price) and pay rent (grows each day). Later: inspections, pump calibration, bribing an inspector.
- **The day:** the station is open 7am–11pm, which runs for 3 real minutes. One shared tank (400 L) feeds every pump. The day ends when the clock runs out or the tank is empty. If cash is below zero after costs, the run ends (evicted).
- **Overshoot:** the customer pays only for the amount requested; the extra fuel drains the tank (less fuel left to sell) and is paid for at refill. Next hypothesis: a car-cleaning delay as an extra time penalty.
- **Undershoot:** the player sells less and gets no tip unless the stop is Perfect. The top-up request waits for customer patience.
- **Scoring tiers:** Super Perfect / Perfect / Good / OK / Miss. Thresholds are tunable (±$0.03 / ±$0.10 / ±$0.50 / ±$1.00). Super Perfect = the best possible frame at 60 fps; the display snaps to the exact target. Super Perfect pays an $8 tip and 200 XP.

## 4. Genre, Mood & Audience
- **Genre / comparables:** short-run roguelite with a number-go-up build layer. Balatro, Bills Must Be Paid, 9 Kings, Ball x Pit, sports management games.
- **Mood:** frantic, absurd, satisfying, with the blues of a lonely late shift.
- **For:** fans of short roguelite runs and build-crafting, playing on Mac or PC in ~15-minute sittings, who want depth under a simple surface.
- **Not for:** players who want a story, mobile play, or the strict precision of a rhythm game.

## 5. Uniqueness
Timing-precision skill stacked with attention-splitting across many pumps, inside a roguelite economy. The theme (a gas pump) produces the mechanic directly: a number climbs and you must stop it on a target.

## 6. Feature Split (60 / 40)
| Feature | Type | Serves | Notes |
|---|---|---|---|
| Hold key to pour, release to stop | Standard | Mastery | |
| Visible climbing number and target | Standard | Mastery | |
| Tiered tips | Standard | Mastery | |
| Rent each round, game over if unpaid | Standard | Advancement | |
| Upgrade shop between rounds | Standard | Advancement | |
| Permanent upgrades between runs | Standard | Advancement | |
| Customer queue with patience timer | Standard | Mastery | |
| Tutorial first customer | Standard | Onboarding | |
| ~~Rusty lever (release delay)~~ | Cut | Mastery | Cut after playtest 3: a fixed delay is a constant offset learned once; a random one feels unfair |
| Combo multiplier | Innovation | Mastery | Kept after playtest 2 |
| Multi-pump juggling (up to 10 keys) | Innovation | Mastery | Pump count is a difficulty ladder. Kept after playtest 4: it creates strategy, which single-pump play lacked |
| Customer modifiers | Innovation | Comedy, Mastery | Every customer must change a micro-loop variable |
| Upgrades with built-in downsides | Innovation | Mastery, Advancement | e.g. "let it run" drifts and loses precision |
| Overshoot builds fire risk | Innovation | Comedy, Advancement | |
| On-release procs | Innovation | Advancement | |
| XP from combos (second currency) | Innovation | Advancement | For permanent upgrades; added after playtest 5 |
| Shared tank + day clock as round limits | Standard | Advancement | Tank works like stamina in Bills Must Be Paid |

**Later:** calibration and inspections, police callback, special customers (Rich Guy), fuel types (ethanol, diesel, premium).
**Parked:** pump as a character, receipts and invoices, hiring attendants, mobile.
**Cut:** conspiracy-angle gag.

### Design rules
1. Upgrades cost cash (in-run) or XP (between runs), never a gameplay malus. They must never replace skill (no auto-stop, no aim assist). Difficulty rises through rent and customers instead. *(Rewritten 2026-10-19, playtest 11; was "every upgrade must have a downside".)*
2. Every customer must change at least one variable of the micro loop. Dialogue alone is flavor.
3. The micro loop must be fun in a grey box before the build layer is built.
4. Variation must be readable. Hidden randomness in the player's own controls feels unfair; variation the player can see coming is fair.
5. The combo is global: one chain for the whole station, so a miss on any pump breaks it.

## 7. Pacing
Each run rises from one calm pump to a chaotic multi-pump peak. A round is one day (7am–11pm, 3 real minutes): calm start, rising customer pressure, a rush as the tank or the clock runs low, then a rest on the end-of-day screen (and later the shop). Target run: ~15 minutes. Slice: two runs, ~30 minutes.

## 8. Onboarding
Teach by doing, first 5 minutes:
1. One pump, one friendly customer, a large generous target. The player learns hold and release.
2. The second customer shows what an overshoot costs (fuel the player pays for).
3. A second pump appears; the player learns that two keys run at once.
4. First rent payment and first shop visit with two simple upgrades.
Failure is cheap early: a miss costs a little money and teaches the rule.

## 9. Vertical Slice Boundary
**Target length:** ~30 minutes (two full runs).
- **IN:** 1 to 10 pumps on keyboard; pump-feel tuning; combo multiplier; 4 customers (Regular, $20 Guy, Confused Grandpa with a moving target, Impatient Businessman with time pressure); fire risk from overshoots; rent, shop and about 8 upgrades with downsides; a small set of permanent upgrades; tutorial and the first 5 minutes.
- **OUT (explicitly not building):** mobile and touch; pump as animated character; receipts, paperwork, inspections; police callback and special customers; fuel types; hiring attendants; meta-progression trees; any art beyond what Phase 4 covers.

## 10. Risks
| Risk | Why it matters | How we test it early |
|---|---|---|
| The micro loop may not be fun alone | Everything else rests on it | Grey-box one pump first; fake feel with sound, screen shake, number ticks |
| Ten pumps may be annoying, not fun | The core hook could become chaos | Treat pump count as a ladder; playtest each step |
| Upgrade balance | Synergy is hard to get right | Few clear upgrades in the slice; bot players in headless Godot test the numbers (not the fun) |

## 11. Decision Log
| Date | Decision | Why | Evidence (playtest / issue) |
|---|---|---|---|
| 2026-10-18 | Hold-to-pour input, keyboard keys 1–0 | Tactile; scales to many pumps on PC | Phase 1 interview |
| 2026-10-18 | Mac and PC only; mobile parked | Keyboard-first design | Phase 1 interview |
| 2026-10-18 | Tiered scoring (Perfect/Good/OK/Miss) | Readable at a glance; easy for procs | Phase 1 interview |
| 2026-10-18 | Economy = fuel margin + tips − restock − rent; overshoot is eaten by player | Rewards volume and precision | Phase 1 interview |
| 2026-10-18 | Run length ~15 minutes | Player preference | Phase 1 interview |
| 2026-10-18 | Keep flow rate at $4/s and tier windows ±0.10/0.50/1.00 | Misses felt readable; slower would be boring | Playtest 1 (#1) |
| 2026-10-18 | Grey one-pump loop kept | Player wanted another go to hit more Perfects | Playtest 1 (#1) |
| 2026-10-18 | Combo multiplier (x1–x5, resets on OK/Miss) kept | Losing a x5 combo created real pressure; each stop now has stakes | Playtest 2 (#7) |
| 2026-10-18 | Placeholder sound kept, incl. a click per dollar | Clicks help timing; sound and combo each improved the loop on their own | Playtest 2 (#7) |
| 2026-10-18 | Rusty lever cut | Fixed delay = constant offset, learned once; random delay = unfair. Depth must come from juggling pumps and customer modifiers | Playtest 3 (#2) |
| 2026-10-19 | Second pump kept; combo stays global across pumps | Juggling produced a strategy (start both, stop smallest target first), which is a new skill; more demanding but more rewarding | Playtest 4 (#4) |
| 2026-10-19 | Two currencies: cash (sale + tier tip) and XP (tier points × combo) | Combo-boosted tips broke the fiction; XP gives combos a purpose (permanent upgrades) | Playtest 5 (#3) |
| 2026-10-19 | Costs land between days (refill + rent), not per stop | Payout at the pump should be the full amount; spending happens at day end | Playtest 5 (#3) |
| 2026-10-19 | A day is 7am–11pm in 3 minutes; ends on clock or empty tank (400 L) | Gives each round a shape and makes overshoot visible as wasted tank | Playtest 5 (#8) |
| 2026-10-19 | Full day kept (v0.6.0) | Tank and clock end close together; day 1 felt rewarding | Playtest 6 (#8) |
| 2026-10-19 | Car-cleaning delay kept (4 s past the OK window) | Made play more attentive; overshoot finally feels costly | Playtest 7 (#9) |
| 2026-10-19 | Random arrivals (1–5 s) kept | Rhythm can't be memorized; simultaneous cars are fine | Playtest 8 (#10) |
| 2026-10-19 | Core loop declared genuinely fun (Phase 3 gate) | Player: "clearly becoming more and more fun"; playtests 1–8 | Playtest 8 |
| 2026-10-19 | Game renamed Gas Bar Blues; music is a 12-bar blues | The blues gives the game its mood and ties the chord progression to the theme | Playtest 8 |
| 2026-10-19 | Cash buys run upgrades every night (random offers, Balatro); XP buys permanent upgrades between runs (tree, Bills) | Random offers give run variety; a tree gives long-term goals | Designer decision |
| 2026-10-19 | First cash upgrades: bigger tank, turbo nozzle, flyers, extra pump, squeegee, tip jar, bluesy radio, each with a downside | Design rule 1 | Designer decision (#14) |
| 2026-10-19 | Upgrades cost cash only, no gameplay downside; rule 1 rewritten | Downsides felt like punishments; Bills-style pure upgrades, with difficulty from rising rent | Playtest 11 (#14) |
| 2026-10-19 | Cash shop becomes a 5-branch upgrade tree (Marketing, Pumps, Tank, Service, Vibe) | Designer prefers a Bills-style tree: a plan to work toward | Playtest 11 (#15) |
| 2026-10-19 | Backing track "Roadside At Two" (92 BPM, 46 bars, B♭/D minor); stops play B♭–D–F | Real music; notes chosen to sit over the whole track | Designer asset (#15) |
| 2026-10-19 | Upgrade tree kept | "Just one more turn" planning across days | Playtest 12 (#15) |
| 2026-10-19 | Music is plain background music + SFX; no tier notes, chord tracking or beat-synced clicks | Designer: the music engineering isn't wanted | Playtest 12 (#16) |
| 2026-10-19 | Balance is out of scope until the slice's systems exist | Designer decision | Playtest 12 |
| 2026-10-19 | Pump upgrades become a tree per pump | Designer: each pump should grow on its own | Playtest 13 (#17) |
