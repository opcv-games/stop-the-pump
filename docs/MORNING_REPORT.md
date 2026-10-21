# Good morning: GOD PUMP v0.40.0

Built overnight from your brief (plan: `docs/GOD_PUMP_PLAN.md`). Everything is on the branch
`hypothesis/god-pump-run`, pushed, with 101 tests passing. Nothing is merged into `main` until you've
played it.

![A day](art/godpump_day.png)

## How to play it
1. Open the project in Godot. If it was already open: **Project → Reload Current Project**.
2. Press **Play** (▶, top right) or **Cmd+B**.
3. The first time, the intro plays (ESC skips it). Then name your gaz bar and you're on day 1.

| Key | Does |
|---|---|
| Mouse | aim the God Pump; hold to pour, let go to stop |
| ESC | pause (resume, or back to the title) |
| I | switch view: HD-2D, three-quarter pixel, flat |
| F3 / F4 / F6 | designer keys: end the day / +$100 / +1000 XP |

To start over from scratch, delete the save: `~/Library/Application Support/Godot/app_userdata/GOD PUMP/godpump_meta.cfg`.

## What got built
1. **Your v0.33 notes:**
   - **HD-2D polish:** the regulars applaud a Perfect and cheer a top-off; the tilt-shift is halved; dust drifts in the light; cars drive both ways on the road; no $ on the pump dial.
   - **New props:** a rusted wreck on a flat tire, a tire pile, a green DÉCHETS container and three maples.
   - **Ground:** darker dirt with patches of grass, cracks and oil stains.
   - **The lot, after your satellite photos:** a concrete curb, a grass strip, white bollards, a sidewalk, yellow hatching in front of the store, and the old pump pads.
2. **Grades:** Topped off (99.5%+), Perfect (97%+), Good (90%+), OK (80%+). Overfilling, or leaving a car under 80% at closing or past its patience, is a Miss. Tips start at 90%.
3. **The run:** the clock limits the day (7 h to 13 h to start, 4.5 s a game hour). The station's tank holds about five days of gas, and spills shorten that.
4. **The fuel truck is the bill.** The price rises 8% with every delivery, and each delivery deals **CHOOSE ONE** from 3 cards (common / rare / legendary; luck tilts the odds; rerolls come from a perk). You go bankrupt when the tank is dry and you can't afford a delivery. Day 50 is the ending.
5. **The night shop:** a Bills-style tree with 7 branches, always available:
   - **HEURES:** opening until 14, 16, 19, then 23 h.
   - **MARKETING:** cars already waiting when you open.
   - **ATTRACTIONS:** a traffic light, a mini grocery, a car wash, a lotto machine.
   - **PISTOLET:** a wider stream, auto-aim I and II, more flow, drone nozzles I and II.
   - **RÉSERVOIR:** a bigger tank.
   - **SERVICE:** tip sign, squeegee, coffee for the line.
   - **AMBIANCE:** radio, the regulars' bench, jukebox.
6. **15 truck cards.** For example: happy hour, twin stream, magnet nozzle, golden hose (10% golden fills), recycler, a pact with the devil (tips ×2, prices rise twice as fast), and the cousin's loan (+$300 now, the next delivery costs 40% more).
7. **9 car types**, unlocked by cars filled across all runs, each with its own look:
   - **Customers:** sedan, pickup (big order, pays 80%), Cadillac (tips ×2), Bazou (slow tank), racer (fast).
   - **Troublemakers:** the sweeper (cleans puddles), the thief (siphons gas from customers; pour on it to chase it off), the clumsy van (bumps cars, who spill), the electric (pour on it and pay a $10 fine). They wear badges.
   - **Day 50:** Dad, in the orange hatchback.
8. **Drone nozzles** are the automation (no auto-battler arc). Little quadcopters fill cars to a good-but-not-perfect level, for half the tip and no combo.
9. **Day report:** accuracy, loot, cars fueled, Super / Perfect / Good / OK / Miss, best combo, XP, and progress to the next car type.
10. **Papa's Garage** (XP: +1 a car, plus the combo on Good or better, plus 5 a top-off):
    - **6 nozzles:** Classique, Douche, Laser, Lente, Gros Calibre, Dorée.
    - **10 bling, in 1 to 3 slots:** fuzzy dice (luck), flames (combo), chrome tip (flow), hula girl (first car of the day tips double), pine air freshener (patience), Saint Christophe medal (one overfill forgiven a day), rabbit's foot (every 10th car's gas back in the tank), bobblehead (+5% tip per combo level), coupons (upgrades 10% cheaper), old receipt (+$50 start).
    - **9 perks with tiers:** truck friend, lucky star, more cards, reroll, morning rush, jackpot, a bling slot, head start (a drone), nest egg.
11. **The title: GOD PUMP.**
    - **The intro** is mock-biblical: "In the beginning, there was gas." Golden clouds part, god rays, a choir, the golden nozzle descends, the title slams in. Then Saint-Clin-Clin, the will ("…I leave… THE GOD PUMP."), "It's a gas station."
    - **The ending (day 50):** Dad drives in, sunburnt, a fishing rod out the window. He faked his death to go fishing, and admits you're "un vrai gaz bar boy". Then credits.
12. **Sound:** synthesized placeholders for the regulars' applause, the register ding, horns, the fuel truck with air brakes, and the choir. The music still loops.
13. **Balance:** a bot plays the real game headless (`tools/sim/god_bot.gd`):
    - **No Garage upgrades:** the median run ends around day 13.
    - **Strong Garage upgrades:** median day 36, with 4 in 20 reaching day 50.
    - Details are in `docs/balance/GOD_PUMP_BALANCE.md`.
14. **Every night-shop upgrade shows on the station:** 18 pixel props pop in the morning after you buy them, from the traffic light, car wash and lotto machine to extra tanks, street lamps, cousin Réjean at the door and the jukebox (`art/godpump_upgraded.png`).
15. **ESC pauses a day**, with a volume slider and a way back to the title.
16. **The old key-per-pump game is retired:** its code and tests are removed (still in git history), and its specs are archived in `features/retired/`.

## Decisions I took for you (veto any of them)
- **The bill is the fuel truck only**, with no separate weekly rent. Its rising price is the escalating bill, and each delivery deals the 3 cards. You suggested tying the bill to refuelling, and this keeps one bill, not two.
- **50 days is the finish line of one run**, and Garage progress is tuned so day 50 takes many runs. I read your "50 runs to reach the ultimate" that way.
- **Dad faked his death to go fishing.** That explains how he drives in on day 50 when the intro says he passed away. It fits "after 11 he went fishing".
- **Interface in English, flavour in French:** shop, card and car names, the regulars, the signs.
- **"A game by Olivier"** in the credits. Change it in `scenes/god/ui/cinematic.gd` if you'd rather.

## Known gaps
- **No playtest yet:** I verified with tests, renders and the bot, but no person has played a full run.
- **New car types make runs harder:** the bot does worse once the pickup, Bazou and racer unlock. They should feel like a challenge, not a punishment.
- **The cars' sprite stacks look flat** when seen straight from above. Fine at the game's camera angle, rough in the flat view.
- **Placeholder sounds** are synthesized and sound like it.
- **Settings:** only a volume slider (in the pause menu); no fullscreen option yet.

## Screenshots (docs/art/)
`godpump_day.png` · `godpump_title.png` · `godpump_report.png` · `godpump_night.png` ·
`godpump_cards.png` · `godpump_garage.png` · `godpump_car_types.png` · `godpump_drones.png` ·
`godpump_m1_polish.png` · `godpump_upgraded.png`
