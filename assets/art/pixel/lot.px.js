// GOD PUMP round 8 (docs/ROUND_8_PLAN.md): the lot comes alive. The tube man, a prop for every Garage
// perk and every two-parent upgrade, and the lot's everyday junk. Upright sprites for the HD-2D scene,
// light from the upper left. Build:
//   node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/lot.px.js --out assets/art/pixel/out

pal({ k: "#1d1a1f", K: "#3a3540", w: "#f4efe2", W: "#cfc6b0" })
shades("ABCD", "#e0502e", { hue: 16 })      // tube man red-orange
shades("EFG", "#f2c230", { hue: 12 })       // yellow
shades("HIJ", "#8f969c", { hue: 10 })       // steel
shades("LMN", "#7a5232", { hue: 14 })       // wood
shades("PQR", "#4f8a3c", { hue: 18 })       // green
shades("STU", "#3c6ea8", { hue: 16 })       // blue
shades("VXY", "#c9a24a", { hue: 10 })       // gold, brass
pal({ a: "#141214", b: "#2a2c30", c: "#9fc4d8", d: "#d8ecf4", e: "#b8342a", f: "#7e1e18", g: "#e9a77f", h: "#ffe28a",
      i: "#ff4fb0", j: "#ff9ad8", l: "#55d6ff", m: "#d0d0c8", n: "#8a8a80", o: "#5a4a3a", p: "#ffd6a0", q: "#e9e2cc" })

// --- Bonhomme gonflable: the tube man (round 8 perk). 8 frames of flailing, and a grab pose. -------
// The spine sways more the higher up it goes; the arms whip around out of phase with the body.
function tubeMan(c, ph, grab) {
  const W = 44, base = 66
  const sway = (y) => (grab ? 0.3 : 1) * Math.sin(ph * Math.PI * 2 + (base - y) / 11) * (base - y) / 9
  const spine = []
  for (let y = base; y >= 14; y -= 6) spine.push(Math.round(W / 2 + sway(y)), y)
  // the blower: a grey box with a fan grille
  c.rect(10, base, 16, 9, "I"); c.rect(10, base, 16, 2, "J"); c.rect(12, base + 3, 12, 4, "H")
  for (let x = 13; x < 24; x += 2) c.vline(x, base + 3, 4, "a")
  // the body: a fat tube, shaded round (dark edge, body, a lit stripe on the left)
  c.curve(spine, "A", { width: 11 })
  c.curve(spine, "B", { width: 8 })
  c.curve(spine.map((v, i) => (i % 2 === 0 ? v - 2 : v)), "C", { width: 3 })
  // yellow rings
  for (const y of [52, 40, 28]) { const x = Math.round(W / 2 + sway(y)); c.hline(x - 4, y, 9, "F"); c.hline(x - 3, y + 1, 7, "E") }
  // the head and its face: big eyes, a wide grin
  const hx = Math.round(W / 2 + sway(14)), hy = 12
  c.circ(hx, hy, 6, "B"); c.circ(hx - 1, hy - 1, 4, "C")
  c.circ(hx - 3, hy - 1, 2, "w"); c.circ(hx + 3, hy - 1, 2, "w"); c.px(hx - 3, hy - 1, "a"); c.px(hx + 3, hy - 1, "a")
  c.hline(hx - 3, hy + 3, 7, "a"); c.px(hx - 4, hy + 2, "a"); c.px(hx + 4, hy + 2, "a"); c.hline(hx - 2, hy + 4, 5, "f")
  // the hair: wild yellow tufts
  for (let i = -2; i <= 2; i++) c.line(hx + i * 2, hy - 5, hx + i * 3 + Math.round(Math.sin(ph * 6.28 + i) * 2), hy - 10 - (i % 2 === 0 ? 1 : 0), "F")
  // the arms, from the shoulders
  const sy = 26, sx = Math.round(W / 2 + sway(sy))
  if (grab) {
    c.curve([sx - 3, sy, sx - 9, sy - 10, sx - 6, sy - 22], "A", { width: 6 }); c.curve([sx - 3, sy, sx - 9, sy - 10, sx - 6, sy - 22], "B", { width: 4 })
    c.curve([sx + 3, sy, sx + 9, sy - 10, sx + 6, sy - 22], "A", { width: 6 }); c.curve([sx + 3, sy, sx + 9, sy - 10, sx + 6, sy - 22], "B", { width: 4 })
  } else {
    const a1 = ph * Math.PI * 2, a2 = ph * Math.PI * 2 + 2.2
    const l = [sx - 3, sy, sx - 9, sy - 4 + Math.round(Math.sin(a1) * 6), sx - 15, sy - 2 + Math.round(Math.sin(a1 + 1.2) * 12)]
    const r = [sx + 3, sy, sx + 9, sy - 4 + Math.round(Math.sin(a2) * 6), sx + 15, sy - 2 + Math.round(Math.sin(a2 + 1.2) * 12)]
    for (const arm of [l, r]) { c.curve(arm, "A", { width: 6 }); c.curve(arm, "B", { width: 4 }) }
  }
}
anim("tube_man", { w: 44, h: 76, frames: 8, fps: 10, outline: "k" }, (c) => tubeMan(c, c.phase, false))
sprite("tube_man_grab", { w: 44, h: 76, outline: "k" }, (c) => tubeMan(c, 0.1, true))


