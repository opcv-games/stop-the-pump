// GOD PUMP round 8: the bling on the nozzle (Papa's Garage). Small pieces that hang off or stand on the
// nozzle, and overlays the size of the nozzle sprite (nozzle_idle, 60x48 with its outline) that paint
// onto it. Drawn at 1x, shown at 2x with the nozzle.
//   node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/bling.px.js --out assets/art/pixel/out

pal({
  k: "#1d1a1f", K: "#3a3540", w: "#f4efe2", W: "#cfc6b0", a: "#141214",
  r: "#e0402e", R: "#9a2418", p: "#ff7ab8", P: "#c0407e",            // dice pink, red
  g: "#3f9a46", G: "#256a2c", l: "#8ad07a",                         // pine
  y: "#ffd34d", Y: "#c98a1c", o: "#ffe9a0",                          // gold
  s: "#e9a77f", S: "#b8724e", h: "#3a2416", f: "#f06a2a", F: "#ffb830", // skin, hair, flames
  c: "#e8f4f8", C: "#9fb4c0", m: "#6f7c86",                          // chrome
  b: "#5a8fd0", q: "#e9e2cc",
})

// Fuzzy dice: one die, fluffy (a ragged edge), pink with white pips.
sprite("bling_die", { w: 7, h: 7, outline: "P" }, rect(0, 0, 7, 7, "p"), px(0, 0, "_"), px(6, 6, "_"), px(1, 1, "w"), px(5, 5, "w"), px(3, 3, "w"), px(5, 1, "w"), px(1, 5, "w"))
// The pine air freshener, on its string.
sprite("bling_pine", { w: 7, h: 11, outline: "G" }, poly([3, 0, 6, 4, 4, 4, 7, 8, 4, 8, 4, 10, 3, 10, 3, 8, 0, 8, 3, 4, 1, 4], "g"), px(3, 2, "l"), px(2, 6, "l"))
// Saint Christophe: a little gold medal.
sprite("bling_medal", { w: 6, h: 6, outline: "Y" }, circ(3, 3, 3, "y"), px(2, 2, "o"), px(3, 3, "Y"), px(3, 4, "Y"))
// The rabbit's foot: white fur, a gold cap.
sprite("bling_rabbit", { w: 5, h: 8, outline: "K" }, rect(1, 0, 3, 2, "y"), ellipse(2, 5, 2, 3, "w"), px(1, 4, "W"), px(3, 6, "W"))
// The hula girl, standing on the nozzle: grass skirt, a lei, arms out (her hips sway in game).
sprite("bling_hula", { w: 9, h: 14, outline: "k" },
  circ(4, 2, 2, "s"), rect(2, 0, 5, 2, "h"), rect(3, 4, 3, 3, "s"), hline(2, 5, 5, "p"), line(1, 5, 0, 3, "s"), line(7, 5, 8, 3, "s"),
  poly([1, 7, 8, 7, 9, 11, 0, 11], "g"), vline(2, 8, 3, "G"), vline(5, 8, 3, "G"), rect(1, 11, 7, 3, "Y"))
// The bobblehead: a body, and a head the game bobs on its spring.
sprite("bling_bobble_body", { w: 5, h: 5, outline: "k" }, rect(1, 0, 3, 3, "b"), rect(0, 3, 5, 2, "Y"), px(2, 1, "w"))
sprite("bling_bobble_head", { w: 7, h: 7, outline: "k" }, circ(3, 3, 3, "s"), rect(1, 0, 5, 2, "h"), px(2, 3, "a"), px(4, 3, "a"), hline(2, 5, 3, "R"))

// Overlays on the nozzle (same canvas as nozzle_idle's PNG: 60x48, drawing coordinates + 1).
// Flame decal: flames licking back along the red handle and head.
sprite("bling_flames", { w: 60, h: 48 },
  poly([12, 34, 15, 30, 14, 33, 18, 27, 17, 31, 21, 24, 20, 29, 23, 26, 21, 33, 16, 36], "f"),
  poly([14, 33, 17, 29, 17, 32, 20, 27, 19, 32, 15, 35], "F"),
  poly([24, 18, 28, 14, 27, 17, 31, 13, 30, 16, 34, 13, 33, 18, 26, 20], "f"), poly([26, 18, 29, 15, 29, 17, 32, 15, 31, 18], "F"))
// Chrome tip: the spout polished to a mirror.
sprite("bling_chrome", { w: 60, h: 48 }, capsule(37, 14, 2.6, 55, 37, 1.6, "mCc"), line(38, 13, 53, 33, "c"), px(54, 36, "w"))
// The coupon book, tucked under a rubber band on the handle.
sprite("bling_coupons", { w: 60, h: 48 }, rect(5, 28, 7, 5, "q"), rect(5, 28, 7, 1, "w"), hline(6, 30, 5, "g"), rect(5, 31, 7, 1, "G"), line(4, 33, 13, 29, "R"))
// The old receipt, curling off the head.
sprite("bling_receipt", { w: 60, h: 48 }, poly([33, 9, 37, 7, 40, 10, 38, 12, 34, 12], "w"), hline(35, 9, 3, "W"), hline(35, 11, 2, "W"), px(39, 10, "W"))
