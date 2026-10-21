# GOD PUMP balance (2026-10-21, #37)

`tools/sim/god_bot.gd` plays the real game headless: GodPump's own simulation and RunState's rules.
The bot chases moving cars at 900 px/s and reacts in 0.25 s. It lets go aiming for an even split of
Topped off, Perfect, Good, OK and overfill (the designer's assumption), stopping exactly on its plan.
At night it calls the truck when the tank won't last tomorrow, keeps cash for it when the tank is
short, and buys the cheapest upgrade in this order: hours, marketing, nozzle, attractions, service,
tank, vibe. Cards are picked from a fixed preference list.

    godot --headless -s tools/sim/god_bot.gd -- 20 fresh      (fresh | mid | late)

## Chosen economy
- **Wholesale price:** starts at $1.20/L against a $2.00 pump price (was $1.00) and rises 8% per delivery (was 12%).
- **Tank:** $700 of gas (was $800), full at the start.

Tried along the way:
- **$1.00 + 7%:** too easy; fresh runs reached day 50 6 times in 10.
- **$1.40–$1.50 + 18–20%:** too hard; gas sells at a loss after three deliveries, and the Garage can't help.

## Results (20 runs per meta level)
    GOD PUMP bot: 20 runs, meta fresh, 6 s
    days survived: median 13, mean 15.2, min 7, max 50; reached day 50: 1
    mean per day: loot $141, gas used $116, cars 9.8
    GOD PUMP bot: 20 runs, meta mid, 6 s
    days survived: median 12, mean 13.3, min 7, max 48; reached day 50: 0
    mean per day: loot $139, gas used $118, cars 9.9
    GOD PUMP bot: 20 runs, meta late, 25 s
    days survived: median 36, mean 33.6, min 7, max 50; reached day 50: 4
    mean per day: loot $432, gas used $288, cars 15.7

- **fresh:** no Garage purchases. **mid:** 400 cars filled (unlocks the pickup, Cadillac, bazou, racer and sweeper) and a few perks and bling, no nozzle. **late:** everything unlocked, the Laser nozzle, strong perks, three bling.
- **mid isn't better than fresh:** the car types it unlocks (a pickup that pays 80%, the slow bazou, the fast racer) make days harder, and its perks are weak. Real players at that stage would also own a nozzle. Worth watching in playtests: new car types should feel like a challenge, not a punishment.
- **The bot is better than a person:** perfect tracking, instant reactions, a guaranteed even split. People will likely go bust earlier, so the ending should take many runs, as intended (about 50).
