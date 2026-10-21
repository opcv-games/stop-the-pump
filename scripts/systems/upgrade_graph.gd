class_name UpgradeGraph
extends RefCounted
## The night shop's station-wide tree (#31), Bills-style: the station sits in the centre and the
## branches leave it in different directions. Pumps are built and improved on the station tab
## instead (#33, StationShopView), so PUMPS and the per-pump trees are not in here. This file is
## the model (what each node is, where it sits, whether it is owned); UpgradeTreeView draws it.
## Serves: Advancement (see where the station can go) and Discovery (plan a route).

enum { OWNED, AVAILABLE, LOCKED }

## Lattice cells (x right, y down) of each branch's nodes, in buying order. Lines run along the
## lattice, so neighbours are one step apart, straight or diagonal.
const BRANCH_CELLS := {
	"marketing": [Vector2i(-1, -1), Vector2i(-2, -2), Vector2i(-3, -3)],
	"vibe": [Vector2i(1, -1), Vector2i(2, -2)],
	"tank": [Vector2i(-1, 1), Vector2i(-2, 2), Vector2i(-3, 3)],
	"service": [Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)],
	"hours": [Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3), Vector2i(0, -4)],
}
## Built and improved on the station tab (#33).
const STATION_TAB_BRANCHES := ["pumps"]
## Big moments get a diamond, like Bills' keystones.
const KEYSTONES := ["billboard", "tank_3", "pressure_washer", "jukebox", "cousin"]
const ICONS := {"tank_1": "tank", "tank_2": "tank", "tank_3": "tank"}


## Every node of the tree, with its state for this station right now.
static func build(station: Node) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	nodes.append({"key": "root", "kind": "root", "cell": Vector2i.ZERO, "parent": "", "state": OWNED,
		"keystone": true, "icon": "station", "name": station.station_name if station.station_name != "" else "Your station",
		"helps": "where it all starts", "price": 0.0, "branch": -1, "level": 0, "pump": -1})
	for bi in Upgrades.BRANCHES.size():
		var b: Dictionary = Upgrades.BRANCHES[bi]
		if b.id in STATION_TAB_BRANCHES:
			continue
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
	return nodes


## Buys `node` if it is the next one in its branch or pump tree. True when bought.
static func buy(station: Node, node: Dictionary) -> bool:
	if node.state != AVAILABLE:
		return false
	return node.kind == "branch" and station.buy(node.branch)
