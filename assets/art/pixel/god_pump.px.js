// God-pump prototype sprites (#36), pixel art as code with claude-pxl.
// Build: node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/god_pump.px.js --out assets/art/pixel/out
// Top-down, seen from above; vehicles face right (+x). Drawn at 1x, shown at 2x in Godot (nearest filter).
// Palette: Hopper's "Gas" mood, muted, with the gas itself the only bright gold.

pal({
  k: "#1d1a1f", K: "#3a3540",                       // ink, soft ink
  b: "#6f8fb0", B: "#4c6684", L: "#a3bdd6", R: "#3d5470",   // car body (blue): mid, dark, light, roof
  w: "#c9dde6", W: "#8fb0c2",                       // glass, glass shade
  y: "#fff2a8", r: "#d8483c", t: "#141214",         // headlight, taillight, tyre
  s: "#e9a77f", S: "#c27a58", n: "#f6c9a8",         // skin: mid, shade, light
  e: "#b3261e", E: "#7e1712", f: "#e0574a",         // nozzle grip red: mid, dark, light
  m: "#4a4a52", M: "#77777f",                       // nozzle steel
  G: "#b07a12", g: "#f0b52a", h: "#ffe58a", H: "#fff7d6",   // gas gold ramp (dark to shine)
  v: "#3f8a4a", V: "#2a6234", u: "#7cc488",         // dollar bill greens
  o: "#c98a1c", O: "#8e5e10", c: "#ffd34d", C: "#fff1a0",   // coin
  a: "#34312f", A: "#2b2826", i: "#433f3b",         // asphalt
  d: "#d9c78a",                                     // road paint
  x: "#5a4632", X: "#4a3828", z: "#6d563d",         // dirt
  p: "#d8d6d0", P: "#9d9b95",                       // smoke
})
ramps("kKmM", "Eef", "GghH", "Vvu", "Ooc", "Xxz")

// --- Cars ---------------------------------------------------------------------------------
sprite("car", { w: 28, h: 16, outline: "k", pivot: "center" },
  rect(1, 2, 26, 12, "b"),
  rect(2, 2, 24, 1, "L"), rect(2, 13, 24, 1, "B"),          // lit top edge, shaded bottom edge
  rect(7, 4, 11, 8, "R"), rect(8, 5, 9, 6, "b"),              // roof panel
  rect(18, 4, 4, 8, "w"), rect(18, 4, 1, 8, "W"),             // windshield
  rect(4, 4, 2, 8, "w"),                                      // rear window
  px(26, 3, "y"), px(26, 12, "y"), px(1, 3, "r"), px(1, 12, "r"),
  rect(4, 1, 4, 1, "t"), rect(19, 1, 4, 1, "t"), rect(4, 14, 4, 1, "t"), rect(19, 14, 4, 1, "t"))

const BODIES = {
  red: ["#b0574a", "#803a32", "#d8857a", "#6a2f29"],
  green: ["#6f9a5f", "#4d7042", "#9bc28a", "#3f5b36"],
  cream: ["#cdbb8a", "#a39066", "#e8dcb4", "#8a7853"],
  purple: ["#8a74a8", "#634f80", "#b2a0cc", "#52406b"],
  white: ["#d8d6d0", "#a8a59e", "#f2f0ea", "#8c8a84"],
  orange: ["#d06a2c", "#a04c1c", "#ec9a5e", "#8a3e16"],   // the faded-orange 70s hatchback from the reference
}
for (const [name, [b, B, L, R]] of Object.entries(BODIES))
  sprite("car_" + name, { base: "car", swap: { b, B, L, R } })

// --- The god hand: a giant hand gripping a pump nozzle; the spout's tip is bottom right -------
sprite("nozzle", { w: 48, h: 38, outline: "k" },
  capsule(1, 36, 2.5, 7, 26, 2.5, "kKm"),                     // the hose, trailing off the bottom left
  capsule(6, 25, 4, 30, 15, 3.5, "Eef"),                      // red grip, long enough to show
  capsule(29, 15, 4.5, 35, 17, 4.5, "kKmM"),                  // valve body
  capsule(35, 18, 2.5, 44, 32, 1.5, "kKmM"),                  // spout
  circ(17, 13, 7, "s"), circ(15, 11, 4, "n"),                 // fist, lit
  circ(23, 10, 3, "s"), circ(25, 14, 3, "s"), circ(24, 18, 2, "S"),   // fingers wrapped over the grip
  px(22, 9, "n"), px(24, 13, "n"),
  rect(19, 21, 7, 2, "M"))                                     // trigger guard

// --- Money ----------------------------------------------------------------------------------
sprite("bill", { w: 12, h: 7, outline: "V" },
  rect(0, 0, 12, 7, "v"), rect(1, 1, 10, 5, "u"), rect(2, 2, 8, 3, "v"),
  circ(6, 3, 1, "u"), px(1, 1, "v"), px(10, 5, "v"))

// A coin spinning: face, three-quarter, edge, three-quarter.
sprite("coin_0", { w: 8, h: 8, outline: "O" }, circ(4, 4, 3, "o"), circ(3, 3, 2, "c"), px(2, 2, "C"))
sprite("coin_1", { w: 6, h: 8, outline: "O" }, ellipse(3, 4, 2, 3, "o"), ellipse(2, 3, 1, 2, "c"))
sprite("coin_2", { w: 2, h: 8, outline: "O" }, rect(0, 1, 2, 6, "c"))
sprite("coin_3", { w: 6, h: 8, outline: "O" }, ellipse(3, 4, 2, 3, "o"), ellipse(4, 3, 1, 2, "c"))