// --- Papa's Garage perks, each a prop on the lot (round 8) -----------------------------------------
// Bonne étoile: a lucky horseshoe over the door (flat on the facade).
sprite("prop_horseshoe", { w: 12, h: 12, outline: "k" },
  arc(6, 5, 5, 20, 160, "X", { inner: 3 }), rect(1, 5, 3, 6, "X"), rect(8, 5, 3, 6, "X"),
  px(2, 7, "Y"), px(9, 7, "Y"), px(3, 3, "Y"), px(8, 3, "Y"), px(2, 6, "V"), px(9, 6, "V"))
// Rush du matin: a rooster crowing on the roof.
sprite("prop_rooster", { w: 16, h: 16, outline: "k" },
  ellipse(7, 10, 5, 4, "W"), ellipse(6, 9, 3, 2, "w"), poly([1, 6, 3, 10, 0, 11], "e"), poly([1, 4, 4, 9, 2, 10], "f"),
  circ(11, 5, 3, "w"), poly([11, 1, 13, 1, 14, 3, 12, 3], "e"), poly([14, 5, 16, 6, 14, 7], "F"), px(12, 4, "a"),
  rect(13, 7, 1, 2, "e"), vline(6, 13, 3, "F"), vline(8, 13, 3, "F"))
// Jackpot: a one-armed bandit by the door.
sprite("prop_slots", { w: 18, h: 32, outline: "k" },
  rect(1, 6, 14, 26, "e"), rect(1, 6, 14, 2, "f"), rect(2, 2, 12, 5, "F"), text(8, 2, "777", "e", { align: "c" }),
  rect(3, 10, 10, 8, "w"), rect(3, 10, 10, 1, "W"), text(5, 12, "7", "e"), text(9, 12, "7", "e"),
  rect(3, 21, 10, 3, "a"), rect(5, 26, 6, 3, "W"), vline(16, 10, 9, "I"), circ(16, 9, 1, "e"))
// Bas de laine: a clothesline with a big wool sock (the nest egg) and a plaid shirt.
sprite("prop_clothesline", { w: 44, h: 28, outline: "k" },
  rect(1, 2, 2, 26, "M"), rect(41, 2, 2, 26, "M"), wire(2, 3, 42, 3, 3, "a"),
  rect(8, 5, 6, 10, "q"), rect(8, 13, 9, 4, "q"), hline(8, 7, 6, "e"), hline(8, 9, 6, "e"), px(10, 15, "W"), px(14, 15, "W"),
  rect(22, 5, 12, 12, "e"), (c) => { for (let y = 5; y < 17; y += 2) for (let x = 22 + (y % 4 ? 1 : 0); x < 34; x += 2) c.px(x, y, "f") },
  rect(20, 5, 2, 7, "e"), rect(34, 5, 2, 7, "e"))
// Contrat du fournisseur: the supplier's contract, framed in the window.
sprite("prop_contract", { w: 14, h: 16, outline: "k" },
  rect(0, 0, 14, 16, "X"), rect(2, 2, 10, 12, "q"), hline(3, 4, 8, "W"), hline(3, 6, 8, "W"), hline(3, 8, 6, "W"),
  circ(9, 11, 2, "e"), line(3, 11, 6, 11, "S"))
