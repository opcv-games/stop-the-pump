// GOD PUMP icons (#37): one 16x16 pixel icon per shop node, truck card and garage item, drawn as code
// with claude-pxl. Build: node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/icons.px.js --out assets/art/pixel/out
// Named icon_<id> to match GodData ids. Warm palette, gold accents, black outline.

pal({
  k: "#1d1a1f", K: "#4a4450", w: "#f2ead8", W: "#c9bfa8", y: "#ffd34d", Y: "#c98a1c", o: "#e88a2c",
  r: "#d8483c", R: "#8e2a22", g: "#5fb04a", G: "#2f6e2a", b: "#5a8fd0", B: "#2d4f86", c: "#8fd6e8",
  p: "#b07ad0", P: "#5e3a7a", s: "#e9a77f", S: "#a86a4a", m: "#9a9aa2", M: "#5a5a62", n: "#7a5232", N: "#4a3020",
})

const I = (id, ...ops) => sprite("icon_" + id, { w: 16, h: 16, outline: "k" }, ...ops)

// --- Shared glyphs -------------------------------------------------------------------------
const clock = (col) => [circ(8, 8, 6, "w"), ring(8, 8, 6, col), vline(8, 4, 5, "k"), hline(8, 8, 3, "k")]
const paper = (col) => [rect(3, 2, 10, 12, "w"), hline(5, 5, 6, col), hline(5, 8, 6, col), hline(5, 11, 4, col)]
const drone = (col) => [rect(5, 7, 6, 4, col), rect(6, 11, 4, 1, "M"), hline(1, 5, 5, "m"), hline(10, 5, 5, "m"), vline(3, 5, 2, "M"), vline(12, 5, 2, "M"), px(7, 8, "c"), px(8, 8, "c")]
const nozzle = (body, spout) => [capsule(2, 12, 2, 7, 6, 2, body), capsule(7, 6, 2.2, 10, 5, 2.2, body), capsule(10, 5, 1.2, 14, 11, 0.8, spout)]
const tank = (n) => [rect(2, 5, 12, 7, "w"), rect(2, 5, 12, 2, "W"), rect(3, 12, 2, 2, "M"), rect(11, 12, 2, 2, "M"), text(8, 6, n, "r", { align: "c" })]
const coins = (n) => Array.from({ length: n }, (_, i) => [ellipse(8, 12 - i * 2, 5, 2, "Y"), ellipse(8, 11 - i * 2, 5, 2, "y")]).flat()

// --- The night shop --------------------------------------------------------------------------
I("station", rect(2, 7, 12, 7, "w"), poly([1, 7, 8, 2, 15, 7], "M"), rect(4, 9, 4, 3, "c"), rect(10, 9, 2, 5, "n"))
I("thermos", rect(5, 3, 6, 11, "r"), rect(5, 3, 6, 2, "M"), rect(6, 7, 4, 3, "w"), px(11, 6, "k"))
I("mom_lunch", circ(5, 6, 3, "r"), circ(11, 6, 3, "r"), poly([2, 7, 14, 7, 8, 14], "r"), px(5, 5, "w"))
I("permit", ...paper("b"), circ(11, 11, 2, "r"))
I("cousin", circ(8, 8, 6, "y"), circ(10, 6, 5, "k"), px(4, 4, "w"), px(13, 12, "w"))
I("flyers", ...paper("r"), rect(4, 3, 8, 3, "y"))
I("radio_ad", rect(2, 6, 12, 8, "n"), circ(6, 10, 2, "K"), rect(10, 8, 3, 1, "w"), rect(10, 10, 3, 1, "w"), line(4, 6, 10, 2, "m"))
I("billboard", rect(1, 2, 14, 7, "w"), rect(2, 3, 12, 2, "r"), vline(5, 9, 6, "n"), vline(11, 9, 6, "n"))
I("traffic_light", rect(5, 1, 6, 13, "K"), circ(8, 4, 1, "r"), circ(8, 7, 1, "y"), circ(8, 10, 1, "g"), vline(8, 14, 2, "M"))
I("grocery", poly([3, 6, 13, 6, 12, 14, 4, 14], "W"), rect(5, 2, 2, 5, "r"), rect(8, 3, 2, 4, "g"), rect(11, 4, 1, 3, "y"))
I("car_wash", circ(5, 6, 2, "c"), circ(11, 4, 2, "c"), circ(9, 9, 1, "c"), rect(2, 11, 12, 3, "b"), rect(4, 10, 8, 2, "b"))
I("loto", rect(2, 4, 12, 8, "y"), text(8, 5, "7", "r", { align: "c" }), px(3, 5, "k"), px(12, 10, "k"))
I("wide", ...nozzle("r", "m"), poly([14, 11, 16, 15, 10, 15], "c"))
I("aim_1", ring(8, 8, 5, "r"), hline(1, 8, 4, "r"), hline(11, 8, 4, "r"), vline(8, 1, 4, "r"), vline(8, 11, 4, "r"), px(8, 8, "r"))
I("aim_2", ring(8, 8, 5, "y"), ring(8, 8, 2, "y"), hline(1, 8, 3, "y"), hline(12, 8, 3, "y"), vline(8, 1, 3, "y"), vline(8, 12, 3, "y"))
I("flow_1", poly([2, 6, 9, 6, 9, 3, 14, 8, 9, 13, 9, 10, 2, 10], "o"))
I("drone_1", ...drone("r"))
I("drone_2", ...drone("b"), text(12, 0, "2", "y"))
I("tip_sign", rect(2, 3, 12, 8, "w"), text(8, 4, "$", "g", { align: "c" }), vline(8, 11, 4, "n"))
I("squeegee", rect(2, 3, 12, 3, "K"), rect(3, 6, 10, 1, "M"), capsule(8, 7, 1, 11, 14, 1, "n"))
I("coffee", rect(3, 6, 8, 8, "w"), rect(4, 7, 6, 2, "N"), ring(12, 9, 2, "w"), line(5, 4, 6, 2, "W"), line(8, 4, 9, 2, "W"))
I("radio", rect(2, 6, 12, 8, "Y"), circ(6, 10, 2, "N"), rect(10, 8, 3, 4, "N"), line(3, 6, 9, 2, "m"))
I("bench", rect(1, 5, 14, 2, "n"), rect(1, 8, 14, 2, "n"), rect(2, 10, 2, 4, "N"), rect(12, 10, 2, 4, "N"))
I("jukebox", rect(3, 4, 10, 11, "p"), circ(8, 4, 5, "p"), rect(5, 6, 6, 5, "y"), rect(5, 12, 6, 2, "P"))
I("tank_1", ...tank("I"))
I("tank_2", ...tank("II"))
I("tank_3", ...tank("III"))