// --- Gas on the ground: gold puddles, three sizes ---------------------------------------------
function puddle(name, rx, ry) {
  sprite(name, { w: rx * 2 + 4, h: ry * 2 + 4, pivot: "center" },
    ellipse(rx + 2, ry + 2, rx, ry, "G"),
    ellipse(rx + 1, ry + 1, rx - 2, ry - 1, "g"),
    ellipse(rx + 3, ry + 3, Math.max(2, rx - 5), Math.max(1, ry - 3), "g"),
    ellipse(rx - Math.floor(rx / 3), ry - Math.floor(ry / 3), Math.max(1, rx / 4), Math.max(1, ry / 4), "h"),
    px(rx - Math.floor(rx / 3) - 1, ry - Math.floor(ry / 3) - 1, "H"))
}
puddle("puddle_s", 6, 4)
puddle("puddle_m", 10, 6)
puddle("puddle_l", 15, 9)

// --- Effects ----------------------------------------------------------------------------------
sprite("sparkle", { w: 7, h: 7 }, vline(3, 0, 7, "h"), hline(0, 3, 7, "h"), px(3, 3, "H"), px(2, 2, "g"), px(4, 4, "g"), px(2, 4, "g"), px(4, 2, "g"))
sprite("smoke", { w: 9, h: 8, outline: "P" }, circ(3, 4, 3, "p"), circ(6, 3, 2, "p"), circ(5, 5, 2, "p"))

// --- Ground tiles (tile seamlessly) -----------------------------------------------------------
function specks(c, w, h, keys, n, seed) {
  let s = seed
  for (let i = 0; i < n; i++) {
    s = (s * 1103515245 + 12345) % 2147483648
    const x = (s >> 16) % w   // the high bits: the low bits of this generator repeat quickly
    s = (s * 1103515245 + 12345) % 2147483648
    const y = (s >> 16) % h
    c.px(x, y, keys[i % keys.length])
  }
}
sprite("asphalt", { w: 32, h: 32 }, rect(0, 0, 32, 32, "a"), (c) => specks(c, 32, 32, "Ai", 70, 7))
sprite("road", { w: 32, h: 32 }, rect(0, 0, 32, 32, "A"), (c) => specks(c, 32, 32, "ai", 40, 3), rect(4, 15, 16, 2, "d"))
sprite("dirt", { w: 32, h: 32 }, rect(0, 0, 32, 32, "x"), (c) => specks(c, 32, 32, "Xz", 90, 11))