// Super sans plomb: a tall gold SUPER sign by the road.
sprite("prop_super_sign", { w: 26, h: 44, outline: "k" },
  rect(12, 18, 2, 26, "I"), rect(0, 0, 26, 18, "V"), rect(1, 1, 24, 16, "X"), rect(2, 2, 22, 14, "Y"),
  text(13, 4, "SUPER", "e", { align: "c" }), (c) => { for (const x of [6, 11, 16, 21]) c.px(x - 1, 12, "h") }, hline(4, 13, 18, "Y"), px(3, 3, "w"), px(4, 3, "w"))
// Plus de choix: the regulars' card table, a hand of cards dealt.
sprite("prop_card_table", { w: 30, h: 20, outline: "k" },
  rect(0, 4, 30, 4, "P"), rect(0, 4, 30, 1, "Q"), rect(2, 8, 2, 12, "a"), rect(26, 8, 2, 12, "a"),
  rect(5, 2, 4, 3, "w"), rect(10, 1, 4, 3, "w"), rect(16, 2, 4, 3, "w"), px(6, 3, "e"), px(11, 2, "a"), px(17, 3, "e"),
  rect(22, 0, 5, 4, "e"), rect(23, 1, 3, 2, "f"))
// Rebrasser: a pair of giant dice by the door.
sprite("prop_dice", { w: 26, h: 15, outline: "k" },
  rect(0, 3, 12, 12, "w"), poly([0, 3, 4, 0, 16, 0, 12, 3], "W"), poly([12, 3, 16, 0, 16, 12, 12, 15], "W"),
  px(3, 6, "a"), px(8, 11, "a"), px(6, 8, "a"),
  rect(14, 5, 10, 10, "q"), poly([14, 5, 17, 2, 26, 2, 24, 5], "W"), px(16, 7, "e"), px(21, 7, "e"), px(16, 12, "e"), px(21, 12, "e"))
// Place pour bling: a glass display case with the bling inside.
sprite("prop_display_case", { w: 24, h: 28, outline: "k" },
  rect(1, 2, 22, 16, "c"), rect(1, 2, 22, 1, "d"), rect(2, 3, 2, 14, "d"), rect(1, 18, 22, 4, "M"), rect(3, 22, 2, 6, "N"), rect(19, 22, 2, 6, "N"),
  rect(6, 13, 3, 3, "w"), px(7, 14, "a"), rect(11, 12, 3, 4, "Q"), circ(17, 14, 2, "Y"), px(17, 13, "h"), rect(5, 6, 4, 2, "B"))
// Longueur d'avance: a drone dock, a drone parked on its pad.
sprite("prop_drone_dock", { w: 20, h: 32, outline: "k" },
  rect(9, 10, 2, 22, "I"), rect(2, 9, 16, 2, "J"), rect(4, 11, 12, 1, "H"),
  rect(6, 4, 8, 4, "e"), rect(6, 4, 8, 1, "B"), hline(0, 2, 7, "H"), hline(13, 2, 7, "H"), vline(3, 2, 3, "I"), vline(16, 2, 3, "I"),
  px(9, 5, "l"), px(10, 5, "l"), rect(6, 28, 8, 4, "J"))

// --- The upgrades with two parents, on the lot (round 8) -------------------------------------------
// Fenêtre au volant: a drive-thru window with its menu board.
sprite("prop_drive_thru", { w: 38, h: 30, outline: "k" },
  rect(0, 6, 18, 24, "W"), rect(0, 6, 18, 2, "q"), rect(3, 10, 12, 9, "c"), rect(3, 10, 12, 1, "d"), rect(4, 11, 3, 7, "d"),
  rect(2, 20, 14, 2, "M"), rect(7, 18, 3, 2, "w"), rect(8, 17, 1, 1, "M"),
  rect(20, 4, 18, 16, "a"), rect(21, 5, 16, 14, "b"), text(29, 6, "CAFE", "h", { align: "c" }), hline(23, 13, 12, "W"), hline(23, 15, 9, "W"), rect(28, 20, 2, 10, "I"))