// --- Truck cards -----------------------------------------------------------------------------
I("happy_hour", rect(4, 4, 7, 10, "y"), rect(4, 4, 7, 3, "w"), ring(12, 8, 2, "W"), px(6, 9, "Y"), px(8, 11, "Y"))
I("gas_saver", poly([8, 1, 13, 8, 8, 15, 3, 8], "g"), vline(8, 4, 10, "G"))
I("rush_hour", rect(1, 7, 14, 5, "r"), rect(4, 4, 7, 4, "r"), rect(5, 5, 2, 2, "c"), rect(8, 5, 2, 2, "c"), circ(4, 12, 2, "K"), circ(12, 12, 2, "K"))
I("gold_rush", poly([2, 12, 5, 6, 11, 6, 14, 12], "y"), poly([5, 6, 11, 6, 10, 8, 6, 8], "w"))
I("combo_lock", rect(3, 7, 10, 8, "y"), ring(8, 6, 3, "m"), rect(5, 6, 6, 1, "y"), px(8, 10, "k"), px(8, 11, "k"))
I("fat_tips", ...coins(4))
I("twin_stream", capsule(4, 2, 2, 4, 12, 1, "y"), capsule(11, 2, 2, 11, 12, 1, "y"), px(4, 14, "y"), px(11, 14, "y"))
I("magnet", poly([2, 3, 6, 3, 6, 9, 10, 9, 10, 3, 14, 3, 14, 10, 8, 15, 2, 10], "r"), rect(2, 3, 4, 2, "m"), rect(10, 3, 4, 2, "m"))
I("drone_card", ...drone("y"))
I("price_freeze", hline(1, 8, 14, "c"), vline(8, 1, 14, "c"), line(3, 3, 13, 13, "c"), line(13, 3, 3, 13, "c"), circ(8, 8, 1, "w"))
I("encourage", circ(5, 8, 3, "s"), circ(11, 8, 3, "s"), line(2, 3, 4, 5, "y"), line(14, 3, 12, 5, "y"), line(8, 1, 8, 4, "y"))
I("golden_hose", ...nozzle("y", "Y"), px(14, 13, "y"), px(14, 15, "y"))
I("recycler", capsule(3, 10, 1.5, 8, 3, 1.5, "g"), capsule(8, 3, 1.5, 13, 10, 1.5, "g"), capsule(13, 10, 1.5, 3, 10, 1.5, "g"))
I("devil", circ(8, 9, 5, "r"), poly([3, 5, 4, 1, 6, 4], "r"), poly([13, 5, 12, 1, 10, 4], "r"), px(6, 8, "y"), px(10, 8, "y"), hline(6, 11, 5, "R"))
I("loan", circ(8, 10, 5, "W"), rect(6, 3, 4, 3, "W"), text(8, 7, "$", "g", { align: "c" }))

