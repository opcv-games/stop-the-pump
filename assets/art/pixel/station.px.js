// GOD PUMP round 8 (docs/ROUND_8_PLAN.md): the station's own hardware, drawn as code with claude-pxl.
// Build: node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/station.px.js --out assets/art/pixel/out
// Side views, light from the upper left. Shown at 2x or 3x in Godot (nearest filter).

pal({ k: "#1d1a1f", K: "#3a3540" })
shades("1234", "#c9c3b4", { hue: 18 })     // the tank's paint: an off-white gone a little yellow
shades("5678", "#b8342a", { hue: 14 })     // red: the stripe, the cab
shades("9ab", "#8f969c", { hue: 10 })      // galvanised steel: legs, ladder, pipes
shades("cdef", "#a7b0b6", { hue: 22 })     // polished aluminium: the tanker
pal({
  g: "#2a2c30", G: "#4a4e55",              // tyres and rubber, the glass's dark
  y: "#f2c230", Y: "#1c1a18",              // hazard yellow and black
  r: "#8a4a22", R: "#a8642e",              // rust
  w: "#f4efe2", q: "#e9e2cc", Q: "#bdb59e", // white lettering, the dial's face and its rim
  v: "#9fc4d8", V: "#5e7f93", u: "#d8ecf4", // windows: glass, its shade, a glint
  h: "#ffe28a", H: "#fff6cf",              // headlight
  n: "#555a60", N: "#77808a",              // the cabinet's steel
})
ramps("gG")

// --- The station's tank (night screen): a horizontal cylinder with round heads on two steel cradles
// and concrete piers, a ladder up the right head, a manhole and a vent on top, the fill pipe the
// truck's hose locks onto (top left), a red ESSENCE stripe, a dial on the left head and a sight glass
// on its face. The game draws the dial's needle and the gas inside the sight glass:
//   dial centre (12, 24) radius 6; sight glass inside x 62..64, y 11..36; fill pipe mouth (24, 2)
//   (drawing coordinates; the outline adds 1 to each in the PNG).
sprite("gas_tank", { w: 86, h: 56, outline: "k", selout: true },
  // concrete piers with painted hazard stripes, and the steel cradles that hold the shell
  rect(21, 42, 10, 13, "Q"), rect(55, 42, 10, 13, "Q"), rect(21, 42, 10, 1, "q"), rect(55, 42, 10, 1, "q"),
  rect(21, 46, 10, 6, "y"), rect(55, 46, 10, 6, "y"),
  clip([21, 46, 10, 6], (c) => { for (let i = -12; i < 14; i += 4) { c.line(21 + i, 51, 27 + i, 45, "Y"); c.line(22 + i, 51, 28 + i, 45, "Y") } }),
  clip([55, 46, 10, 6], (c) => { for (let i = -12; i < 14; i += 4) { c.line(55 + i, 51, 61 + i, 45, "Y"); c.line(56 + i, 51, 62 + i, 45, "Y") } }),
  rect(21, 46, 10, 1, "Y"), rect(55, 46, 10, 1, "Y"), rect(21, 51, 10, 1, "Y"), rect(55, 51, 10, 1, "Y"),
  rect(19, 36, 14, 7, "9"), rect(53, 36, 14, 7, "9"), rect(19, 42, 14, 1, "b"), rect(53, 42, 14, 1, "b"),
  // the shell: a capsule, lit from the upper left
  capsule(18, 24, 17, 68, 24, 17, "1234"),
  // weld seams (rings), with a lit edge, and a row of rivets on each
  (c) => {
    for (const x of [27, 43, 59]) {
      for (let y = 7; y <= 41; y++) { if (c.is(x, y, "1234")) { c.px(x, y, y < 18 ? "2" : "1"); c.px(x + 1, y, y < 18 ? "4" : "3") } }
      for (let y = 10; y <= 38; y += 4) if (c.is(x - 1, y, "1234")) c.px(x - 1, y, "K")
    }
  },
  // the red stripe and its lettering
  (c) => { for (let x = 0; x < 86; x++) for (let y = 27; y <= 33; y++) if (c.is(x, y, "1234")) c.px(x, y, y === 27 ? "8" : (y === 33 ? "5" : "6")) },
  text(44, 28, "ESSENCE", "w", { align: "c" }),
  // rust weeping from the rivets and the stripe
  (c) => { const R = c.rng(5); for (let i = 0; i < 16; i++) { const x = 8 + Math.floor(R() * 70), y = 12 + Math.floor(R() * 22); for (let d = 0; d < 2 + Math.floor(R() * 4); d++) if (c.is(x, y + d, "1234")) c.px(x, y + d, d < 1 ? "R" : "r") } },
  // on top: the fill pipe (its cap open for the truck), a manhole with bolts, a vent with a rain cap
  rect(22, 2, 5, 6, "a"), rect(21, 1, 7, 2, "9"), rect(21, 1, 7, 1, "b"),
  rect(37, 4, 12, 3, "9"), rect(38, 3, 10, 1, "b"), px(38, 5, "K"), px(47, 5, "K"),
  rect(55, 0, 3, 8, "9"), rect(53, 0, 7, 2, "a"), px(54, 1, "b"),
  // the ladder up the right head
  vline(78, 6, 49, "9"), vline(83, 6, 49, "9"), (c) => { for (let y = 10; y < 55; y += 4) c.hline(79, y, 4, "b") },
  rect(76, 5, 9, 2, "a"),
  // the dial on the left head: cream face, rim, ticks (the game draws the needle)
  circ(12, 24, 7, "Q"), circ(12, 24, 6, "q"),
  (c) => { for (let i = 0; i <= 6; i++) { const a = Math.PI * (1.1 - i * 1.2 / 6); c.px(Math.round(12 + Math.cos(a) * 5), Math.round(24 - Math.sin(a) * 5), i >= 5 ? "6" : "K") } },
  px(12, 24, "k"),
  // the sight glass on the face: a glass tube in two brackets (the game fills it with gas)
  rect(61, 9, 5, 29, "a"), rect(62, 10, 3, 27, "g"), px(62, 11, "G"), px(62, 12, "G"),
  rect(60, 8, 7, 2, "9"), rect(60, 37, 7, 2, "9"),
)