pal({ q: "#efe6cf" })  // cream: plates, chrome glints (the same cream the round-4 palette uses)
// --- Sprite-stacked cars (#36, redrawn in round 8) ---------------------------------------------
// Every car is 8 top-down slices, bottom to top, front facing +x. carSlices() draws them from a spec:
// len (pixels), cab [x0, x1] (the greenhouse), body keys {b, B, Lt, R} (mid, dark, light, roof), and
// optional features: bed (pickup), tall (vans and trucks), low (no roof: the racer), fins + ornament
// (the Cadillac), stripes + wing (the racer), patch (the bazou's odd door and rust), tint + scoop
// (the thief), rack + rod (Dad's hatchback, a fishing rod on the roof), hatch (a short rear).
// Every car gets: tyres with hubcaps, chrome bumpers, headlights, a grille, taillights, a Québec
// plate, door seams and handles, a chrome trim line, glass with a reflection, a lit roof corner.
function carSlices(spec) {
  const L = spec.len, [c0, c1] = spec.cab, { b, B, Lt, R } = spec.keys
  const wa = 3, wb = L - 10, mid = Math.round((c0 + c1) / 2)
  const tyres = [rect(wa, 0, 6, 16, "t"), rect(wb, 0, 6, 16, "t")]
  const hubs = spec.patch ? [px(wa + 2, 0, "M"), px(wa + 2, 15, "M"), px(wb + 2, 0, "M")]   // the bazou lost a hubcap
    : [px(wa + 2, 0, "M"), px(wa + 3, 0, "M"), px(wa + 2, 15, "M"), px(wa + 3, 15, "M"), px(wb + 2, 0, "M"), px(wb + 3, 0, "M"), px(wb + 2, 15, "M"), px(wb + 3, 15, "M")]
  const seams = (k) => [c0 + 1, mid, c1].flatMap((x) => [px(x, 1, k), px(x, 14, k)])
  const glass = spec.tint ? ["}", "{"] : ["w", "W"]
  const sl = []
  // 0: the tyres and the dark underbody
  sl.push([...tyres, rect(1, 2, L - 2, 12, B), px(1, 4, "M")])
  // 1: the tyres' outer faces with hubcaps, the lower body
  sl.push([...tyres, ...hubs, rect(0, 1, L, 14, B)])
  // 2: the body's sides, chrome bumpers, headlights and grille in front, taillights and the plate behind
  sl.push([rect(0, 1, L, 14, b), rect(0, 1, 1, 14, "M"), rect(L - 1, 1, 1, 14, "M"), px(L - 1, 1, "q"), px(0, 1, "q"),
    rect(L - 2, 2, 2, 3, "y"), rect(L - 2, 11, 2, 3, "y"), rect(L - 1, 5, 1, 6, "t"),
    rect(0, 2, 1, 3, "r"), rect(0, 11, 1, 3, "r"), rect(0, 6, 1, 4, "q"), px(0, 7, "B"), ...seams(B),
    ...(spec.patch ? [rect(c0 + 1, 1, mid - c0 - 1, 1, "o"), rect(c0 + 1, 14, mid - c0 - 1, 1, "o")] : [])])
  // 3: the body with its chrome trim, door handles
  sl.push([rect(0, 1, L, 14, b), hline(2, 1, L - 4, "M"), hline(2, 14, L - 4, "M"), ...seams(B), px(c0 + 3, 1, "q"), px(mid + 3, 1, "q"), px(c0 + 3, 14, "q"), px(mid + 3, 14, "q"),
    ...(spec.patch ? [rect(c0 + 1, 1, mid - c0 - 1, 1, "o"), rect(c0 + 1, 14, mid - c0 - 1, 1, "o"), px(5, 1, "S"), px(L - 6, 14, "S"), px(9, 14, "S")] : [])])
  if (spec.tall) {
    // vans and trucks: three more body slices with side windows, then the roof
    sl.push([rect(0, 1, L, 14, b), rect(L - 5, 2, 4, 12, glass[0]), rect(3, 1, L - 10, 1, glass[0]), rect(3, 14, L - 10, 1, glass[0])],
      [rect(0, 1, L, 14, b), rect(L - 5, 2, 4, 12, glass[1]), px(L - 4, 3, "w")],
      [rect(0, 1, L, 14, b), hline(1, 1, L - 2, Lt), hline(1, 14, L - 2, B)],
      [rect(0, 1, L, 14, R), rect(1, 2, L - 2, 12, Lt), rect(2, 3, Math.floor(L / 3), 4, "q")])
  } else {
    // 4: the hood and trunk lids, lit: a crease down the hood, the trunk's seam, features
    const top = [rect(0, 1, L, 14, Lt), rect(1, 2, L - 2, 12, b), hline(c1 + 1, 7, L - c1 - 3, Lt), hline(c1 + 1, 8, L - c1 - 3, Lt), vline(Math.max(c0 - 2, 2), 3, 10, B)]
    if (spec.bed) top.push(rect(2, 3, c0 - 3, 10, "{"), hline(2, 7, c0 - 3, "}"))                       // the open bed
    if (spec.fins) top.push(rect(0, 1, 6, 2, Lt), rect(0, 13, 6, 2, Lt), px(0, 2, "r"), px(0, 13, "r"))  // tail fins
    if (spec.ornament) top.push(px(L - 2, 7, "q"), px(L - 2, 8, "q"))                                   // the hood ornament
    if (spec.stripes) top.push(hline(0, 6, L, "q"), hline(0, 9, L, "q"))                                // racing stripes
    if (spec.scoop) top.push(rect(c1 + 3, 6, 5, 4, "t"), hline(c1 + 3, 6, 5, B))                         // a hood scoop
    if (spec.patch) top.push(px(4, 3, "S"), px(5, 4, "S"), px(L - 5, 11, "S"), px(c1 + 4, 4, "o"))       // rust
    sl.push(top)
    // 5-6: the greenhouse: glass all round, the pillars, a streak of reflected sky
    const bedWalls = spec.bed ? [rect(1, 1, c0 - 1, 1, b), rect(1, 14, c0 - 1, 1, b), rect(1, 1, 1, 14, b)] : []
    const pillars = [rect(c0, 2, 1, 1, b), rect(c1 - 1, 2, 1, 1, b), rect(c0, 13, 1, 1, b), rect(c1 - 1, 13, 1, 1, b), rect(mid, 2, 1, 12, b)]
    const hatch = spec.hatch ? [rect(1, 3, c0 - 1, 10, glass[1])] : []
    sl.push([rect(c0, 2, c1 - c0, 12, glass[0]), ...pillars, line(c0 + 2, 3, c0 + 5, 12, glass[1]), ...bedWalls, ...hatch,
      ...(spec.fins ? [px(1, 1, Lt), px(1, 14, Lt)] : [])])
    sl.push([rect(c0, 2, c1 - c0, 12, glass[1]), rect(mid, 2, 1, 12, b), rect(c0 + 1, 3, c1 - c0 - 2, 10, glass[0]), px(c1 - 3, 4, "q"), ...bedWalls])
    // 7: the roof, its lit corner, the antenna; or nothing (a convertible racer) and its wing
    const roof = spec.low ? [] : [rect(c0 + 1, 3, c1 - c0 - 2, 10, R), rect(c0 + 2, 4, c1 - c0 - 4, 8, b), rect(c0 + 2, 4, Math.floor((c1 - c0) / 2), 2, Lt), px(c0 + 1, 3, "M")]
    if (spec.wing) roof.push(rect(0, 1, 3, 14, "t"), hline(0, 1, 3, "q"))                               // the racer's rear wing
    if (spec.rack) roof.push(hline(c0 + 1, 4, c1 - c0 - 2, "t"), hline(c0 + 1, 11, c1 - c0 - 2, "t"))   // a roof rack
    if (spec.rod) roof.push(line(1, 3, L - 1, 12, "q"), px(c0 + 3, 6, "M"), px(c0 + 3, 7, "t"))          // ...and the fishing rod on it
    sl.push(roof)
  }
  return sl
}
const SEDAN = carSlices({ len: 30, cab: [9, 22], keys: { b: "b", B: "B", Lt: "L", R: "R" } })
SEDAN.forEach((ops, i) => sprite(`_stack_${i}`, { w: 30, h: 16 }, ...ops))
const STACK_BODIES = { blue: null, ...BODIES }
for (const [name, body] of Object.entries(STACK_BODIES))
  SEDAN.forEach((_, i) => body
    ? sprite(`stack_${name}_${i}`, { base: `_stack_${i}`, swap: { b: body[0], B: body[1], L: body[2], R: body[3] } })
    : sprite(`stack_${name}_${i}`, { base: `_stack_${i}` }))

