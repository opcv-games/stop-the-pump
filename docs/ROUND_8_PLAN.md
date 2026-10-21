# GOD PUMP: round 8 build plan (2026-10-21)

> **Status: built in v0.43.0 (2026-10-21), awaiting playtest.** Two changes from the plan:
> - **Fenêtre au volant** needs Café + Thermos: the tree's layout can't put three links on one branch side by side.
> - **Contrat à terme** freezes every 4th delivery (not every 3rd), so a fresh save still can't reach day 50.
>
> Agreed in a design session with the designer (playtest 7 follow-up). Contract for one long build
> round of about 75 minutes. Work top to bottom; each step: spec → test → code → commit, tests green.
> Republish the artifact at the end (`sh tools/web/pack_artifact.sh`, same URL).

## Designer's verdict going in
"The gameplay is tight. The tension between refuelling now to get an upgrade and refuelling later to
buy more gas at a lower price is crazy good." Protect it: nothing in this round may weaken that choice.

## Build order
1. **Gas Tank panel and the truck animation** (must)
   - The night screen's "THE TRUCK" becomes **GAS TANK**, drawn as an industrial fuel tank: a
     horizontal cylinder on legs, rivets, a ladder, a hazard stripe, a dial and a sight-glass level.
   - **CALL THE TRUCK** plays a short animation (about 2.5 s): a tanker backs in, the hose connects,
     the tank fills while the price ticks, the truck pulls away. Then the cards.
2. **A deeper tree, with upgrades needing two parents** (must)
   - **Truck tension:**
     - Achat en vrac: −10% delivery when the tank is under 25%.
     - Contrat à terme: lock today's price for your next delivery. Needs Gros réservoir II + Panneau.
     - Citerne usagée: a partial delivery doesn't raise the price.
     - Jauge d'alarme: days of gas left, to the hour.
   - **Cross-branch nodes,** sitting between branches and needing both parents:
     - Fenêtre au volant (Café + Mini-épicerie): a car that waited over 3 s buys a coffee, +$1.
     - Soirée du hockey (Maman fait le dîner + Radio bluesy): every 7th day, double the cars.
     - Carte fidélité (Pub à la radio + Pancarte pourboire): every 5th car tips double.
     - Néons de nuit (Permis du soir + Juke-box): tips +30% after 19 h.
     - Hangar à drones (Drone + Lave-auto): drone fills +$2.
     - Cantine à patates (Mini-épicerie + Banc): a chip truck; cars wait longer, applause +$2.
     - Prix affiché (Panneau + Gros réservoir): sales +5%.
   - Rebalance with the campaign bot afterwards: day 50 still impossible on a fresh save, still about
     2 h of Garage.
3. **Bonhomme gonflable, plus every perk as a prop** (must)
   - The tube man is a Garage perk. Tier 1 siphons: every few seconds it grabs a car from the road,
     sucks the gas out of it and spits it into your tank. Tier 2 siphons and drops the car on your lot
     as a customer. It dances on the lot.
   - Every owned Garage perk is always a prop on the lot:
     - Bonne étoile: a horseshoe over the door.
     - Rush du matin: a rooster on the roof.
     - Jackpot: a slot machine.
     - Bas de laine: a sock on a clothesline.
     - Contrat du fournisseur: a framed contract in the window.
     - Super sans plomb: a gold SUPER sign.
     - Ami du camionneur: the trucker's rig out back.
     - Plus de choix, Rebrasser, Place pour bling, Longueur d'avance: a card table, dice, a display case, a drone dock.
4. **Bling on the nozzle** (must)
   - **Pieces:** fuzzy dice, flame decal, chrome tip, hula girl, pine air freshener, medal, rabbit's
     foot, bobblehead, coupons and receipt.
   - **Rings:** each one also adds a gold ring or bracelet around the handle, like a hand full of rings.
5. **A living lot** (should)
   - **Regulars:** Ti-Guy, Mme Gagnon, Bertrand, Le Grand. They have routines: out the door, bench,
     smoke, wander to watch the pump, back inside, out with a coffee. They cheer from wherever they are.
   - **New props:**
     - an ice machine (GLACE)
     - an AIR 25¢ pump
     - a propane cage
     - newspaper boxes
     - a sandwich board with the day's special
     - a picnic table
     - a hockey net
     - a phone booth
     - a moose-crossing sign
   - **The horizon:** cows in the field and a church steeple.
6. **Reports and lore: both** (should)
   - **L'Écho de Saint-Clin-Clin,** the nightly newspaper:
     - a headline about your day
     - gas price news
     - a small chart: price per delivery and cash per day
     - gossip that builds the lore
     - classified ads teasing upgrades
     - Dad's postcards on days 10, 20, 30 and 40, signed "un pêcheur", subtle hints he's alive
   - **A STATS tab in Papa's Garage:** lifetime numbers (runs, best day, cars, grades, best combo, XP
     earned, deliveries, highest price paid).
   - **The rival:** a station across the road, with the notary and cousin Réjean in the gossip.
7. **Art pass** (if time allows), in this order:
   - Regulars: bigger, with walk, sit, cheer and coffee poses.
   - Cars: more detailed stacks with chrome, lights, rust, and a distinct silhouette per type.
   - Night screen and UI: 80s wood paneling and enamel-sign panels.

## Parked (next round)
- Full-run charts on the end-of-run front page (if time runs short).
- A full redraw of every car type (only the common ones get the pass this round).
