extends GutTest
## Spec: features/upgrade_tree.feature (#31): one Bills-style tree grows from the station.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()  # night shop


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _nodes() -> Array[Dictionary]:
	return UpgradeGraph.build(station)


func _node(key: String) -> Dictionary:
	for n in _nodes():
		if n.key == key:
			return n
	return {}


func test_the_station_sits_in_the_centre_and_is_owned() -> void:
	var root := _node("root")
	assert_eq(root.cell, Vector2i.ZERO)
	assert_eq(root.state, UpgradeGraph.OWNED)


func test_every_upgrade_and_pump_upgrade_is_a_node() -> void:
	var count := 1  # the station
	for b in Upgrades.BRANCHES:
		count += b.nodes.size()
	count += UpgradeGraph.MAX_PUMPS * Upgrades.PUMP_TREE.size()
	assert_eq(_nodes().size(), count)


func test_no_two_nodes_share_a_cell() -> void:
	var seen := {}
	for n in _nodes():
		assert_false(seen.has(n.cell), "%s overlaps %s" % [n.key, seen.get(n.cell, "")])
		seen[n.cell] = n.key


func test_every_node_touches_its_parent() -> void:
	var cells := {}
	for n in _nodes():
		cells[n.key] = n.cell
	for n in _nodes():
		if n.key == "root":
			continue
		var d: Vector2i = (n.cell - cells[n.parent]).abs()
		assert_eq(maxi(d.x, d.y), 1, "%s sits next to its parent %s" % [n.key, n.parent])


func test_the_five_branches_leave_the_station_in_different_directions() -> void:
	var first_cells := {}
	for n in _nodes():
		if n.kind == "branch" and n.level == 0:
			first_cells[n.cell] = true
	assert_eq(first_cells.size(), Upgrades.BRANCHES.size())


func test_each_pump_tree_hangs_off_its_pump() -> void:
	assert_eq(_node("p:0:0").parent, "root", "pump 1 is the station's own pump")
	assert_eq(_node("p:1:0").parent, "b:pumps:0", "pump 2's tree hangs off the Pump 2 node")


func test_states_owned_available_locked() -> void:
	assert_eq(_node("b:marketing:0").state, UpgradeGraph.AVAILABLE)
	assert_eq(_node("b:marketing:1").state, UpgradeGraph.LOCKED)
	assert_eq(_node("p:1:0").state, UpgradeGraph.LOCKED, "pump 2 isn't built yet")
	station.buy(0)
	assert_eq(_node("b:marketing:0").state, UpgradeGraph.OWNED)
	assert_eq(_node("b:marketing:1").state, UpgradeGraph.AVAILABLE)


func test_every_node_has_an_icon_file() -> void:
	for n in _nodes():
		assert_true(ResourceLoader.exists("res://assets/art/icons/%s.png" % n.icon), "icon for %s" % n.key)


func test_clicking_an_available_node_buys_it() -> void:
	var cash: float = station.wallet.cash
	assert_true(station.tree_view.press("b:pumps:0"))
	assert_eq(station.bays.size(), 2)
	assert_lt(station.wallet.cash, cash)
	assert_eq(_node("p:1:0").state, UpgradeGraph.AVAILABLE, "pump 2's own tree opens up")


func test_clicking_a_locked_node_does_nothing() -> void:
	var cash: float = station.wallet.cash
	assert_false(station.tree_view.press("b:marketing:2"))
	assert_almost_eq(station.wallet.cash, cash, 0.001)


func test_hovering_a_node_explains_it() -> void:
	var text: String = station.tree_view.tooltip_for("b:marketing:0")
	assert_string_contains(text, "Flyers")
	assert_string_contains(text, "cars arrive 20% sooner")
	assert_string_contains(text, "$80")


func test_the_tree_view_is_shown_in_the_night_shop() -> void:
	assert_true(station.tree_view.is_visible_in_tree())
