# GOD PUMP — Design Document

> **The game is now GOD PUMP** (2026-10-20). The overnight build plan, with the full design of the run, the
> fuel-truck bill, cards, car types and Papa's Garage, is **docs/GOD_PUMP_PLAN.md**. Sections below that
> describe the key-per-pump game are history.

> **Current phase:** 5 — Vertical Slice
> **Last updated:** 2026-10-20
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
1. **Mastery (application of an ability)**: early in a run, the player stops pumps on the exact amount; their hands decide whether they survive or thrive the first days. Later, mastery moves to *the build*: choosing what to automate and when.
2. **Advancement & completion**: the station grows within a run from hand-poured pumps to an automated machine (9 Kings arc), and run after run through XP.
3. **Comedy**: unreliable pumps, absurd customers and fire-risk mishaps interrupt the plan.

### MDA chain
| Aesthetic (feel) | ← Dynamic (emergent behavior) | ← Mechanic (rule) |
|---|---|---|
| Mastery | The player gets precise on one pump, then splits attention across many and plans the order of stops (e.g. start both, stop the smallest target first) | Hold a key to pour, release to stop. Visible number and target. Tiered scoring. Combo multiplier. Keys 1–0 for up to ten pumps. |
| Advancement | The player turns a hand-run station into an automated machine and steers its tempo | Rent each day. Cash upgrade tree (station + per pump). Self-service automation. 1x/2x/3x speed. 10-day run with a finish line. XP tree between runs (later). |
| Comedy | Customers and mishaps break the player's plan | Customer modifiers (moving target, time pressure, unreliable display, costly overshoot). Overshoots build fire risk. |

### Run arc (playtest 15, after 9 Kings)
- **Days 1–3, manual:** the player pours every pump. Manual pumps earn tips, combo and XP; precision is the difference between surviving and thriving.
- **About a third of the run in (day 3–4 of 10):** automation (self-service and its upgrades) becomes the main path; the player is mostly automated.
- **Late run:** the player steers the machine: what to build and automate next, and the game speed (1x/2x/3x). The feel to protect is the auto-battler's: "make the right decision, let it run, hope you didn't overstretch" (playtest 16). A pump can be switched back to manual to chase combos.
- **After day 10:** start a new run, or keep going in endless mode until the rent wins.
- **Tuning target (for the balance phase):** manual is clearly worth it on days 1–3; by day 4 most pumps are automated.
- **Risk:** automated days need decisions or the game becomes idle-watching. The upgrade tree must carry those decisions.

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
| ~~Overshoot builds fire risk~~ | Cut | | Cut from the slice 2026-10-19: the car-cleaning delay already makes overshoot costly |
| On-release procs | Innovation | Advancement | |
| XP from combos (second currency) | Innovation | Advancement | For permanent upgrades; added after playtest 5 |
| Shared tank + day clock as round limits | Standard | Advancement | Tank works like stamina in Bills Must Be Paid |

**Later:** calibration and inspections, police callback, special customers (Rich Guy), fuel types (ethanol, diesel, premium).
**Parked:** pump as a character, receipts and invoices, hiring attendants, mobile.
**Cut:** conspiracy-angle gag.

### Design rules
1. Upgrades cost cash (in-run) or XP (between runs), never a gameplay malus. Manual play must be clearly worth it early (tips, combo, XP only come from hand-poured pumps); automation may replace the player's hands, and should become the main path about a third of the way into a run. *(Rewritten 2026-10-19, playtest 15; before: "upgrades must never replace skill"; originally: "every upgrade must have a downside".)*
2. Every customer must change at least one variable of the micro loop. Dialogue alone is flavor.
3. The micro loop must be fun in a grey box before the build layer is built.
4. Variation must be readable. Hidden randomness in the player's own controls feels unfair; variation the player can see coming is fair.
5. The combo is global: one chain for the whole station, so a miss on any pump breaks it.

## 7. Pacing
Each run rises from one calm pump to a chaotic multi-pump peak. A round is one day (7am–11pm, 3 real minutes): calm start, rising customer pressure, a rush as the tank or the clock runs low, then a rest on the end-of-day screen (and later the shop). Target run: ~15 minutes. Slice: two runs, ~30 minutes.