// --- Neon (#36): the red GAZ BAR sign from the references, on a dark board -----------------------
pal({ N: "#ff4a3a", Q: "#ffb0a0", j: "#141016", J: "#2a1e22" })
sprite("neon_gazbar", { w: 30, h: 26, outline: "J" },
  rect(0, 0, 30, 26, "j"),
  ring(15, 13, 0, "j"),
  text(15, 3, "GAZ", "N", { scale: 2, align: "c", gap: 1 }),
  text(15, 14, "BAR", "N", { scale: 2, align: "c", gap: 1 }),
  rect(1, 1, 28, 1, "N"), rect(1, 24, 28, 1, "N"), rect(1, 1, 1, 24, "N"), rect(28, 1, 1, 24, "N"))
// The same sign switched off, for the neon's flicker.
sprite("neon_gazbar_off", { base: "neon_gazbar", swap: { N: "#5a2a26" } })

// =============================================================================================
// Round 4 (#36): the real nozzle, the vintage pump, the tip jar, funnels and gauges, the regulars.
// =============================================================================================
pal({
  q: "#efe6cf", Q: "#cdbf9c",            // cream (dials, signs)
  T: "#8fa3ad", U: "#c9d8de", Y: "#e8f2f4",   // jar glass: edge, glass, glint
  F: "#2f8a3e", Z: "#5a3a22", I: "#7a5232", l: "#a87a4e",   // sign green; wood dark, mid, light
})

// --- The nozzle, after the reference photo: red molded body and hump, a steel spout with a spring
// collar, a black trigger guard and lever. The hand grips the handle; squeezing pulls the lever in.
function nozzle(name, squeeze) {
  // No hand (god-pump playtest 5): the nozzle alone, its lever squeezed up against the body to pour.
  sprite(name, { w: 58, h: 46, outline: "k" },
    capsule(0, 45, 2.5, 9, 36, 2.5, "kKm"),                    // hose into the handle
    capsule(9, 36, 5, 22, 16, 4.5, "Eef"),                     // red handle
    capsule(20, 15, 6, 34, 13, 6, "Eef"),                      // red head
    circ(27, 9, 5, "e"), circ(26, 8, 3, "f"),                  // the hump
    capsule(36, 13, 2.5, 54, 36, 1.5, "kKmM"),                 // steel spout
    (c) => { for (let i = 0; i < 4; i++) c.line(37 + i * 2, 10 + i * 2, 35 + i * 2, 14 + i * 2, "M") },   // spring collar
    capsule(13, 36, 1.4, 33, 33, 1.4, "k"), capsule(33, 33, 1.4, 35, 20, 1.4, "k"),   // trigger guard
    squeeze ? capsule(33, 21, 2, 19, 25, 1.6, "kKm") : capsule(33, 21, 2, 25, 32, 1.6, "kKm"))   // the lever
}
nozzle("nozzle_idle", false)
nozzle("nozzle_squeeze", true)

// --- The vintage pump (reference: a red pump with a white globe and a clock-face dial). The game
// draws the dial's needle at (17, 41): it shows the round's gas.
sprite("pump_hud", { w: 34, h: 78, outline: "k" },
  circ(17, 10, 9, "q"), circ(14, 7, 4, "w"), text(17, 8, "GAZ", "e", { align: "c" }),   // white globe
  rect(9, 19, 16, 3, "K"),                                    // cap
  rect(3, 22, 28, 52, "e"), rect(3, 22, 3, 52, "f"), rect(28, 22, 3, 52, "E"),   // red body
  rect(7, 30, 20, 22, "E"), rect(8, 31, 18, 20, "q"),         // dial frame and face
  (c) => { for (let i = 0; i <= 8; i++) { const a = Math.PI * (1 - i / 8); c.px(Math.round(17 + Math.cos(a) * 7), Math.round(41 - Math.sin(a) * 7), "k") } },
  text(17, 45, "E   F", "K", { align: "c" }),
  rect(31, 44, 3, 4, "m"),                                    // hose outlet on the side
  rect(5, 58, 24, 3, "E"), text(17, 63, "1985", "q", { align: "c" }),
  rect(1, 74, 32, 4, "K"))

// --- Tip jar: a glass jar with a red TIPS label and a tin lid. Coins inside are drawn by the game.
sprite("tip_jar", { w: 24, h: 28 },
  rect(5, 0, 14, 3, "m"), rect(5, 0, 14, 1, "M"),             // lid
  rect(3, 3, 18, 25, "T"), rect(4, 4, 16, 23, "U"),           // glass
  rect(5, 5, 2, 18, "Y"),                                     // glint
  rect(4, 13, 16, 7, "e"), text(12, 14, "TIPS", "q", { align: "c" }))

// --- On each car: a cartoon funnel in the roof, and a dial gauge (empty to full; the needle is the game's).
sprite("funnel", { w: 14, h: 11, outline: "k" },
  ellipse(7, 3, 6, 3, "h"), ellipse(7, 3, 4, 2, "G"),        // wide yellow mouth
  poly([2, 4, 12, 4, 9, 8, 5, 8], "e"), rect(5, 8, 4, 3, "E"))
