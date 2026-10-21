// GOD PUMP round 8: the regulars, bigger and alive. Four characters, each in every pose the lot needs:
// standing, a 4-frame walk, seated on the bench, cheering, clapping and carrying a coffee (standing
// and seated). Seen from the front (they're billboards in the HD-2D scene); light from the upper left.
//   node ~/Tools/claude-pxl/bin/pxl.js build assets/art/pixel/people.px.js --out assets/art/pixel/out

pal({ k: "#1d1a1f", K: "#3a3540", a: "#141214", w: "#f4efe2", W: "#cfc6b0", q: "#e9e2cc", v: "#c8ccd0" })
shades("sSt", "#e9a77f", { hue: 10 })      // skin
shades("rRe", "#c8402e", { hue: 12 })      // plaid red
shades("bBn", "#4f6f9e", { hue: 14 })      // denim
shades("pPi", "#e48ab0", { hue: 12 })      // pink cardigan
shades("gGh", "#8a8a84", { hue: 8 })       // greys
shades("lLm", "#2c2a30", { hue: 8 })       // leather
shades("oOu", "#7a5232", { hue: 12 })      // browns
pal({ c: "#3f7a46", C: "#ffd34d", x: "#2a1c14", X: "#c9c4b8", y: "#ffd34d", Y: "#c98a1c", z: "#8a5a2a", Z: "#6a3a1a", f: "#fff7d6" })

const CAST = {
  // Ti-Guy: short, red plaid flannel, jeans, a moustache and a trucker cap.
  tiguy: { h: 34, w: 10, skin: "S", top: "R", lit: "r", check: "e", pants: "B", plit: "b", shoes: "x",
    hair: "x", cap: "c", moustache: "x" },
  // Mme Gagnon: grey curls in a bun, glasses, a pink cardigan over a white blouse, a brown skirt, a purse.
  gagnon: { h: 33, w: 9, skin: "S", top: "P", lit: "p", inner: "w", pants: "o", plit: "O", skirt: true, legs: "X", shoes: "a",
    hair: "h", bun: true, glasses: "G", purse: "O" },
  // Bertrand: bald with a grey fringe, a big belly in an undershirt, suspenders, grey slacks, slippers.
  bertrand: { h: 35, w: 12, skin: "S", top: "w", lit: "w", belly: true, suspenders: "R", pants: "G", plit: "g", shoes: "o",
    hair: "h", bald: true },
  // Le Grand: tall and thin, a black leather jacket, a mullet, faded jeans, white sneakers, a beer.
  legrand: { h: 42, w: 9, skin: "S", top: "L", lit: "l", inner: "w", pants: "b", plit: "n", shoes: "w",
    hair: "z", mullet: true, beer: true },
}

const CX = 12, FEET = 45

