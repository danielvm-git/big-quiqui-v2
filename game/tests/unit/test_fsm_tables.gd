# story: e11s01
extends GutTest
## INV-06 — every declared FSM table is closed.
##
## BUG-009/012/018/031/038 lineage. An edge that points at a state nobody declares is a
## typo that only shows up as `fsm.illegal_transition` on a child's iPad; a state with no
## inbound edge is dead code the reviewer keeps re-reading. Both are static facts.


func _machines() -> Array[Dictionary]:
	## Every script that declares `LEGAL_EDGES`, paired with its constant map.
	var found: Array[Dictionary] = []
	for path: String in SourceScanner.scripts():
		var constants: Dictionary = SourceScanner.constants_of(path)
		if constants.has("LEGAL_EDGES"):
			found.append({"path": path, "constants": constants})
	assert_gte(found.size(), 8, "the scanner must find the machines, not zero of them")
	return found


func _states(constants: Dictionary) -> Array[String]:
	var states: Array[String] = []
	for key: Variant in constants.keys():
		if str(key).begins_with("STATE_") or str(key).begins_with("RECYCLE_"):
			var value: Variant = constants[key]
			if value is String and not states.has(value):
				states.append(value)
	return states


func test_every_edge_target_is_a_declared_state() -> void:
	for machine: Dictionary in _machines():
		var constants: Dictionary = machine["constants"]
		var states: Array[String] = _states(constants)
		var edges: Dictionary = constants["LEGAL_EDGES"]
		for from_state: Variant in edges.keys():
			for target: Variant in edges[from_state]:
				assert_true(
					states.has(str(target)),
					"%s: edge %s -> %s targets an undeclared state" % [machine["path"], from_state, target]
				)


func test_every_declared_state_is_reachable_or_initial() -> void:
	for machine: Dictionary in _machines():
		var constants: Dictionary = machine["constants"]
		var edges: Dictionary = constants["LEGAL_EDGES"]
		var declared: Dictionary = {}
		for from_state: Variant in edges.keys():
			declared[str(from_state)] = true
			for target: Variant in edges[from_state]:
				declared[str(target)] = true
		for state: String in _states(constants):
			assert_true(declared.has(state), "%s: state %s appears in no edge (dead state)" % [machine["path"], state])


func test_every_dwell_entry_names_a_state() -> void:
	for machine: Dictionary in _machines():
		var constants: Dictionary = machine["constants"]
		var states: Array[String] = _states(constants)
		for key: String in ["MAX_DWELL", "MAX_DWELL_SEC"]:
			if not constants.has(key):
				continue
			var dwell: Dictionary = constants[key]
			for state: Variant in dwell.keys():
				assert_true(
					states.has(str(state)), "%s: dwell declared for unknown state %s" % [machine["path"], state]
				)


func test_an_undeclared_edge_is_inert_and_logged() -> void:
	var fsm: Fsm = Fsm.new("A", {"A": ["B"]}, {})
	assert_false(fsm.transition_to("Z"), "no declared edge, no move")
	assert_eq(fsm.state, "A", "a rejected transition leaves the state untouched")
	assert_false(fsm.transition_to("A"), "a self-edge is a no-op, not an event (CONVENTIONS §4)")
	assert_eq(fsm.state, "A")


func test_transition_from_refuses_a_stale_expected_state() -> void:
	var fsm: Fsm = Fsm.new("A", {"A": ["B"], "B": ["C"]}, {})
	fsm.transition_to("B")
	assert_false(fsm.transition_from("A", "C"), "the world moved on while we awaited")
	assert_eq(fsm.state, "B", "a stale transition must not drag the machine forward")
	assert_true(fsm.transition_from("B", "C"))


func test_a_state_with_a_declared_dwell_fires_once_per_visit() -> void:
	# A lambda captures locals by value, so the clock lives in a box the lambda can see.
	var clock: Array[int] = [0]
	var fsm: Fsm = Fsm.new("A", {"A": ["B"], "B": ["A"]}, {"A": 1.0}, func() -> int: return clock[0])
	clock[0] = 3000
	assert_true(fsm.check_dwell())
	assert_false(fsm.check_dwell(), "one timeout per visit, not one per frame")
	fsm.transition_to("B")
	fsm.transition_to("A")
	clock[0] = 4500
	assert_true(fsm.check_dwell(), "a new visit is a new budget")