sprite("gauge_face", { w: 26, h: 15, outline: "k" },
  circ(13, 14, 12, "q"), rect(0, 14, 26, 1, "q"),
  (c) => { for (let i = 0; i <= 10; i++) { const a = Math.PI * (1 - i / 10); c.px(Math.round(13 + Math.cos(a) * 10), Math.round(14 - Math.sin(a) * 10), i >= 8 ? "F" : "k") } },
  text(4, 9, "E", "r"), text(20, 9, "F", "F"))

// --- The regulars, seated, after the reference photos. Two poses: hanging out, and cheering.
function regular(name, o) {
  // A third pose (playtest 6): applauding, hands together in front of the chest.
  sprite(name + "_clap", { w: 18, h: 26, outline: "k" },
    rect(4, 19, 4, 6, o.pants), rect(10, 19, 4, 6, o.pants), rect(3, 24, 5, 2, "K"), rect(10, 24, 5, 2, "K"),
    rect(3, 16, 12, 4, o.pants), rect(3, 8, 12, 9, o.shirt),
    ...(o.check ? [(c) => { for (let y = 8; y < 17; y += 2) for (let x = 3 + (y % 4 ? 1 : 0); x < 15; x += 2) c.px(x, y, o.check) }] : []),
    rect(4, 9, 3, 4, o.shirt), rect(11, 9, 3, 4, o.shirt), rect(7, 11, 4, 2, o.shirt), circ(9, 11, 1, "s"),
    circ(9, 4, 4, "s"), rect(5, 0, 8, 3, o.hair), px(7, 4, "k"), px(11, 4, "k"),
    rect(8, 6, 3, 2, "k"),                                    // open mouth: "BRAVO!"
    ...(o.glasses ? [ring(7, 4, 1, "K"), ring(11, 4, 1, "K")] : []))
  for (const cheer of [false, true]) {
    sprite(name + (cheer ? "_cheer" : ""), { w: 18, h: 26, outline: "k" },
      rect(4, 19, 4, 6, o.pants), rect(10, 19, 4, 6, o.pants), rect(3, 24, 5, 2, "K"), rect(10, 24, 5, 2, "K"),   // legs, shoes
      rect(3, 16, 12, 4, o.pants),                             // lap
      rect(3, 8, 12, 9, o.shirt), ...(o.check ? [(c) => { for (let y = 8; y < 17; y += 2) for (let x = 3 + (y % 4 ? 1 : 0); x < 15; x += 2) c.px(x, y, o.check) }] : []),
      ...(cheer ? [rect(0, 1, 3, 9, o.shirt), rect(15, 1, 3, 9, o.shirt), circ(1, 1, 1, "s"), circ(16, 1, 1, "s")]   // arms up
            : [rect(1, 9, 3, 8, o.shirt), rect(14, 9, 3, 8, o.shirt), circ(2, 17, 1, "s"), circ(15, 17, 1, "s")]),
      circ(9, 4, 4, "s"), rect(5, 0, 8, 3, o.hair),            // head and hair
      px(7, 4, "k"), px(11, 4, "k"),                           // eyes
      o.moustache ? rect(7, 6, 5, 1, o.hair) : px(9, 6, "S"),
      ...(o.glasses ? [ring(7, 4, 1, "K"), ring(11, 4, 1, "K")] : []),
      ...(o.beer && !cheer ? [rect(15, 12, 2, 5, "Z"), px(15, 11, "q")] : []),
      ...(o.beer && cheer ? [rect(16, 0, 2, 4, "Z")] : []))
  }
}
regular("regular_0", { shirt: "r", check: "E", pants: "R", hair: "Z", moustache: true })            // plaid, moustache, jeans
regular("regular_1", { shirt: "I", pants: "l", hair: "P", glasses: true })                         // brown jacket, glasses
regular("regular_2", { shirt: "P", pants: "Q", hair: "p" })                                         // grey cardigan, beige pants
regular("regular_3", { shirt: "j", pants: "R", hair: "k", beer: true })                             // leather jacket, a beer

sprite("bench", { w: 80, h: 12, outline: "k" },
  rect(0, 0, 80, 3, "l"), rect(0, 3, 80, 1, "I"), rect(0, 5, 80, 3, "I"),
  rect(4, 8, 3, 4, "Z"), rect(73, 8, 3, 4, "Z"), rect(38, 8, 3, 4, "Z"))

sprite("clock_face", { w: 13, h: 13, outline: "k" }, circ(6, 6, 6, "q"),
  px(6, 1, "k"), px(11, 6, "k"), px(6, 11, "k"), px(1, 6, "k"))
sprite("sign_ouvert", { w: 28, h: 9, outline: "k" }, rect(0, 0, 28, 9, "q"), text(14, 2, "OUVERT", "F", { align: "c" }))
sprite("sign_ferme", { w: 28, h: 9, outline: "k" }, rect(0, 0, 28, 9, "q"), text(14, 2, "FERME", "r", { align: "c" }), px(19, 0, "r"), px(20, 1, "r"))

// Neon variants for the pinball flash: only GAZ lit, only BAR lit.
sprite("neon_gaz", { base: "neon_gazbar", swap: {} }, rect(2, 14, 26, 10, "j"), text(15, 14, "BAR", "#5a2a26", { scale: 2, align: "c", gap: 1 }))
sprite("neon_bar", { base: "neon_gazbar", swap: {} }, rect(2, 2, 26, 11, "j"), text(15, 3, "GAZ", "#5a2a26", { scale: 2, align: "c", gap: 1 }))

