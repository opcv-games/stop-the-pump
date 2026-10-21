# GOD PUMP — the overnight build plan (2026-10-20)

> Written before the overnight batch, from the designer's brief. This is the contract for the night:
> what gets built, in what order, and the decisions taken on the designer's behalf (marked **DECIDED**,
> to review in the morning). DESIGN.md stays the long-term memory; this file is the plan.

## The game in one line
**GOD PUMP: you inherit your late father's run-down gaz bar in Saint-Clin-Clin-des-Meuh-Meuh, Québec, and
pour gas from the sky onto the cars driving around your lot, topping each one off on the dollar, until
the fuel truck's bills catch up with you, or until day 50, when an old car pulls in.**

## Core loop
- **Day** (the clock is the limit): the store opens at 7 h and closes at the closing hour (13 h to start;
  the HOURS branch pushes it to 23 h). A game hour lasts 4.5 s, so day 1 is 27 s and a full day 72 s.
  Cars flow along the road (both ways); some pull in and drive around the lot. Hold the mouse to pour
  from the God Pump; a car leaves once it is 80% full and the stream moves off it.
- **Grades** (per car, on the fill when the stream leaves it):

  | Grade | Fill | Tip | Regulars |
  |---|---|---|---|
  | SUPER "TOPPED OFF!" | 99.5%+, no spill | max + bonus | arms up, cheer |
  | PERFECT | 97%+ | high | applause |
  | GOOD | 90%+ | some | nod |
  | OK | 80%+ | none | — |
  | MISS | overfilled (spill > $0.25), or still under 80% at closing | none, combo breaks | "AYOYE" |

- **Night**: the day report, then the night screen: the upgrade tree (cash, always there), the fuel
  truck, then open the next day.