// Soirée du hockey: a street hockey net.
sprite("prop_hockey_net", { w: 28, h: 18, outline: "k" },
  rect(0, 0, 28, 2, "e"), rect(0, 0, 2, 18, "e"), rect(26, 0, 2, 18, "e"),
  (c) => { for (let x = 3; x < 26; x += 3) c.vline(x, 2, 15, "W"); for (let y = 4; y < 17; y += 3) c.hline(2, y, 24, "W") },
  rect(0, 16, 28, 2, "f"), ellipse(20, 16, 2, 1, "a"))
// Carte fidélité: a sticker sign on the door.
sprite("prop_loyalty", { w: 26, h: 12, outline: "k" },
  rect(0, 0, 26, 12, "S"), rect(1, 1, 24, 10, "T"), text(13, 1, "CARTE", "w", { align: "c" }), text(13, 6, "FIDELE", "F", { align: "c" }))
// Néons de nuit: a pink neon NUIT in a blue tube frame.
sprite("prop_night_neon", { w: 30, h: 14 },
  rect(0, 0, 30, 14, "a"), box(1, 1, 28, 12, "l"), text(15, 4, "NUIT", "i", { align: "c", scale: 1 }), px(4, 4, "j"), px(25, 9, "j"))
// Hangar à drones: a little quonset hangar with a drone out front.
sprite("prop_drone_hangar", { w: 42, h: 28, outline: "k" },
  ellipse(21, 28, 20, 22, "H"), ellipse(21, 28, 18, 20, "I"), (c) => { for (let x = 6; x < 40; x += 5) c.vline(x, 8, 20, "H") },
  rect(14, 14, 14, 14, "a"), rect(15, 15, 12, 13, "b"), text(21, 9, "DRONES", "w", { align: "c" }),
  rect(30, 4, 8, 3, "e"), hline(27, 3, 5, "H"), hline(36, 3, 5, "H"))
// Cantine à patates: a chip truck with a cone of fries on the roof.
sprite("prop_chip_truck", { w: 52, h: 34, outline: "k" },
  rect(0, 10, 44, 18, "w"), rect(0, 10, 44, 3, "e"), rect(0, 25, 44, 3, "e"), rect(44, 16, 8, 12, "W"), rect(45, 17, 5, 5, "c"),
  rect(8, 15, 22, 8, "c"), rect(8, 15, 22, 1, "d"), rect(6, 22, 26, 2, "M"), text(20, 4, "PATATES", "e", { align: "c" }),
  rect(30, 2, 1, 8, "I"), rect(10, 2, 1, 8, "I"), circ(9, 29, 4, "a"), circ(9, 29, 2, "I"), circ(40, 29, 4, "a"), circ(40, 29, 2, "I"),
  poly([34, 9, 42, 9, 40, 2, 36, 2], "e"), vline(36, 0, 3, "F"), vline(38, 0, 3, "E"), vline(40, 0, 3, "F"))
// Prix affiché: a tall roadside price board.
sprite("prop_price_board", { w: 32, h: 48, outline: "k" },
  rect(15, 26, 2, 22, "I"), rect(0, 0, 32, 26, "W"), rect(1, 1, 30, 24, "w"), text(16, 2, "ESSENCE", "e", { align: "c" }),
  rect(5, 9, 22, 13, "a"), text(16, 11, "2.00", "e", { align: "c", scale: 1 }), text(16, 17, "LITRE", "e", { align: "c" }))
// Contrat à terme: a notice board, the contract pinned on it, stamped.
sprite("prop_contract_board", { w: 22, h: 30, outline: "k" },
  rect(0, 0, 22, 18, "L"), rect(1, 1, 20, 16, "M"), rect(3, 2, 9, 12, "q"), hline(4, 4, 7, "W"), hline(4, 6, 7, "W"), hline(4, 8, 5, "W"),
  rect(13, 4, 7, 8, "w"), hline(14, 6, 5, "W"), circ(7, 12, 2, "e"), px(7, 2, "e"), px(16, 4, "S"), rect(4, 18, 2, 12, "N"), rect(16, 18, 2, 12, "N"))