// --- Papa's Garage: nozzles ------------------------------------------------------------------
I("classique", ...nozzle("r", "m"))
I("douche", ...nozzle("r", "m"), circ(14, 13, 2, "m"), px(12, 15, "c"), px(15, 15, "c"))
I("laser", ...nozzle("b", "c"), line(14, 11, 15, 15, "c"))
I("lente", ...nozzle("g", "m"), circ(4, 4, 2, "S"))
I("gros_calibre", capsule(2, 12, 3, 7, 6, 3, "K"), capsule(7, 6, 3, 10, 5, 3, "K"), capsule(10, 5, 2.2, 14, 12, 2, "M"))
I("doree", ...nozzle("y", "Y"), px(2, 2, "w"), px(13, 3, "w"))

// --- Bling ---------------------------------------------------------------------------------
I("fuzzy_dice", rect(2, 5, 6, 6, "w"), rect(8, 7, 6, 6, "r"), px(4, 7, "k"), px(6, 9, "k"), px(10, 9, "w"), px(12, 11, "w"), vline(5, 1, 4, "K"), vline(11, 1, 6, "K"))
I("flame_decal", poly([8, 1, 13, 9, 11, 15, 5, 15, 3, 9], "o"), poly([8, 6, 10, 11, 8, 14, 6, 11], "y"))
I("chrome_tip", capsule(3, 12, 2, 12, 3, 2, "m"), capsule(5, 10, 1, 11, 4, 1, "w"))
I("hula", circ(8, 3, 2, "s"), rect(6, 5, 4, 4, "s"), poly([4, 9, 12, 9, 13, 13, 3, 13], "g"), rect(6, 13, 4, 2, "s"))
I("pine", poly([8, 1, 13, 8, 10, 8, 14, 13, 2, 13, 6, 8, 3, 8], "g"), rect(7, 13, 2, 2, "n"))
I("medal", poly([5, 1, 8, 6, 11, 1], "b"), circ(8, 10, 4, "y"), circ(8, 10, 2, "Y"))
I("rabbit", capsule(8, 13, 3, 8, 6, 2, "w"), circ(6, 3, 1, "w"), circ(10, 3, 1, "w"), rect(7, 14, 2, 1, "y"))
I("bobblehead", circ(8, 5, 4, "s"), rect(6, 9, 4, 5, "b"), px(6, 5, "k"), px(10, 5, "k"), hline(7, 7, 3, "k"), rect(4, 14, 8, 1, "K"))
I("coupons", ...paper("g"), line(2, 4, 6, 8, "M"), line(2, 8, 6, 4, "M"))
I("receipt", rect(4, 1, 8, 14, "w"), hline(5, 3, 6, "K"), hline(5, 5, 4, "K"), hline(5, 7, 6, "K"), text(8, 9, "$", "g", { align: "c" }))

// --- Perks ---------------------------------------------------------------------------------
I("truck_friend", rect(1, 5, 9, 7, "w"), rect(10, 7, 5, 5, "r"), rect(11, 8, 2, 2, "c"), circ(4, 12, 2, "K"), circ(12, 12, 2, "K"))
I("lucky", poly([8, 1, 10, 6, 15, 6, 11, 9, 13, 15, 8, 11, 3, 15, 5, 9, 1, 6, 6, 6], "y"))
I("big_cards", rect(1, 3, 7, 10, "w"), rect(5, 2, 7, 10, "W"), rect(9, 4, 6, 10, "y"))
I("reroll", capsule(3, 8, 1.5, 8, 3, 1.5, "b"), capsule(8, 3, 1.5, 13, 8, 1.5, "b"), capsule(13, 8, 1.5, 8, 13, 1.5, "b"), poly([1, 8, 5, 8, 3, 11], "b"))
I("morning_rush", circ(8, 11, 4, "y"), hline(1, 13, 14, "o"), line(8, 1, 8, 4, "y"), line(2, 5, 4, 7, "y"), line(14, 5, 12, 7, "y"))
I("jackpot", rect(1, 3, 14, 10, "r"), rect(2, 5, 3, 6, "w"), rect(6, 5, 3, 6, "w"), rect(10, 5, 3, 6, "w"), px(3, 8, "r"), px(7, 8, "r"), px(11, 8, "r"))
I("slot", rect(3, 3, 10, 10, "K"), hline(5, 8, 6, "y"), vline(8, 5, 6, "y"))
I("contract", ...paper("K"), line(6, 13, 12, 11, "b"), poly([11, 1, 15, 5, 13, 7, 9, 3], "y"))
I("premium", rect(4, 3, 8, 12, "r"), rect(5, 5, 6, 4, "w"), text(8, 5, "S", "r", { align: "c" }), rect(12, 5, 2, 6, "K"), rect(6, 1, 4, 2, "K"))
I("head_start", ...drone("g"), poly([12, 1, 15, 3, 12, 5], "y"))
I("nest_egg", poly([5, 2, 11, 2, 11, 9, 14, 12, 12, 15, 5, 15, 5, 9], "r"), hline(5, 4, 6, "w"), text(8, 9, "$", "y", { align: "c" }))