// --- HD-2D try (#36): the store's front as one texture for the 3D facade. The clock and the
// OUVERT/FERME sign are separate sprites so they can move.
pal({ D: "#d9c9a3", "2": "#b8a57e", "3": "#33404a", "4": "#c7ccd0", "5": "#8a6a44", "6": "#4a5a66" })
sprite("storefront", { w: 132, h: 44 },
  rect(0, 0, 132, 44, "D"), rect(0, 40, 132, 4, "2"), rect(0, 0, 132, 2, "2"),
  rect(6, 8, 78, 28, "3"),                                      // the glass front
  (c) => {
    const items = "rgbwFhe"
    for (let shelf = 0; shelf < 3; shelf++) {
      const y = 12 + shelf * 8
      c.rect(7, y + 4, 76, 1, "5")                              // shelf board
      for (let x = 9, i = shelf; x < 82; x += 4, i++) c.rect(x, y, 2, 4, items[i % items.length])
    }
    for (let m = 6; m <= 84; m += 19.5) c.rect(Math.round(m), 8, 1, 28, "4")   // aluminium mullions
  },
  rect(6, 8, 78, 1, "4"), rect(6, 35, 78, 1, "4"),
  rect(92, 8, 18, 32, "3"), rect(92, 8, 18, 1, "4"), rect(92, 8, 1, 32, "4"), rect(109, 8, 1, 32, "4"),   // the door
  rect(93, 9, 3, 30, "6"))


// =============================================================================================
// Playtest 6 (HD-2D): the ground and the junk around the lot, after the satellite photos.
// =============================================================================================
pal({ "7": "#3e2c1e", "8": "#4a3424", "9": "#55402c", "0": "#4a6a2e", "!": "#5f8a3a", "@": "#7aa34a",
      "~": "#8f9086", "$": "#a8a99e", "%": "#6e6f68", "^": "#c9b03a", "&": "#2a2a2a" })

// Darker, patchier dirt (the satellite lots are packed brown earth with stones).
sprite("dirt2", { w: 32, h: 32 }, rect(0, 0, 32, 32, "8"), (c) => specks(c, 32, 32, "79~", 120, 17))
// Patches of grass to scatter on the dirt.
function grass(name, w, h, seed) {
  sprite(name, { w, h }, (c) => {
    let s = seed
    for (let i = 0; i < w * h * 0.55; i++) {
      s = (s * 1103515245 + 12345) % 2147483648; const x = (s >> 16) % w
      s = (s * 1103515245 + 12345) % 2147483648; const y = (s >> 16) % h
      const dx = (x - w / 2) / (w / 2), dy = (y - h / 2) / (h / 2)
      if (dx * dx + dy * dy < 1) c.px(x, y, "0!@"[i % 3])
    }
  })
}
grass("grass_a", 24, 16, 5)
grass("grass_b", 32, 20, 9)
grass("grass_c", 16, 12, 13)
sprite("oil_stain", { w: 20, h: 12 }, ellipse(10, 6, 9, 5, "&"), ellipse(8, 5, 4, 2, "%"))
sprite("crack", { w: 32, h: 8 }, line(0, 4, 8, 2, "&"), line(8, 2, 15, 5, "&"), line(15, 5, 24, 3, "&"), line(24, 3, 31, 6, "&"), line(15, 5, 17, 7, "&"))
sprite("hatch", { w: 16, h: 16 }, rect(0, 0, 16, 16, "a"), (c) => { for (let i = -16; i < 16; i += 6) c.line(i, 16, i + 16, 0, "^") })
sprite("concrete", { w: 32, h: 32 }, rect(0, 0, 32, 32, "$"), (c) => specks(c, 32, 32, "~%", 40, 23))

// A maple: round canopy, a trunk; drawn upright, it stands in the 3D scene.
sprite("tree", { w: 40, h: 56, outline: "k" },
  rect(18, 34, 5, 22, "Z"), rect(18, 34, 2, 22, "I"),
  circ(20, 18, 16, "0"), circ(13, 22, 10, "!"), circ(27, 20, 11, "!"), circ(17, 12, 9, "@"), circ(25, 10, 6, "@"))
// A pile of old tyres, and a green garbage container (the satellite photos have both).
sprite("tire_pile", { w: 30, h: 22, outline: "k" },
  ellipse(8, 17, 7, 4, "t"), ellipse(8, 17, 3, 1, "K"), ellipse(22, 17, 7, 4, "t"), ellipse(22, 17, 3, 1, "K"),
  ellipse(15, 11, 7, 4, "t"), ellipse(15, 11, 3, 1, "K"), ellipse(15, 5, 7, 4, "t"), ellipse(15, 5, 3, 1, "K"))
sprite("dumpster", { w: 34, h: 24, outline: "k" },
  rect(0, 6, 34, 18, "V"), rect(0, 6, 34, 3, "v"), rect(2, 10, 30, 1, "u"), rect(0, 3, 34, 4, "u"),
  rect(4, 22, 4, 2, "K"), rect(26, 22, 4, 2, "K"), text(17, 13, "DECHETS", "q", { align: "c" }))
// The rundown car: the sedan stack, rusted brown, a wheel missing.
const RUST = { b: "#7a4a2a", B: "#5a341c", L: "#9a6a44", R: "#4a2a16", w: "#556066", W: "#3c464c", y: "#665544", M: "#6a5a4a" }
SEDAN.forEach((_, i) => sprite(`stack_rust_${i}`, { base: `_stack_${i}`, swap: RUST }, ...(i <= 1 ? [rect(20, 0, 6, 3, "_")] : [])))

