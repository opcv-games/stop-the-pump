# GOD PUMP balance (2026-10-21, #37)

`tools/sim/god_bot.gd` plays the real game headless: GodPump's own simulation and RunState's rules.
The bot chases moving cars at 900 px/s and reacts in 0.25 s. It lets go aiming for an even split of
Topped off, Perfect, Good, OK and overfill (the designer's assumption), stopping exactly on its plan.
At night it calls the truck when the tank won't last tomorrow, keeps cash for it when the tank is
short, and buys the cheapest upgrade in this order: hours, marketing, nozzle, attractions, service,
tank, vibe. Cards are picked from a fixed preference list.

    godot --headless -s tools/sim/god_bot.gd -- 20 fresh      (fresh | mid | late)

## Target (playtest 7, 2026-10-21)
- **Day 50 is impossible on a fresh save.**
- **It takes about 2 hours of Papa's Garage upgrades.** The first win comes around hour 3: about 2 h of earning XP, then the winning run.
- **New car types are a difficulty ladder:** unlocking them makes days harder; the Garage answers them.

## Chosen economy
- **Wholesale price:** starts at $1.20/L against a $2.00 pump price and rises **25% per delivery** (was 8%).
- **Tank:** $700 of gas, full at the start.
- **The truck sells partial deliveries:** whatever your cash buys, at least $20. Bankrupt means a dry tank and under $20.
- **Two Garage perks push the wall back,** each 350 XP a tier (350, 700, 1050), 3 tiers:
  - **Contrat du fournisseur:** prices rise 20% slower per tier.
  - **Super sans plomb:** sales pay 10% more per tier.

Why: with 8% and full deliveries only, most runs ended in the trap the designer hit (enough money, not enough for a *full* delivery). Once partial deliveries were in, even a fresh save reached day 50 every time. The rising price is the wall. Growing the business doesn't beat it on its own: more sales mean more deliveries, so more rises. The fully kitted "late" save without the two perks dies around day 28. So the Garage needed levers aimed at the wall.

Tried along the way (price rise per delivery, fresh save):
- **14%:** 22 of 30 reach day 50.
- **20%:** 2 of 30.
- **26%:** 0 of 30, median day 34.
- **32–40%:** median day 27–29.
- **Perk tiers at 200 XP:** half the bot players won in their second run (1.5 h).

## Round 8 retune (2026-10-21)
Round 8 added three things that change the numbers:
- **A deeper tree:** the CAMION branch and 8 upgrades with two parents.
- **The tube man perk.**
- **No XP for unserved cars:** cars that leave without their fill no longer count, which lowered XP to about 1,175 an hour.

The new upgrades made every run stronger, so two prices went up:
- **Contrat à terme:** every **fourth** delivery comes without a price rise (was every third), and it costs $480 (was $380). At every third it cut the price wall by a third, and a fresh save reached day 50 in 1 run of 60.
- **Contrat du fournisseur** and **Super sans plomb:** **450 XP a tier** (was 350). At 350, the campaign's median first win came at 2.6 h.

    fresh (80 runs):  days survived median 34, mean 35.0, min 27, max 48; reached day 50: 0
                      mean per run: XP 694, play time 35.5 min -> 1174 XP per hour of play
    campaign: 12 players from a fresh save (Garage order: contract and premium gas first, then the tube man)
    first day 50: 12 of 12 players; median 2.8 h (earliest 1.5 h, latest 3.8 h)
    (full log: docs/balance/campaign.txt)

## Results before round 8
    fresh (80 runs):  days survived median 34, mean 34.9, min 27, max 47; reached day 50: 0
                      mean per run: XP 871, play time 35.8 min -> 1462 XP per hour of play
    mid (20 runs):    median 33, max 43; reached day 50: 0
    late (20 runs):   median 28, max 31; reached day 50: 0   (everything unlocked, no contract or premium gas)

    campaign: 12 players from a fresh save, buying contract and premium gas first
    first day 50: 12 of 12 players; median 3.1 h (earliest 1.5 h, latest 4.6 h)
    (full log: docs/balance/campaign.txt)

- **Play time** counts each day's clock plus about 25 s for the report and the night.
- **The bot is better than a person:** perfect tracking, instant reactions, a guaranteed even split. People will probably need longer than 3 h, and should still be able to find the contract and premium gas.