- **The bill = the fuel truck (DECIDED).** The station's tank holds about a week of gas. Gas used by
  cars, by drones and by spills all comes out of it (spills cut your week short: skill matters). At
  night you may call the truck: it fills the tank, the price per litre rises by 12% with every
  delivery, and each delivery lets you **choose 1 of 3 premium cards** (stronger than the shop). Call
  early for more cards; stretch the tank and invest in the shop instead. If the tank runs dry during a
  day, the day ends. A run ends (bankrupt) when the tank is nearly dry at night and you can't afford a
  delivery. (No separate rent: the truck's rising price is the escalating bill.)
- **A run** lasts until bankruptcy or day 50. **Day 50 = the ending** (see Story). Meta progression is
  tuned so the ending takes roughly 50 runs.
- **Between runs**: XP buys permanent things in Papa's Garage: nozzles, bling, perks.

## Starting numbers (to tune with the bot)
- Pump price $2/L. Wholesale starts at $1.20/L, ×1.08 per delivery (balance bot, docs/balance/GOD_PUMP_BALANCE.md).
- Tank: $700 of gas (350 L), about five days at day-1 pace. Starts full (Dad's last delivery).
- Starting cash $60. Flow $4/s.
- Customers: orders $10–$30 (sedans), more with other types.

## The night shop (cash, always available): branches
| Branch | Nodes (in order) |
|---|---|
| HEURES (hours) | Thermos (14 h) · Mom covers lunch (16 h) · Evening permit (19 h) · Cousin Réjean on nights (23 h) |
| MARKETING (queue) | Flyers (+1 car waiting at opening) · Radio ad (+2) · Billboard (+3, more traffic) |
| ATTRACTIONS (bring cars) | Traffic light (more cars cut through) · Mini grocery (+$2 per car) · Car wash (+$4 per car, cars stay longer) · Loto machine (5% chance of a $20 tip) |
| NOZZLE | Wider stream · Auto-aim I · Faster flow · Auto-aim II · Drone nozzle 1 · Drone nozzle 2 |
| SERVICE | Tip-jar sign (+20% tips) · Squeegee (+$2 on Perfect or better) · Coffee for the line (cars wait 30% longer) |
| VIBE | Bluesy radio (max combo +1) · Regulars' bench (each applause +$1) · Jukebox (max combo +1) |

(The station tab and self-serve automation are retired: automation is **drone nozzles**, the 9-Kings
"auto-battler by a third of the run" arc is dropped.)

## Fuel-truck cards (choose 1 of 3 per delivery; luck raises the rarity)
Common: Happy hour (tips ×2 the first 2 h of each day) · Gas saver (spills halved) · Rush hour (+2 cars
waiting each morning) · Gold rush (Topped off +$4) · Combo lock (an OK no longer breaks the combo).
Rare: Twin stream (the stream fills two cars at once) · Magnet nozzle (auto-aim +60%) · Drone nozzle +1 ·
Price freeze (the next delivery doesn't raise the price) · Regulars' encouragement (applause +$2).
Legendary: Golden hose (10% of fills are golden: tip ×3) · Fuel recycler (spills flow back to the tank) ·
Deal with the devil (tips ×2, deliveries rise twice as fast) · Cousin's loan (+$300 now, next delivery +40%).

## Car types (unlocked over time; the day report shows progress to the next)
| Car | Look | Rule | Unlocks at (cars filled, all runs) |
|---|---|---|---|
| Sedan | boxy 80s sedan | the baseline | start |
| Le Pick-up | long pickup | huge order ($40–$60) but pays 80% | 25 |
| Le Cadillac | long white land yacht | big tipper (tips ×2) | 60 |
| Le Bazou | rusty beater | its tank takes fuel at 60% speed | 110 |
| Le Char de course | low red sports car | drives around fast | 180 |
| La Balayeuse | street-sweeper truck | not a customer: cleans puddles it drives over | 260 |
| Le Voleur | black car | not a customer: siphons gas from other cars, then flees; pour on it to chase it off | 350 |
| Le Maladroit | dented van | bumps cars, who spill some of their fuel | 460 |
| L'Électrique | small green car | doesn't take gas: pour on it and it leaves with a $10 fine | 600 |

## Papa's Garage (permanent, bought with XP)
XP: +1 per car filled, + the combo multiplier on each Good-or-better fill, +5 per Topped off.
- **Nozzles** (equip one): Le Classique (baseline) · La Douche (wide stream, −20% flow) · Le Laser (narrow,
  +40% flow, Topped off tips +50%) · La Lente (−30% flow, tips +30%) · Le Gros Calibre (flow ×2) · La Dorée
  (10% golden fills, flow +10%; late).
- **Bling** (equip in slots: 1 to start, up to 3): Fuzzy dice (luck +10) · Flame decal (max combo +1) · Chrome
  tip (flow +10%) · Hula girl (the first car of each day tips double) · Pine air freshener (cars wait 20%
  longer) · Saint Christophe medal (once a day an overfill doesn't break the combo) · Rabbit's foot (every
  10th car's fuel goes back in the tank) · Bobblehead (+5% tip per combo level) · Coupon book (upgrades
  10% cheaper) · Old receipt (start each run with +$50).
- **Perks** (tiers): Truck connections (first delivery −25%) · Lucky streak (luck +5 per tier) · Bigger
  cards (4 cards per delivery) · Reroll (1 reroll per delivery) · Morning rush (+1 car at opening) ·
  Jackpot (3% of fills tip ×4) · Bling slot +1 (×2) · Head start (start with a drone nozzle).
- **Luck** raises proc chances and card rarity.

## Story and tone
- **Title: GOD PUMP.** The intro is a mock-biblical epic: "In the beginning, there was gas." Clouds part,
  a choir swells, a golden nozzle descends from the heavens, the title slams in. Then: Saint-Clin-Clin-
  des-Meuh-Meuh, Québec. Your father passed away. The will: "...and to my only child, I leave... THE GOD
  PUMP." (choir) "It's a gas station." One pump, a boarded window. "Are you worthy?"
- **Ending (day 50):** an old faded-orange hatchback pulls in, a fishing rod out the window. You top it
  off. It's Dad: he faked his death to go fishing ("After 11, I went fishing. Then I just... kept going.").
  He looks at the lot, the regulars, the jar. "T'es un vrai gaz bar boy." Credits; the God Pump keeps going.

## Day report (end of each day)
Accuracy, loot (sales + tips), cars fueled, Super / Perfect / Good / OK / Miss counts, XP earned, and
progress towards the next car type.

## Build order (each step: spec → test → code → commit, tests green)
1. HD-2D polish from playtest 6: applause on Perfect, half the tilt-shift, dust, two-way traffic, no $
   on the pump dial, a rundown car, a tire pile, a garbage container, darker patchy ground with grass, a
   tree, a bordered lot (curbs, grass strip, bollards, old pump islands) after the satellite photos.
2. Grades rework + day report + XP.
3. Run loop: days by the clock, multi-day tank, the fuel truck, the 3 cards, bankruptcy, day 50.
4. Night shop tree (the branches above).
5. Car types + unlock progression.
6. Drone nozzles + auto-aim + wide/twin streams.
7. Papa's Garage: XP shop, nozzles, bling, perks, save file.
8. GOD PUMP title screen, intro, ending.
9. Sound pass (placeholder synths: applause, cash ding, horns, choir, truck).
10. Balance: a bot plays the real game headless; tune.
11. Retire the key-per-pump game; docs; a morning report with screenshots.