// --- Round 8: the CAMION branch, the upgrades with two parents, the tube man ------------------------
I("tank_gauge", circ(7, 9, 6, "w"), ring(7, 9, 6, "K"), line(7, 9, 3, 6, "r"), px(7, 9, "k"), circ(13, 3, 2, "r"), px(12, 2, "y"))
I("bulk", rect(1, 5, 6, 10, "r"), rect(9, 5, 6, 10, "r"), hline(1, 8, 6, "R"), hline(1, 12, 6, "R"), hline(9, 8, 6, "R"), hline(9, 12, 6, "R"),
  ellipse(4, 5, 3, 1, "R"), ellipse(12, 5, 3, 1, "R"), text(8, 0, "%", "y", { align: "c" }))
I("used_tanker", capsule(4, 8, 3, 9, 8, 3, "Mm"), rect(11, 5, 4, 6, "r"), rect(12, 6, 2, 2, "c"), rect(1, 11, 14, 1, "K"),
  circ(4, 13, 1, "k"), circ(11, 13, 1, "k"), px(5, 7, "o"), px(8, 9, "o"), px(3, 9, "S"))
I("drive_thru", rect(1, 2, 14, 10, "W"), rect(2, 3, 12, 6, "c"), rect(2, 9, 12, 2, "n"), rect(6, 9, 4, 5, "w"), rect(6, 9, 4, 1, "N"), px(10, 11, "w"), px(11, 11, "w"))
I("hockey", line(3, 1, 9, 12, "n", 2), poly([8, 11, 15, 11, 15, 14, 8, 14], "n"), ellipse(4, 13, 3, 1, "k"), px(3, 12, "K"))
I("loyalty", rect(1, 3, 14, 10, "w"), rect(1, 3, 14, 3, "b"), circ(4, 9, 1, "k"), circ(8, 9, 1, "k"), circ(12, 9, 1, "W"), text(12, 3, "5", "y", { align: "c" }))
I("night_neons", rect(1, 1, 14, 14, "N"), ring(8, 8, 5, "p"), poly([4, 7, 9, 7, 9, 4, 13, 8, 9, 12, 9, 9, 4, 9], "r"), px(2, 2, "y"), px(13, 3, "w"))
I("drone_hangar", poly([1, 15, 1, 8, 4, 4, 8, 2, 12, 4, 15, 8, 15, 15], "M"), poly([3, 15, 3, 9, 5, 6, 8, 5, 11, 6, 13, 9, 13, 15], "k"),
  rect(6, 10, 4, 3, "r"), hline(4, 9, 3, "m"), hline(9, 9, 3, "m"))
I("chip_truck", rect(1, 6, 13, 7, "w"), rect(1, 6, 13, 2, "r"), rect(4, 8, 5, 3, "c"), rect(10, 9, 3, 4, "W"), circ(4, 13, 1, "k"), circ(11, 13, 1, "k"),
  poly([5, 5, 9, 5, 8, 1, 6, 1], "r"), vline(6, 0, 2, "y"), vline(8, 0, 2, "y"), px(7, 0, "y"))
I("price_board", rect(3, 0, 10, 11, "M"), rect(4, 1, 8, 4, "k"), text(8, 1, "1", "r", { align: "c" }), rect(4, 6, 8, 4, "k"), text(8, 6, "9", "r", { align: "c" }), vline(7, 11, 5, "m"), vline(8, 11, 5, "M"))
I("forward_contract", ...paper("K"), rect(8, 8, 7, 6, "y"), ring(11, 7, 2, "M"), rect(10, 10, 2, 2, "k"))
I("tube_man", curve([7, 15, 8, 11, 6, 8, 8, 5], "o", { width: 3 }), circ(8, 4, 2, "o"), px(7, 4, "k"), px(9, 4, "k"),
  curve([7, 8, 3, 5, 1, 1], "r", { width: 2 }), curve([8, 7, 12, 6, 15, 2], "r", { width: 2 }), rect(5, 14, 6, 2, "M"))

// --- Round 9: the wheel clamps (Sabot de Denver) -------------------------------------------------
I("clamp_1", circ(7, 9, 6, "k"), circ(7, 9, 3, "m"), rect(2, 3, 11, 3, "y"), rect(10, 6, 5, 5, "y"), px(12, 8, "k"))
I("clamp_2", circ(7, 9, 6, "k"), circ(7, 9, 3, "m"), rect(2, 3, 11, 3, "y"), rect(10, 6, 5, 5, "y"), px(12, 8, "k"), text(13, 0, "2", "r"))