// --- CAMION props ----------------------------------------------------------------------------------
// Achat en vrac: oil drums, stacked.
sprite("prop_drums", { w: 30, h: 24, outline: "k" },
  ...[[0, 10], [10, 10], [20, 10], [5, 0], [15, 0]].flatMap(([x, y]) => [rect(x, y, 10, 14, "e"), rect(x, y, 2, 14, "B"), rect(x + 8, y, 2, 14, "f"),
    hline(x, y + 4, 10, "f"), hline(x, y + 10, 10, "f"), rect(x + 3, y, 4, 1, "a")]))
// Citerne usagée: the old spare tanker trailer, rusting out back.
sprite("prop_old_tanker", { w: 62, h: 28, outline: "k" },
  capsule(10, 12, 10, 52, 12, 10, "HIJ"),
  (c) => { const R = c.rng(3); for (let i = 0; i < 9; i++) { const x = 6 + Math.floor(R() * 50), y = 4 + Math.floor(R() * 8); for (let d = 0; d < 3 + Math.floor(R() * 5); d++) if (c.is(x, y + d, "HIJ")) c.px(x, y + d, d < 1 ? "o" : "N") } },
  hline(4, 16, 54, "N"), rect(4, 22, 54, 2, "a"), circ(12, 25, 3, "a"), circ(20, 25, 3, "a"), rect(52, 20, 8, 3, "I"), rect(58, 18, 2, 8, "I"))

// --- The everyday lot (round 8) ------------------------------------------------------------------
sprite("prop_ice", { w: 20, h: 28, outline: "k" },
  rect(0, 0, 20, 28, "w"), rect(0, 0, 20, 2, "d"), rect(1, 3, 18, 7, "S"), text(10, 4, "GLACE", "w", { align: "c" }),
  rect(2, 12, 16, 12, "q"), line(10, 13, 10, 22, "c"), line(6, 15, 14, 20, "c"), line(6, 20, 14, 15, "c"), rect(15, 17, 2, 3, "I"), rect(1, 26, 18, 2, "W"))
sprite("prop_air", { w: 18, h: 28, outline: "k" },
  rect(2, 0, 14, 24, "e"), rect(2, 0, 2, 24, "B"), rect(3, 2, 12, 7, "w"), text(9, 3, "AIR", "a", { align: "c" }), text(9, 11, "25", "w", { align: "c" }),
  curve([15, 16, 18, 20, 14, 26], "a", { width: 2 }), rect(1, 24, 16, 4, "I"))
sprite("prop_propane", { w: 26, h: 28, outline: "k" },
  rect(0, 0, 26, 28, "I"), rect(1, 1, 24, 26, "b"), (c) => { for (let x = 2; x < 25; x += 3) c.vline(x, 1, 26, "H"); for (let y = 6; y < 27; y += 6) c.hline(1, y, 24, "H") },
  rect(3, 12, 6, 13, "w"), rect(10, 12, 6, 13, "w"), rect(17, 12, 6, 13, "w"), rect(4, 10, 4, 2, "I"), rect(11, 10, 4, 2, "I"), rect(18, 10, 4, 2, "I"),
  rect(4, 1, 18, 5, "e"), text(13, 1, "PROPANE", "w", { align: "c" }))
sprite("prop_news_boxes", { w: 36, h: 20, outline: "k" },
  rect(0, 2, 15, 14, "S"), rect(1, 4, 13, 6, "c"), rect(1, 4, 13, 1, "d"), text(7, 11, "JRNL", "w", { align: "c" }), rect(2, 16, 2, 4, "I"), rect(11, 16, 2, 4, "I"),
  rect(17, 0, 19, 16, "F"), rect(18, 2, 17, 7, "c"), rect(18, 2, 17, 1, "d"), text(26, 10, "ECHO", "a", { align: "c" }), rect(19, 16, 2, 4, "I"), rect(32, 16, 2, 4, "I"))
sprite("prop_special", { w: 18, h: 22, outline: "k" },
  poly([1, 21, 4, 0, 14, 0, 17, 21], "L"), rect(4, 2, 10, 15, "a"), text(9, 3, "SPE", "w", { align: "c" }), hline(5, 9, 8, "F"), hline(5, 11, 6, "w"), hline(5, 13, 7, "i"))