function person(c, o, pose) {
  const sit = pose.sit, H = o.h
  // Seated: the legs fold (a short lap seen from the front, shins down to the floor), so the body sits lower.
  const legLen = Math.round(H * 0.45)
  const shin = Math.round(legLen * 0.42)
  const drop = sit ? legLen - shin - 2 : 0   // seen from the front, a seated body loses its thighs
  const bob = pose.bob || 0
  const top = FEET - H + drop - bob
  const headY = top + 4, neckY = top + 9, shY = neckY + 1
  const hipY = FEET - legLen + drop - bob
  const w = o.w, L = CX - Math.floor(w / 2), Rr = L + w - 1
  // --- legs and shoes
  if (sit) {
    const kneeY = hipY + 2
    c.rect(L - 1, hipY, w + 2, 3, o.pants); c.hline(L - 1, hipY, w + 2, o.plit)       // the lap, knees apart
    c.rect(CX - 6, kneeY, 3, FEET - 1 - kneeY, o.legs || o.pants); c.rect(CX + 3, kneeY, 3, FEET - 1 - kneeY, o.legs || o.pants)
    c.rect(CX - 7, FEET - 1, 4, 2, o.shoes); c.rect(CX + 3, FEET - 1, 4, 2, o.shoes)
  } else {
    const spread = pose.walk === 0 ? 2 : pose.walk === 2 ? -2 : 0
    const lx = CX - 4 - (spread > 0 ? 1 : 0), rx = CX + 1 + (spread < 0 ? 1 : 0)
    const lLen = FEET - 2 - hipY - (pose.walk === 0 ? 1 : 0), rLen = FEET - 2 - hipY - (pose.walk === 2 ? 1 : 0)
    if (o.skirt) {
      c.poly([L, hipY, Rr + 1, hipY, Rr + 2, hipY + 8, L - 1, hipY + 8], o.pants); c.hline(L, hipY, w, o.plit)
      c.rect(lx + 1, hipY + 8, 2, lLen - 8, o.legs); c.rect(rx, hipY + 8, 2, rLen - 8, o.legs)
    } else {
      c.rect(lx, hipY, 3, lLen, o.pants); c.rect(rx, hipY, 3, rLen, o.pants); c.vline(lx, hipY, lLen, o.plit)
    }
    c.rect(lx - 1, hipY + lLen, 4, 2, o.shoes); c.rect(rx, hipY + rLen, 4, 2, o.shoes)
  }
  // --- the torso, its pattern, the belly, suspenders
  c.rect(L, shY, w, hipY - shY + (o.skirt ? 1 : 0), o.top)
  c.vline(L, shY, hipY - shY, o.lit)
  if (o.inner) c.rect(CX - 1, shY, 2, Math.min(6, hipY - shY), o.inner)                 // the blouse, the T-shirt
  if (o.check) for (let yy = shY; yy < hipY; yy += 2) for (let xx = L + ((yy - shY) % 4 ? 1 : 0); xx <= Rr; xx += 2) c.px(xx, yy, o.check)
  if (o.belly) { c.ellipse(CX, hipY - 4, Math.floor(w / 2) + 1, 4, o.top); c.px(CX - 3, hipY - 6, "W"); c.hline(CX - 2, hipY - 1, 5, "W") }
  if (o.suspenders) { c.vline(L + 2, shY, hipY - shY, o.suspenders); c.vline(Rr - 2, shY, hipY - shY, o.suspenders) }
  // --- arms
  const armL = L - 2, armR = Rr + 1
  const arm = (x, y0, y1) => { c.rect(x, y0, 2, y1 - y0, o.top); c.px(x, y0, o.lit) }
  const hand = (x, y) => c.rect(x, y, 2, 2, o.skin)
  const swing = pose.walk === 0 ? 1 : pose.walk === 2 ? -1 : 0
  const handY = hipY + 1
  if (pose.arms === "up") {                                  // cheering: both arms thrown up
    arm(armL - 1, top - 3, shY + 2); arm(armR + 1, top - 3, shY + 2); hand(armL - 1, top - 5); hand(armR + 1, top - 5)
  } else if (pose.arms === "clap") {                         // applauding: hands together at the chest
    c.line(armL + 1, shY + 1, CX - 1, shY + 6, o.top, 2); c.line(armR, shY + 1, CX + 1, shY + 6, o.top, 2); hand(CX - 1, shY + 5)
  } else if (pose.arms === "coffee") {                       // a coffee from inside: cup at the chest, steam
    arm(armL, shY + 1, handY); hand(armL, handY)
    c.line(armR, shY + 1, armR, shY + 6, o.top, 2); c.line(armR, shY + 6, CX + 2, shY + 7, o.top, 2)
    c.rect(CX + 1, shY + 5, 3, 3, "w"); c.hline(CX + 1, shY + 5, 3, "W"); c.px(CX + 2, shY + 3, "v"); c.px(CX + 3, shY + 1, "v")
  } else {                                                   // hanging, or swinging as they walk
    arm(armL, shY + 1, handY - swing); arm(armR, shY + 1, handY + swing); hand(armL, handY - swing); hand(armR, handY + swing)
    if (o.beer && !pose.walk && pose.walk !== 0) { c.rect(armR + 1, handY - 3, 2, 4, "Z"); c.px(armR + 1, handY - 4, "f") }
    if (o.purse && !sit) { c.line(armL, shY + 2, armL - 1, handY, "O"); c.rect(armL - 3, handY, 4, 4, o.purse); c.hline(armL - 3, handY, 4, "u") }
  }
  // --- the head
  c.circ(CX, headY, 4, o.skin); c.px(CX - 2, headY - 2, "t"); c.px(CX + 3, headY + 1, "s")
  c.px(CX - 2, headY, "a"); c.px(CX + 2, headY, "a")                                      // eyes
  if (o.glasses) { c.ring(CX - 2, headY, 1, o.glasses); c.ring(CX + 2, headY, 1, o.glasses) }
  const cheering = pose.arms === "up" || pose.arms === "clap"
  if (o.moustache) c.hline(CX - 2, headY + 2, 5, o.moustache)
  if (cheering) c.rect(CX - 1, headY + 2 + (o.moustache ? 1 : 0), 3, 2, "a")             // mouth open: BRAVO!
  else if (!o.moustache) c.hline(CX - 1, headY + 2, 3, "s")
  // hair, hats
  if (o.cap) { c.rect(CX - 4, headY - 5, 9, 3, o.cap); c.rect(CX + 2, headY - 3, 5, 1, o.cap); c.px(CX - 1, headY - 4, "C") }
  else if (o.bald) { c.px(CX - 4, headY, o.hair); c.px(CX - 4, headY - 1, o.hair); c.px(CX + 4, headY, o.hair); c.px(CX + 4, headY - 1, o.hair); c.px(CX - 1, headY - 3, "w") }
  else if (o.bun) { c.rect(CX - 4, headY - 5, 9, 3, o.hair); c.circ(CX, headY - 6, 2, o.hair); c.px(CX - 4, headY - 2, o.hair); c.px(CX + 4, headY - 2, o.hair) }
  else if (o.mullet) { c.rect(CX - 4, headY - 5, 9, 3, o.hair); c.rect(CX - 5, headY - 3, 2, 7, o.hair); c.rect(CX + 4, headY - 3, 2, 7, o.hair) }
}

const POSES = {
  stand: { arms: "down" },
  walk_0: { arms: "down", walk: 0 }, walk_1: { arms: "down", walk: 1, bob: 1 }, walk_2: { arms: "down", walk: 2 }, walk_3: { arms: "down", walk: 3, bob: 1 },
  cheer: { arms: "up" }, clap: { arms: "clap" }, coffee: { arms: "coffee" },
  sit: { arms: "down", sit: true }, sit_cheer: { arms: "up", sit: true }, sit_clap: { arms: "clap", sit: true }, sit_coffee: { arms: "coffee", sit: true },
}
for (const [name, o] of Object.entries(CAST))
  for (const [pose, p] of Object.entries(POSES))
    sprite(`${name}_${pose}`, { w: 24, h: 47, outline: "k" }, (c) => person(c, o, p))