// --- The fuel truck, side view, facing right: an 80s cab-over-engine tractor in faded red and a
// polished aluminium tanker. Its wheels are a separate sprite so the game can turn them; the hose
// leaves the valve cabinet under the tank at (44, 40).
sprite("fuel_truck", { w: 132, h: 50, outline: "k", selout: true },
  // the tanker: a long polished capsule with ring stiffeners, a catwalk and two hatches on top
  capsule(8, 22, 14, 92, 22, 14, "cdef"),
  (c) => { for (const x of [22, 38, 54, 70, 84]) for (let y = 9; y <= 35; y++) if (c.is(x, y, "cdef")) { c.px(x, y, "d"); c.px(x + 1, y, "f") } },
  // a long sky reflection and a dark ground reflection along the polish
  (c) => { for (let x = 6; x < 94; x++) { if (c.is(x, 15, "cdef")) c.px(x, 15, "f"); if (c.is(x, 30, "cdef")) c.px(x, 30, "c") } },
  rect(12, 6, 76, 2, "9"), (c) => { for (let x = 12; x < 88; x += 6) c.vline(x, 3, 3, "a") }, hline(12, 3, 76, "a"),
  rect(30, 6, 8, 3, "a"), rect(58, 6, 8, 3, "a"),
  text(50, 19, "PETROLES ST-CLIN", "6", { align: "c" }),
  // the chassis rail, the valve cabinet with its hose reel, mudflaps, the rear bumper
  rect(4, 36, 104, 3, "K"),
  rect(34, 34, 22, 8, "n"), rect(35, 35, 20, 6, "N"), circ(45, 38, 3, "K"), circ(45, 38, 1, "a"), rect(52, 36, 2, 4, "y"),
  rect(2, 34, 6, 6, "a"), rect(16, 38, 2, 7, "k"), rect(76, 38, 2, 7, "k"),
  // wheel arches (the wheels are drawn by the game)
  rect(6, 38, 22, 12, "_"), rect(64, 38, 14, 12, "_"), rect(104, 38, 14, 12, "_"),
  // the cab: boxy, faded red, a big windshield, a sleeper vent, chrome grille and bumper, a stack
  rect(96, 6, 32, 32, "6"), rect(96, 6, 32, 2, "8"), rect(96, 36, 32, 2, "5"), rect(126, 8, 2, 28, "5"),
  rect(110, 10, 16, 12, "v"), rect(110, 10, 16, 1, "u"), rect(111, 11, 5, 3, "u"), rect(110, 19, 16, 3, "V"),
  rect(99, 10, 9, 10, "v"), rect(99, 18, 9, 2, "V"), px(100, 11, "u"),
  rect(128, 24, 3, 12, "b"), (c) => { for (let y = 25; y < 36; y += 2) c.hline(128, y, 3, "a") },
  rect(127, 22, 4, 3, "h"), px(128, 23, "H"),
  rect(96, 38, 36, 3, "b"), rect(96, 38, 36, 1, "c"),
  rect(92, 0, 3, 36, "b"), rect(92, 0, 3, 1, "c"), rect(93, 2, 1, 30, "c"),   // exhaust stack, chrome
  rect(100, 26, 8, 2, "7"), rect(114, 26, 10, 2, "7"),   // door handle and step trim
  text(112, 28, "31", "w", { align: "c" }),
  rect(104, 38, 14, 12, "_"),
)

// A truck wheel: a black tyre, a steel hub with lug nuts (the game turns it as the truck rolls).
sprite("truck_wheel", { w: 13, h: 13, outline: "k" },
  circ(6, 6, 6, "g"), ring(6, 6, 6, "G"), circ(6, 6, 3, "a"), circ(6, 6, 2, "b"), px(5, 5, "c"),
  px(6, 3, "K"), px(9, 6, "K"), px(6, 9, "K"), px(3, 6, "K"))

// --- Round 8, the night screen: Dad's office wall, 80s wood paneling (a seamless tile) ---------------
pal({ P: "#3a2214", Q: "#523019", R: "#5f3a22", S: "#6e472c" })   // walnut-stained plywood: groove, dark grain, base, light grain
sprite("wood_panel", { w: 48, h: 64, wrap: true },
  rect(0, 0, 48, 64, "R"),
  (c) => {
    for (let x = 0; x < 48; x++) for (let y = 0; y < 64; y++) {
      const plank = Math.floor(x / 12), xl = x % 12
      const warp = fbm(xl * 0.25 + plank * 5.3, y / 22 + plank * 3.1, 3) * 5    // the grain wanders
      const v = Math.sin((xl + warp) * 1.25 + plank)
      c.px(x, y, v > 0.82 ? "S" : v < -0.86 ? "Q" : "R")
    }
    for (let p = 0; p < 4; p++) { c.vline(p * 12, 0, 64, "P"); c.vline(p * 12 + 1, 0, 64, "Q") }   // the grooves between planks
    for (let p = 0; p < 4; p++) c.px(p * 12 + 6, (p * 23 + 9) % 64, "P")                           // a nail in each
  })