## 8. Onboarding
**Story (#29):** your father passed away; at the will reading you learn he left you a run-down gas station in Saint-Clin-Clin-des-Meuh-Meuh, Québec (the Québécois "middle of nowhere"). You rebuild it, one car at a time. Told as a skippable in-engine intro (captions over the station at dawn), not a pre-rendered video: it reuses the real station, so the player first sees the place they will fix up.

Teach by doing, first 5 minutes:
1. One pump, one friendly customer, a large generous target. The player learns hold and release.
2. The second customer shows what an overshoot costs (fuel the player pays for).
3. A second pump appears; the player learns that two keys run at once.
4. First rent payment and first shop visit with two simple upgrades.
Failure is cheap early: a miss costs a little money and teaches the rule.

## 9. Vertical Slice Boundary
**Target length:** ~30 minutes (two full runs).
- **IN:** 1 to 10 pumps on keyboard; pump-feel tuning; combo multiplier; 4 customers (Regular, $20 Guy, Confused Grandpa with a moving target, Impatient Businessman with time pressure); car-cleaning delay on overshoot; rent and the cash upgrade tree (station branches + a tree per pump, cost only); self-service pumps; a small XP tree between runs; an end to a run; tutorial and the first 5 minutes; isometric impressionist art pass with day/night light and rain.
- **OUT (explicitly not building):** fire risk from overshoots (cut 2026-10-19: the cleaning delay does that job); mobile and touch; pump as animated character; receipts, paperwork, inspections; police callback and special customers; fuel types; hiring attendants; meta-progression trees; any art beyond what Phase 4 covers.

## 9b. Art Direction (Phase 4, decided 2026-10-19)
- **View:** isometric, one fixed camera on the whole station (pumps, kiosk, street).
- **Layout:** parallel lanes, one per pump. Cars enter at the top right and leave at the bottom left. Three lanes fit the starting footprint; next to it sits a weedy vacant lot with a "LOT FOR SALE" sign. The "Expand the station footprint" upgrade paves it for lanes 4 and 5.
- **Condition:** the station starts run-down: dirty walls, a boarded window, faded paint, oil stains, cracks, weeds, potholes. Later levels let the player improve its looks.
- **Name:** the player names the station; the name goes on the roadside pylon sign.
- **Decor:** a broken-down car beside the house, a tyre pile, oil barrels, a bench, a vending machine, an air pump, a phone booth.
- **Style:** clean low-poly with Hopper's *Gas* (1940) as the mood reference: a lonely roadside station, warm light against dark woods, limited palette, light doing the storytelling. *(The impressionist post-process was tried in v0.20 and removed: "it doesn't help". Art direction to be revisited later.)*
- **Time of day:** the day clock drives the light. Morning: low warm sun from the east, long shadows. Afternoon: high flat light, bleached colours. Night (toward 11 pm): pump lights and kiosk glow, deep blue sky.
- **Weather:** rain cycles: wet asphalt reflections, streaks, darker palette.
- **Readability first (affordances):** the pump display, the customer's order and the pump state must stay readable over any light or rain. Pumps in use glow; self-service pumps look different at a glance.
- **Pipeline:** Blender (`.blend` in `assets/art/source/`, `.glb` to `assets/art/export/`) → Godot; painterly look from shaders/textures in Godot. Driven by Blender scripts (`blender -b -P`) and the Godot MCP.

## 10. Risks
| Risk | Why it matters | How we test it early |
|---|---|---|
| The micro loop may not be fun alone | Everything else rests on it | Grey-box one pump first; fake feel with sound, screen shake, number ticks |
| Ten pumps may be annoying, not fun | The core hook could become chaos | Treat pump count as a ladder; playtest each step |
| Upgrade balance | Synergy is hard to get right | Few clear upgrades in the slice; bot players in headless Godot test the numbers (not the fun) |

## 10b. Naming risk (2026-10-20)
"Gaz Bar Blues" is also the title of a 2003 Québec film and a stage show (the source of some art references). Before any public release, check the title and pick a distinct name if needed. Logged, not acted on.

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
| 2026-10-19 | Fire risk from overshoots cut from the slice | The car-cleaning delay already makes overshoot costly | Designer decision |
| 2026-10-19 | Art direction: isometric, impressionist after Hopper's *Gas*, day/night light from the clock, rain cycles | Designer decision; mood matches the blues | Designer decision |
| 2026-10-19 | Run arc after 9 Kings: manual early, mostly automated by a third of the run; 1x/2x/3x speed; design rule 1 rewritten | Single fills don't matter enough to adapt per customer; manual clicking should be worth it early, then automated | Playtest 15 (#19) |
| 2026-10-19 | A run is 10 days with a finish screen | "A third of the run" needs a run length | Playtest 15 (#19) |
| 2026-10-19 | $20 Guy retired (all customers pay cash anyway) | Designer: makes no sense; new characters later | Playtest 15 (#5) |
| 2026-10-19 | Run arc kept; automated days feel like an auto-battler | Playtest 16 | Playtest 16 (#19) |
| 2026-10-19 | Endless mode after day 10; auto on/off per pump | Designer request | Playtest 16 (#20) |
| 2026-10-19 | Phase 3 complete; Phase 4 begins | Core loop fun (playtests 8–17); slice mechanics in grey | Playtest 17 |
| 2026-10-19 | Endless mode parked until balance | Designer: later | Playtest 17 (#20) |
| 2026-10-19 | Look test approved: Hopper kit, isometric composition and mood | Designer review of docs/art/look_test_*.png | #21 |
| 2026-10-19 | Impressionist post-process removed; clean low-poly for now | Designer: it doesn't help; art direction later | Review of v0.20 (#22) |
| 2026-10-19 | Parallel lanes (cars top right to bottom left), one per pump; footprint expansion needed beyond 3 pumps; decor props | Designer request | Review of v0.20 (#23) |
| 2026-10-19 | Station starts run-down (grime, potholes, faded paint); player-named pylon sign; 3 lanes plus a vacant lot for expansion | Designer request; looks upgrades come in later levels | Review of lanes kit (#23) |
| 2026-10-19 | Pump HUD is a compact card pinned to each 3D lane, in a staircase so cards never overlap or cover pumps; combo and XP move to the top right | Designer request (#25) | v0.22.0 |
| 2026-10-19 | Lanes, cars, named pylon and lane-pinned HUD kept; 10x speed added | "The art looks good"; pumps and cards read at a glance | Playtest 18 (#24, #25) |
| 2026-10-19 | Juice kept (stream, sparkle, cash pops, road cars, shake) | "Feels much better"; "the shake is fun" | Playtest 19 (#26) |
| 2026-10-19 | A customer can only be served once their car is parked at the pump; cars drive smoothly | Serving cars that hadn't arrived broke the illusion | Playtest 19 (#27) |
| 2026-10-19 | Every upgrade shows on the station (cosmetic prop) and pops in | Designer request: upgrades should look like upgrades | Playtest 19 (#27, #28) |
| 2026-10-19 | Phase 4 closed; Phase 5 (Vertical Slice) opens with the story intro and a one-pump start | Art kit, lanes, juice and props approved; the first 5 minutes are the next gap | Playtest 20 (#29, #30) |
| 2026-10-19 | The run starts with ONE pump; Pump 2 is the first PUMPS upgrade; day-1 rent $100 → $60 | Designer request; matches §8 onboarding; one pump earns about half | #30 |
| 2026-10-19 | The night shop is one Bills-style tree: the station in the centre, five branches radiating out, each pump's tree hanging off its pump node; icons baked from the 3D props; click to buy | "It looks so bad": the shop should be a beautiful branching tree like Bills | Playtest 21 (#31) |
| 2026-10-19 | Fuel is ordered each night (default: fill-up as far as cash goes); leftover fuel carries over; the day summary charges rent only; no fuel means the day closes at once | Fuel now competes with upgrades for cash: a real decision between rounds | Playtest 21 (#32) |
| 2026-10-19 | The night shop has two tabs: UPGRADE TREE (station-wide branches) and YOUR STATION (cards on each pump with its own upgrades; a card to build the next pump or expand the lot); the day HUD hides at night | "A branch for each pump is not the right design": pumps are bought and improved on the station | Playtest 22 (#33) |
| 2026-10-20 | Balance pass: wholesale fuel 70% (was 80%), rent +$32 a day (was $40), self-serve speed 75% (was 50%), Self-service $120 (was $200) | Simulator, even tier split: best strategy 85% survival, hybrid 74%, hoarding 0.4%; first self-serve pump around day 4 | docs/balance/REPORT.md (#34) |
| 2026-10-20 | Days last 15 s (7 to 11 AM); an HOURS branch (Thermos of coffee, Mom covers lunch, Evening permit, Cousin Réjean on nights) stretches them to 60 s; a game hour is always 3.75 s; the pylon shows the hours; rent $20 + $6 a day, prices halved | "Days are too long" (Bills: 15 s to 45 s). Story: Dad only opened mornings; after 11 he went fishing. Simulator: three routes survive 68–77% | Playtest 23 (#35) |
| 2026-10-20 | Pivot candidate under test: the god pump. A giant nozzle above a top-down lot pours onto cars driving around; cars settle only when full (you can only overfill), the overshoot picks the tier and its animation, coins fly to the cash; gas on the floor is wasted; 15 s rounds; built as a separate greybox scene | Designer idea from Bills' table-top: turns waiting into aiming and makes multi-car mastery possible | #36 |
| 2026-10-20 | God pump scoring: a car leaves once 80% full; the tip grows toward 100% (topped off with no spill pays most); overflow spills as wasted gas; a round ends when its gas runs out (the clock is a safeguard); cars move in readable patterns (loop, shuttle, park-and-go) | "Aiming is much better"; exact-stop tiers fight continuous juggling; unclear what a Perfect achieved | God-pump playtest 1 (#36) |
| 2026-10-20 | The god pump is the game (pour from the sky onto cars on the lot); the key-per-pump game is retired once its systems move over | "God Pump is 1000% the right direction"; aiming, juggling and the cash drop tested well | God-pump playtests 1–3 (#36) |
| 2026-10-20 | Art direction: pixel art drawn as code (claude-pxl), styled after late-80s small-town Québec: plaid flannel, denim, browns and beiges, an aluminium dépanneur storefront, red curbs, boxy sedans with square headlights | "The pixel-art style is working"; designer's reference photo | #36 |
\n| 2026-10-20 | Art references added: red neon (a GAZ BAR sign), a faded-orange 70s hatchback at an old pump with a mechanical counter, the dépanneur interior (counter, chip racks, shelves of oil and mugs, regulars on chairs). In game: a flickering red GAZ BAR neon on the store roof, the orange hatchback | Designer's reference photos | #36 |
| 2026-10-20 | The god pump is the main scene Godot runs; the key-per-pump game stays in scenes/greybox until its systems move over | Designer couldn't find the new version when pressing Play | #36 |
| 2026-10-20 | God pump v0.32: a high-angle three-quarter camera (not isometric); cars get a roof funnel and a dial gauge; a real nozzle whose lever the hand squeezes to pour; a vintage pump (dial = the round's gas) with its hose to your hand; tips go to a jar and sales pile up as bills (no running counter); the regulars sit by the dépanneur and react in Québécois; the neon flashes like a pinball machine on Good or better; spills stay all round; a clock and an OUVERT/FERMÉ sign (7 h to 13 h, round length unchanged); music back | Designer's round-4 requests | God-pump round 4 (#36) |
| 2026-10-20 | HD-2D try (default view; I cycles HD-2D, three-quarter pixel, flat): the same high three-quarter camera on a lit 3D scene built from the claude-pxl textures and sprites; cars as 16 stacked flat slices that catch light and cast shadows; a low warm sun, SSAO, emissive neon with bloom and a red light on the lot, tilt-shift depth of field, a vignette. Also: no tip when overfilled, the nozzle without the hand, no funnels, cash lies 3 s longer | "The three quarter angle is wonderful"; "not happy with the aesthetic, I would like to try HD-2D" | God-pump playtest 5 (#36) |
| 2026-10-20 | Title GOD PUMP. The bill is the fuel truck (price +12% a delivery, a choice of 1 of 3 premium cards per delivery); the clock limits the day; a run ends bankrupt or on day 50 (Dad drives in); drone nozzles are the automation; car types unlock over time; XP buys nozzles, bling and perks; key-per-pump game retired | Designer's overnight brief | docs/GOD_PUMP_PLAN.md |