// =============================================================================================
// GOD PUMP car types (#37): one sprite stack per type, from a generic shape description, plus a badge
// floating over the troublemakers so they read at a glance.
// =============================================================================================
pal({ "<": "#e8c33a", ">": "#a8861a", "{": "#222226", "}": "#3a3a42", "[": "#8ab8a0", "]": "#3d7a5a", "|": "#d0d0c8" })

const K4 = (b, B, Lt, R) => ({ b, B, Lt, R })
function stackSlices(name, spec) {
  carSlices(spec).forEach((ops, i) => sprite(`stack_${name}_${i}`, { w: spec.len, h: 16 }, ...ops, ...(spec.extra ? spec.extra(i) : [])))
}
stackSlices("pickup", { len: 36, cab: [17, 26], bed: true, keys: K4("#3e6a8a", "#28465c", "#6a94b4", "#1e3446") })
stackSlices("cadillac", { len: 38, cab: [15, 27], fins: true, ornament: true, keys: K4("#e8e4da", "#b8b2a4", "#fbf8f0", "#9a2a2a") })
stackSlices("bazou", { len: 28, cab: [9, 20], patch: true, keys: K4("#8a5a3a", "#5e3a22", "#a87a54", "#4a2a16") })
stackSlices("racer", { len: 30, cab: [12, 20], low: true, stripes: true, wing: true, keys: K4("#d0302a", "#8a1a16", "#f06050", "#2a2a2a") })
stackSlices("sweeper", { len: 32, cab: [22, 30], tall: true, keys: K4("<", ">", "#f2dc6a", "#6a5a1a"),
  extra: (i) => i <= 1 ? [circ(4, 2, 2, "M"), circ(4, 13, 2, "M")] : (i === 7 ? [rect(10, 6, 6, 4, "o")] : []) })
stackSlices("thief", { len: 30, cab: [10, 21], tint: true, scoop: true, keys: K4("{", "#121214", "}", "#0a0a0c") })
stackSlices("clumsy", { len: 32, cab: [22, 30], tall: true, keys: K4("#8a8a6a", "#5a5a44", "#aaa88a", "#4a4a38"),
  extra: (i) => i === 3 || i === 4 ? [px(8, 1, "K"), px(9, 1, "K"), px(20, 14, "K"), px(21, 14, "K")] : [] })
stackSlices("electric", { len: 24, cab: [8, 18], keys: K4("[", "]", "#b4dcc4", "#2a5a40"),
  extra: (i) => i === 7 ? [text(13, 6, "E", "y", { align: "c" })] : [] })
// Dad's car (the ending): the faded orange 70s hatchback from the reference, a fishing rod on the roof rack.
stackSlices("papa", { len: 28, cab: [6, 19], hatch: true, rack: true, rod: true, keys: K4("#d06a2c", "#a04c1c", "#ec9a5e", "#8a3e16") })

// Badges floating over the troublemakers.
sprite("badge_thief", { w: 14, h: 10, outline: "k" }, rect(0, 2, 14, 5, "{"), rect(2, 3, 3, 3, "w"), rect(9, 3, 3, 3, "w"), px(3, 4, "k"), px(10, 4, "k"))
sprite("badge_electric", { w: 10, h: 14, outline: "k" }, poly([6, 0, 1, 8, 5, 8, 3, 13, 9, 5, 5, 5], "y"))
sprite("badge_sweeper", { w: 12, h: 14, outline: "k" }, rect(5, 0, 2, 9, "n"), poly([1, 9, 11, 9, 12, 13, 0, 13], "<"))
sprite("badge_clamp", { w: 14, h: 12, outline: "k" }, circ(6, 6, 5, "t"), circ(6, 6, 2, "M"), rect(2, 2, 10, 3, "<"), rect(9, 5, 5, 4, "<"), px(11, 6, "k"))   // round 9: a wheel clamp
sprite("badge_clumsy", { w: 14, h: 10, outline: "k" }, circ(3, 5, 2, "y"), circ(10, 3, 2, "y"), px(7, 8, "y"))

// Drone nozzle (#37): a little quadcopter carrying a mini red nozzle. Two frames: rotors spinning.
function droneSprite(name, blur) {
  sprite(name, { w: 24, h: 14, outline: "k" },
    rect(8, 4, 8, 5, "e"), rect(8, 4, 8, 2, "f"), rect(10, 9, 4, 2, "m"), rect(11, 11, 2, 3, "K"),   // body, nozzle
    hline(1, 3, 7, "m"), hline(16, 3, 7, "m"),
    ...(blur ? [ellipse(4, 2, 4, 1, "W"), ellipse(19, 2, 4, 1, "W")] : [hline(1, 2, 7, "K"), hline(16, 2, 7, "K")]))
}
droneSprite("drone_0", false)
droneSprite("drone_1", true)

