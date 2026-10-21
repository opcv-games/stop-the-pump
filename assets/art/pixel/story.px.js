// GOD PUMP round 8: the story's pictures. Dad's postcards (days 10, 20, 30, 40), each a little scene
// from wherever he's "not" fishing. Drawn at 1x, shown at 2x or 3x in the newspaper and the scrapbook.
//   node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/story.px.js --out assets/art/pixel/out

pal({ k: "#1d1a1f", w: "#f4efe2", a: "#141214" })
shades("1234", "#7fb0d8", { hue: 14 })     // sky
shades("5678", "#3a7aa8", { hue: 16 })     // water
shades("9AB", "#2f5a34", { hue: 18 })      // pines
shades("CDE", "#c9b48a", { hue: 10 })      // sand, rock light
shades("FGH", "#b0654a", { hue: 12 })      // Percé's red rock
pal({ s: "#ffd34d", S: "#ff9a3a", o: "#e8743a", r: "#d84838", p: "#ff8ab8", b: "#4a5ad0", g: "#5fa04a", n: "#7a5232", m: "#cfd6de" })

const W = 72, H = 44
// Lac-à-la-Truite: a still lake in the pines, a rowboat, a trout jumping.
sprite("postcard_truite", { w: W, h: H },
  grad(0, 0, W, 20, "4321", "v"), circ(56, 8, 4, "w"),
  (c) => { for (let x = 0; x < W; x += 3) { const h = 8 + ((x * 7) % 5); c.poly([x - 2, 22, x + 1, 22 - h, x + 4, 22], x % 2 ? "9" : "A") } },
  grad(0, 22, W, 22, "8765", "v"), (c) => { for (let i = 0; i < 14; i++) c.hline((i * 13) % 66, 25 + (i * 5) % 17, 4, "6") },
  poly([18, 32, 34, 32, 31, 36, 21, 36], "n"), rect(24, 29, 3, 3, "r"), line(27, 29, 40, 21, "a"), line(40, 21, 44, 33, "w"),
  poly([50, 30, 55, 27, 58, 29, 55, 31], "G"), px(56, 28, "w"), arc(52, 33, 3, 200, 340, "m"))
// Lac Saint-Jean: the big lake to the horizon, a sunset, blueberries in the front.
sprite("postcard_st_jean", { w: W, h: H },
  grad(0, 0, W, 22, "SSo12", "v"), circ(36, 21, 6, "s"),
  grad(0, 21, W, 23, "5678", "v"), (c) => { for (let y = 23; y < 34; y += 2) c.hline(36 - (y - 21), y, (y - 21) * 2, "S") },
  rect(0, 34, W, 10, "9"), (c) => { for (let i = 0; i < 26; i++) c.circ((i * 11) % 70 + 1, 36 + (i * 7) % 7, 1, i % 3 ? "b" : "A") })
// Gaspésie: Percé Rock in the sea, gannets overhead.
sprite("postcard_gaspesie", { w: W, h: H },
  grad(0, 0, W, 24, "4321", "v"), grad(0, 24, W, 20, "6785", "v"),
  poly([14, 34, 18, 12, 46, 8, 60, 14, 62, 34], "G"), poly([16, 34, 20, 14, 30, 11, 32, 34], "H"), poly([44, 34, 46, 24, 52, 24, 54, 34], "6"),
  rect(46, 24, 6, 10, "7"), hline(18, 12, 26, "F"), hline(14, 34, 48, "C"),
  (c) => { for (const [x, y] of [[8, 6], [24, 4], [64, 8], [36, 3]]) { c.px(x, y, "w"); c.px(x - 1, y - 1, "w"); c.px(x + 1, y - 1, "w") } })
// Floride: palm trees, the sun, a pink flamingo on the beach.
sprite("postcard_floride", { w: W, h: H },
  grad(0, 0, W, 26, "S1234", "v"), circ(58, 9, 6, "s"), grad(0, 26, W, 8, "567", "v"), rect(0, 34, W, 10, "D"),
  (c) => { for (const x0 of [12, 26]) { c.line(x0, 36, x0 + 4, 12, "n", 2); for (const [dx, dy] of [[-9, 2], [9, 3], [-6, -4], [7, -3], [0, -6]]) c.line(x0 + 4, 12, x0 + 4 + dx, 12 + dy + 3, "g", 2) } },
  line(48, 40, 48, 33, "p"), line(50, 40, 49, 33, "p"), ellipse(50, 31, 4, 2, "p"), line(53, 30, 55, 24, "p", 2), px(56, 24, "a"), px(57, 25, "a"))
