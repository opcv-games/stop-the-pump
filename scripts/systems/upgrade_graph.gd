class_name UpgradeGraph
extends RefCounted
## The night shop as one tree (#31), Bills-style: the station sits in the centre, the five branches
## leave it in different directions, and each pump's own tree hangs off its pump node. This file is
## the model (what each node is, where it sits, whether it is owned); UpgradeTreeView draws it.
## Serves: Advancement (see where the station can go) and Discovery (plan a route).

enum { OWNED, AVAILABLE, LOCKED }

const MAX_PUMPS := 5
## Lattice cells (x right, y down) of each branch's nodes, in buying order. Lines run along the
## lattice, so neighbours are one step apart, straight or diagonal.
const BRANCH_CELLS := {
	"marketing": [Vector2i(-1, -1), Vector2i(-2, -2), Vector2i(-3, -3)],
	"tank": [Vector2i(-1, 0), Vector2i(-2, 0), Vector2i(-3, 0)],
	"service": [Vector2i(-1, 1), Vector2i(-2, 2), Vector2i(-3, 3)],
	"vibe": [Vector2i(0, -1), Vector2i(0, -2)],
	"pumps": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)],
}
## Each pump's tree grows straight up or down from its pump node, alternating so they interleave.
const PUMP_TREE_DIR := [1, -1, 1, -1, 1]
## Big moments get a diamond, like Bills' keystones.
const KEYSTONES := ["billboard", "expand", "tank_3", "pressure_washer", "jukebox", "card_deal"]
const ICONS := {
	"pump_2": "pump", "pump_3": "pump", "pump_4": "pump", "pump_5": "pump",
	"tank_1": "tank", "tank_2": "tank", "tank_3": "tank",
}


## Every node of the tree, with its state for this station right now.
static func build(station: Node) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	nodes.append({"key": "root", "kind": "root", "cell": Vector2i.ZERO, "parent": "", "state": OWNED,
		"keystone": true, "icon": "station", "name": station.station_name if station.station_name != "" else "Your station",
		"helps": "where it all starts", "price": 0.0, "branch": -1, "level": 0, "pump": -1})
	var pump_cells := {0: Vector2i.ZERO}
	var pump_parent := {0: "root"}
	for bi in Upgrades.BRANCHES.size():
		var b: Dictionary = Upgrades.BRANCHES[bi]
		var level: int = station.owned.get(b.id, 0)
		var cells: Array = BRANCH_CELLS[b.id]
		for li in b.nodes.size():
			var node: Dictionary = b.nodes[li]
			var key := "b:%s:%d" % [b.id, li]
			nodes.append({"key": key, "kind": "branch", "cell": cells[li],
				"parent": "root" if li == 0 else "b:%s:%d" % [b.id, li - 1],
				"state": OWNED if li < level else (AVAILABLE if li == level else LOCKED),
				"keystone": node.id in KEYSTONES, "icon": ICONS.get(node.id, node.id),
				"name": node.name, "helps": node.helps, "price": roundf(node.price * station.shop_price_scale),
				"branch": bi, "level": li, "pump": -1, "branch_name": b.name})
			if node.id.begins_with("pump_"):
				var p := int(node.id.trim_prefix("pump_")) - 1
				pump_cells[p] = cells[li]
				pump_parent[p] = key
	for p in MAX_PUMPS:
		var built: bool = p < station.bays.size()
		var pump_level: int = station.bays[p].pump_level if built else 0
		for li in Upgrades.PUMP_TREE.size():
			var node: Dictionary = Upgrades.PUMP_TREE[li]
			var state := LOCKED
			if built:
				state = OWNED if li < pump_level else (AVAILABLE if li == pump_level else LOCKED)
			nodes.append({"key": "p:%d:%d" % [p, li], "kind": "pump",
				"cell": pump_cells[p] + Vector2i(0, PUMP_TREE_DIR[p] * (li + 1)),
				"parent": pump_parent[p] if li == 0 else "p:%d:%d" % [p, li - 1],
				"state": state, "keystone": node.id in KEYSTONES, "icon": node.id,
				"name": "Pump %d: %s" % [p + 1, node.name], "helps": node.helps,
				"price": roundf(node.price * station.shop_price_scale), "branch": -1, "level": li, "pump": p})
	return nodes


## Buys `node` if it is the next one in its branch or pump tree. True when bought.
static func buy(station: Node, node: Dictionary) -> bool:
	if node.state != AVAILABLE:
		return false
	match node.kind:
		"branch":
			return station.buy(node.branch)
		"pump":
			return station.buy_pump(node.pump)
	return false