// =============================================================================================
// Upgrade props for the HD-2D station (#37): every night-shop upgrade shows on the lot.
// Upright sprites that stand in the 3D scene; they pop in the morning after you buy them.
// =============================================================================================
pal({ "*": "#d9d2c0", "+": "#3a8ac8", "=": "#c8e4f4", ",": "#7a7a7a" })
sprite("prop_traffic_light", { w: 10, h: 40, outline: "k" }, rect(4, 12, 2, 28, "M"), rect(1, 0, 8, 14, "K"), circ(5, 3, 2, "r"), circ(5, 7, 2, "y"), circ(5, 11, 2, "g"))
sprite("prop_sandwich", { w: 18, h: 20, outline: "k" }, poly([2, 19, 6, 0, 12, 0, 16, 19], "n"), rect(5, 3, 8, 10, "w"), text(9, 4, "GAZ", "r", { align: "c" }), text(9, 9, "!", "r", { align: "c" }))
sprite("prop_antenna", { w: 12, h: 30, outline: "k" }, rect(5, 0, 2, 30, "m"), hline(1, 6, 10, "m"), hline(2, 12, 8, "m"), hline(3, 18, 6, "m"), px(6, 0, "r"))
sprite("prop_billboard", { w: 64, h: 40, outline: "k" }, rect(6, 22, 3, 18, "n"), rect(55, 22, 3, 18, "n"), rect(0, 0, 64, 24, "w"), rect(2, 2, 60, 20, "e"),
  text(32, 5, "GOD PUMP", "y", { align: "c", scale: 1 }), text(32, 13, "EXIT ->", "w", { align: "c" }))
sprite("prop_grocery", { w: 30, h: 22, outline: "k" }, rect(0, 4, 30, 18, "W"), rect(0, 0, 30, 6, "g"), (c) => { for (let x = 0; x < 30; x += 6) c.rect(x, 0, 3, 6, "w") },
  text(15, 9, "EPICERIE", "G", { align: "c" }), rect(4, 15, 6, 7, "r"), rect(12, 15, 6, 7, "y"), rect(20, 15, 6, 7, "o"))
sprite("prop_car_wash", { w: 50, h: 40, outline: "k" }, rect(0, 10, 50, 30, "*"), rect(0, 6, 50, 6, "+"), rect(10, 16, 30, 24, "K"), (c) => { for (let x = 12; x < 40; x += 4) c.rect(x, 17, 2, 20, "+") },
  text(25, 0, "LAVE-AUTO", "+", { align: "c" }), circ(6, 20, 2, "="), circ(44, 24, 3, "="), circ(46, 14, 2, "="))
sprite("prop_loto", { w: 16, h: 28, outline: "k" }, rect(0, 4, 16, 24, "r"), rect(2, 6, 12, 8, "y"), text(8, 7, "LOTO", "r", { align: "c" }), rect(3, 17, 10, 3, "K"), rect(6, 22, 4, 3, "W"))
sprite("prop_fuel_tank", { w: 40, h: 22, outline: "k" }, rect(4, 2, 32, 14, "w"), ellipse(4, 9, 3, 7, "W"), ellipse(36, 9, 3, 7, "w"), rect(6, 16, 3, 6, ","), rect(31, 16, 3, 6, ","), hline(6, 4, 28, "r"))
sprite("prop_lamp", { w: 10, h: 44, outline: "k" }, rect(4, 6, 2, 38, "M"), rect(0, 0, 10, 6, "K"), rect(2, 4, 6, 2, "y"))
sprite("prop_cousin", { w: 18, h: 30, outline: "k" }, rect(5, 22, 3, 8, "R"), rect(10, 22, 3, 8, "R"), rect(3, 10, 12, 13, "+"), rect(1, 11, 3, 9, "+"), rect(14, 11, 3, 9, "+"),
  circ(9, 6, 4, "s"), rect(5, 1, 8, 3, "k"), px(7, 6, "k"), px(11, 6, "k"), rect(6, 13, 6, 2, "w"), text(9, 16, "R", "w", { align: "c" }))
sprite("prop_thermos", { w: 8, h: 16, outline: "k" }, rect(1, 2, 6, 14, "r"), rect(1, 0, 6, 3, "M"), rect(2, 7, 4, 4, "w"))
sprite("prop_coffee", { w: 16, h: 26, outline: "k" }, rect(0, 0, 16, 26, "K"), rect(2, 2, 12, 6, "N"), text(8, 3, "CAFE", "y", { align: "c" }), rect(5, 14, 6, 6, "w"), rect(6, 15, 4, 2, "N"))
sprite("prop_tip_sign", { w: 22, h: 14, outline: "k" }, rect(0, 0, 22, 14, "w"), text(11, 2, "TIPS", "g", { align: "c" }), text(11, 8, "MERCI", "r", { align: "c" }))
sprite("prop_bucket", { w: 12, h: 14, outline: "k" }, poly([1, 4, 11, 4, 10, 13, 2, 13], "+"), rect(5, 0, 2, 8, "n"), rect(2, 0, 8, 2, "K"))
sprite("prop_boombox", { w: 20, h: 12, outline: "k" }, rect(0, 2, 20, 10, "M"), circ(5, 7, 3, "K"), circ(15, 7, 3, "K"), rect(8, 4, 4, 2, "c"), rect(6, 0, 8, 2, "m"))
sprite("prop_cooler", { w: 18, h: 12, outline: "k" }, rect(0, 2, 18, 10, "+"), rect(0, 0, 18, 3, "w"), rect(7, 5, 4, 2, "w"))
sprite("prop_jukebox", { w: 18, h: 30, outline: "k" }, rect(0, 8, 18, 22, "p"), circ(9, 8, 8, "p"), rect(3, 8, 12, 10, "y"), rect(3, 20, 12, 6, "P"), circ(9, 5, 3, "o"))
sprite("prop_tank_gauge", { w: 14, h: 18, outline: "k" }, rect(0, 0, 14, 18, "w"), circ(7, 7, 5, "W"), line(7, 7, 10, 4, "r"), text(7, 12, "TK", "K", { align: "c" }))
