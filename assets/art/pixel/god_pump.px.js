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
    const x = s % w
    s = (s * 1103515245 + 12345) % 2147483648
    const y = s % h
    c.px(x, y, keys[i % keys.length])
  }
}
sprite("asphalt", { w: 32, h: 32 }, rect(0, 0, 32, 32, "a"), (c) => specks(c, 32, 32, "Ai", 70, 7))
sprite("road", { w: 32, h: 32 }, rect(0, 0, 32, 32, "A"), (c) => specks(c, 32, 32, "ai", 40, 3), rect(4, 15, 16, 2, "d"))
sprite("dirt", { w: 32, h: 32 }, rect(0, 0, 32, 32, "x"), (c) => specks(c, 32, 32, "Xz", 90, 11))

// --- Isometric try: sprite-stacked cars (#36) ---------------------------------------------------
// A boxy late-80s sedan (square headlights, chrome bumpers, long hood and trunk) as 8 top-down
// slices, bottom to top. The game stacks them a pixel apart, turned to the car's heading and seen
// through the isometric camera, so one drawing gives every angle.
const SLICES = [
  // 0: tyres and the dark underbody
  [rect(3, 0, 6, 16, "t"), rect(20, 0, 6, 16, "t"), rect(1, 2, 28, 12, "B")],
  // 1: tyres and the lower body
  [rect(3, 0, 6, 16, "t"), rect(20, 0, 6, 16, "t"), rect(0, 1, 30, 14, "B")],
  // 2: body sides, chrome bumpers, square lights
  [rect(0, 1, 30, 14, "b"), rect(0, 1, 1, 14, "M"), rect(29, 1, 1, 14, "M"),
    rect(28, 2, 2, 3, "y"), rect(28, 11, 2, 3, "y"), rect(0, 2, 1, 3, "r"), rect(0, 11, 1, 3, "r")],
  // 3: body with a chrome trim line
  [rect(0, 1, 30, 14, "b"), hline(1, 1, 28, "M"), hline(1, 14, 28, "M")],
  // 4: hood and trunk tops, lit
  [rect(0, 1, 30, 14, "L"), rect(1, 2, 28, 12, "b")],
  // 5-6: the cabin's glass all round, with pillars at the corners
  [rect(9, 2, 13, 12, "w"), rect(9, 2, 1, 1, "b"), rect(21, 2, 1, 1, "b"), rect(9, 13, 1, 1, "b"), rect(21, 13, 1, 1, "b"), rect(14, 2, 1, 12, "b")],
  [rect(9, 2, 13, 12, "W"), rect(14, 2, 1, 12, "b"), rect(10, 3, 11, 10, "w")],
  // 7: the roof
  [rect(10, 3, 11, 10, "R"), rect(11, 4, 9, 8, "b")],
]
SLICES.forEach((ops, i) => sprite(`_stack_${i}`, { w: 30, h: 16 }, ...ops))
const STACK_BODIES = { blue: null, ...BODIES }
for (const [name, body] of Object.entries(STACK_BODIES))
  SLICES.forEach((_, i) => body
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
