# STOP. THE. PUMP. — Design Document

> **Current phase:** 3 — Ugly Prototype
> **Last updated:** 2026-10-18
> This file is the Committee's memory. Read it before every Godot or Blender action. Update it after every approved decision.

## 1. Pitch
**STOP. THE. PUMP. is a 15-minute roguelite for Mac and PC where you run ever more fuel pumps at once, stopping each on the exact amount to earn tips and margins that pay your rent, while absurd customers and your own overshoots set the station on fire.**

<details><summary>Pitch iterations</summary>

| Round | Pitch | What changed |
|---|---|---|
| 1 | A timing game where you stop a pump on the exact dollar amount, upgrading your unreliable pump between customers. | First idea |
| 2 | A 5-minute roguelite where you hold pump levers and release them at exact dollar amounts to pay rent. | Run length, rent, hold mechanic |
| 3 | A 5-minute roguelite where you juggle ever more fuel pumps at once, releasing each on the exact amount to pay rent, while absurd customers and your own overshoots set the station on fire. | Multi-pump juggling, customer chaos, fire risk |
| 4 (final) | See above. | Mac/PC only, 15-minute run, economy = fuel margin + tips |

</details>

## 2. MDA
### Aesthetics (target forms of fun, ranked)
1. **Mastery (application of an ability)**: the player stops a pump on the exact amount, then loses and immediately wants another go at the pump that beat them.
2. **Advancement & completion**: the station grows run after run (more pumps, better equipment) to survive rising rent.
3. **Comedy**: unreliable pumps, absurd customers and fire-risk mishaps interrupt the plan.

### MDA chain
| Aesthetic (feel) | ← Dynamic (emergent behavior) | ← Mechanic (rule) |
|---|---|---|
| Mastery | The player learns each pump's lag, gets precise on one, then splits attention across many | Hold a key to pour, release to stop. Visible number and target. Rusty lever release delay. Tiered scoring. Keys 1–0 for up to ten pumps. |
| Advancement | The player builds a better station to survive rising rent | Rent each round. Upgrade shop. Permanent upgrades. Every helpful upgrade has a downside. On-release procs. |
| Comedy | Customers and mishaps break the player's plan | Customer modifiers (moving target, time pressure, unreliable display, costly overshoot). Overshoots build fire risk. |

## 3. Core Loops
- **Micro (1–5 s):** hold a key to pour, release at the target. Closer means a better tier and a bigger tip.
- **Mid (15–30 s):** a customer arrives with a modifier; the player serves them, often alongside other pumps.
- **Macro (~90 s per round, 8–10 rounds per ~15-minute run):** serve customers, restock fuel, pay rent, shop for upgrades.
- **Meta (between runs):** permanent upgrades (e.g. calibrated pumps, an extra starting pump).
- **How macro feeds back into micro:** upgrades add pumps and change how each pump feels (precision, drift, procs), so the same micro action is played differently each run.

### Economy
- **Money in:** fuel sold (amount × pump price) + tips (by accuracy tier).
- **Money out:** fuel restock after each round (wholesale price varies), rent each round, overshoot losses, fire costs.
- **Overshoot:** the customer pays only for the amount requested. The extra fuel is the player's loss and builds fire risk.
- **Undershoot:** the player sells less, gets no tip, and the customer may ask for a top-up, which eats patience time.
- **Scoring tiers:** Perfect / Good / OK / Miss. Thresholds are tunable values (starting guess: ±$0.10 / ±$0.50 / ±$1.00).

## 4. Genre, Mood & Audience
- **Genre / comparables:** short-run roguelite with a number-go-up build layer. Balatro, Bills Must Be Paid, 9 Kings, Ball x Pit, sports management games.
- **Mood:** frantic, absurd, satisfying.
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
| Rusty lever (release delay) | Innovation | Mastery | |
| Multi-pump juggling (up to 10 keys) | Innovation | Mastery | Pump count is a difficulty ladder |
| Customer modifiers | Innovation | Comedy, Mastery | Every customer must change a micro-loop variable |
| Upgrades with built-in downsides | Innovation | Mastery, Advancement | e.g. "let it run" drifts and loses precision |
| Overshoot builds fire risk | Innovation | Comedy, Advancement | |
| On-release procs | Innovation | Advancement | |

**Later:** calibration and inspections, police callback, special customers (Rich Guy), fuel types (ethanol, diesel, premium).
**Parked:** pump as a character, receipts and invoices, hiring attendants, mobile.
**Cut:** conspiracy-angle gag.

### Design rules
1. Every upgrade that helps the player must cost them something. Upgrades never replace skill.
2. Every customer must change at least one variable of the micro loop. Dialogue alone is flavor.
3. The micro loop must be fun in a grey box before the build layer is built.

## 7. Pacing
Each run rises from one calm pump to a chaotic multi-pump peak. Within a round: calm start, rising customer pressure, a rush at the end, then a rest at the shop. Target run: ~15 minutes. Slice: two runs, ~30 minutes.

## 8. Onboarding
Teach by doing, first 5 minutes:
1. One pump, one friendly customer, a large generous target. The player learns hold and release.
2. The rusty lever delay is felt on the second customer; the game shows the overshoot and what it cost.
3. A second pump appears; the player learns that two keys run at once.
4. First rent payment and first shop visit with two simple upgrades.
Failure is cheap early: a miss costs a little money and teaches the rule.

## 9. Vertical Slice Boundary
**Target length:** ~30 minutes (two full runs).
- **IN:** 1 to 10 pumps on keyboard; rusty lever and pump-feel tuning; 4 customers (Regular, $20 Guy, Confused Grandpa with a moving target, Impatient Businessman with time pressure); fire risk from overshoots; rent, shop and about 8 upgrades with downsides; a small set of permanent upgrades; tutorial and the first 5 minutes.
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