sprite("prop_picnic", { w: 34, h: 16, outline: "k" },
  rect(2, 4, 30, 3, "L"), rect(2, 4, 30, 1, "N"), rect(0, 9, 34, 2, "M"), line(6, 7, 3, 16, "M"), line(28, 7, 31, 16, "M"), line(10, 7, 13, 16, "M"), line(24, 7, 21, 16, "M"))
sprite("prop_phone_booth", { w: 16, h: 38, outline: "k" },
  rect(0, 4, 16, 34, "I"), rect(1, 5, 14, 30, "c"), rect(1, 5, 14, 1, "d"), rect(0, 0, 16, 5, "S"), text(8, 0, "TEL", "w", { align: "c" }),
  rect(5, 14, 6, 9, "a"), rect(6, 15, 4, 3, "H"), rect(0, 35, 16, 3, "J"), vline(3, 6, 28, "d"))
sprite("prop_moose_sign", { w: 18, h: 30, outline: "k" },
  rect(8, 12, 2, 18, "I"), poly([9, 0, 18, 9, 9, 18, 0, 9], "F"), poly([9, 1, 17, 9, 9, 17, 1, 9], "E"),
  rect(5, 8, 7, 3, "a"), rect(11, 6, 2, 3, "a"), px(13, 5, "a"), px(11, 5, "a"), rect(6, 11, 1, 3, "a"), rect(10, 11, 1, 3, "a"))
// The horizon: Holstein cows in the field (two poses), and the church's silver steeple.
function cow(name, head) {
  sprite(name, { w: 28, h: 18, outline: "k" },
    rect(4, 4, 18, 9, "w"), rect(8, 4, 5, 5, "a"), rect(15, 8, 5, 4, "a"), rect(4, 10, 3, 3, "a"),
    rect(5, 13, 2, 5, "w"), rect(9, 13, 2, 5, "w"), rect(16, 13, 2, 5, "w"), rect(19, 13, 2, 5, "w"),
    head ? rect(22, 1, 5, 6, "w") : rect(22, 8, 5, 6, "w"), head ? px(26, 3, "a") : px(26, 11, "a"),
    head ? rect(23, 6, 4, 2, "g") : rect(23, 13, 4, 2, "g"), vline(3, 5, 6, "a"), rect(9, 12, 4, 2, "g"))
}
cow("prop_cow_a", true)
cow("prop_cow_b", false)
sprite("prop_steeple", { w: 26, h: 64, outline: "k" },
  rect(4, 30, 18, 34, "w"), rect(4, 30, 3, 34, "W"), poly([2, 31, 13, 20, 24, 31], "I"), rect(9, 14, 8, 8, "w"), poly([8, 15, 13, 0, 18, 15], "H"),
  poly([10, 15, 13, 3, 13, 15], "J"), vline(13, 0, 3, "Y"), hline(12, 1, 3, "Y"), rect(10, 38, 6, 9, "S"), ring(13, 26, 2, "a"), rect(10, 52, 6, 12, "M"))

// --- The rival across the road (lore): CHEZ GAÉTAN, a sad little kiosk with a higher price ---------
sprite("prop_rival", { w: 64, h: 42, outline: "k" },
  rect(4, 8, 56, 4, "f"), rect(4, 8, 56, 1, "e"), rect(8, 12, 2, 30, "I"), rect(54, 12, 2, 30, "I"),   // canopy on two posts
  rect(20, 18, 24, 24, "W"), rect(20, 18, 24, 2, "q"), rect(24, 24, 7, 8, "c"), rect(34, 22, 7, 20, "M"),   // the kiosk
  rect(12, 0, 40, 9, "a"), text(32, 2, "CHEZ GAETAN", "G", { align: "c" }),
  rect(45, 26, 18, 12, "w"), text(54, 29, "2.19", "e", { align: "c" }), rect(53, 38, 2, 4, "I"),
  rect(11, 30, 6, 12, "e"), rect(12, 31, 4, 3, "w"))

// --- Round 9: the wheel clamps' sign: towing, 24 hours ---------------------------------------------
sprite("prop_tow_sign", { w: 22, h: 34, outline: "k" },
  rect(10, 14, 2, 20, "I"), rect(0, 0, 22, 15, "E"), rect(1, 1, 20, 13, "F"), text(11, 2, "SABOT", "f", { align: "c" }), text(11, 8, "24H", "a", { align: "c" }))
