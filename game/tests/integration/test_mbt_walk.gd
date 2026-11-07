# story: e11s01
extends GutTest
## MBT-01 — a seeded 500-step model-based walk over the economy, the save and the care FSM.
##
## The model says *what may be true at any moment*; the walk tries to make it false. Every
## finding below is reported with the step index and the seed, so a failure reproduces by
## re-running with the same seed instead of by re-reading a stack trace.

const SEED: int = 20261107
const STEPS: int = 500
const RELOAD_EVERY: int = 25
const ACTIONS: int = 9

var pm: Node = null
var loop: Node = null
var rng: RandomNumberGenerator = null


func before_each() -> void:
	TestReset.reset_all()
	pm = get_node("/root/ProgressManager")
	loop = get_node("/root/CareLoopManager")
	pm.set_test_mode(true)
	pm.reset()
	loop.reset()
	rng = RandomNumberGenerator.new()
	rng.seed = SEED


func after_each() -> void:
	pm.reset()
	TestReset.delete_test_save()
	pm.set_test_mode(false)


func test_a_500_step_walk_never_breaks_an_invariant() -> void:
	for step: int in range(STEPS):
		_perform(step)
		_assert_invariants(step)
		if step % RELOAD_EVERY == 0:
			_assert_the_save_survives_a_restart(step)
		if step % 50 == 0:
			_assert_a_full_care_cycle_is_legal(step)


func test_the_walk_is_reproducible_from_its_seed() -> void:
	var first: String = _fingerprint_of_a_short_walk()
	before_each()
	var second: String = _fingerprint_of_a_short_walk()
	assert_eq(first, second, "a monkey test that cannot be replayed is not a gate")


func test_the_walk_actually_exercises_every_action() -> void:
	var seen: Dictionary = {}
	for step: int in range(STEPS):
		seen[_perform(step)] = true
	for action: String in _action_names():
		assert_true(seen.has(action), "%s never ran — the walk is not covering it" % action)


# ── the model ────────────────────────────────────────────────────────────────


func _perform(step: int) -> String:
	var action: String = _action(rng.randi_range(0, ACTIONS - 1))
	match action:
		"coins":
			pm.add_coins(rng.randi_range(-20, 20))
		"tickets":
			pm.add_tickets(rng.randi_range(-3, 3))
		"cycle":
			pm.complete_cycle(5, 1)
		"buy":
			pm.buy_furniture(_some_id(), rng.randi_range(1, 10))
		"place":
			pm.place_furniture(_some_id(), rng.randf_range(-1.0, 2.0), rng.randf_range(-1.0, 2.0))
		"remove":
			pm.remove_furniture(_some_id())
		"equip":
			pm.equip(SaveData.SLOTS[rng.randi_range(0, SaveData.SLOTS.size() - 1)], "vestido_flor")
		"save":
			pm.save()
		"reload":
			pm.load_or_default()
	return action


func _action_names() -> Array[String]:
	return ["coins", "tickets", "cycle", "buy", "place", "remove", "equip", "save", "reload"]


func _action(index: int) -> String:
	return _action_names()[index]


func _some_id() -> String:
	var pool: Array[String] = FurnitureCatalog.FURNITURE_IDS.duplicate()
	pool.append("unowned_piece")
	pool.append("bad id")
	return pool[rng.randi_range(0, pool.size() - 1)]


func _assert_invariants(step: int) -> void:
	var violations: Array[String] = SaveCorpus.violations(pm.data)
	assert_eq(violations, [] as Array[String], "seed %d step %d" % [SEED, step])
	assert_gte(pm.get_coins(), 0, "seed %d step %d" % [SEED, step])
	assert_gte(pm.get_tickets(), 0, "seed %d step %d" % [SEED, step])
	assert_lte(pm.get_coins(), SaveData.MAX_COINS)
	assert_lte(pm.get_tickets(), SaveData.MAX_TICKETS)


func _assert_the_save_survives_a_restart(step: int) -> void:
	pm.save()
	var before: String = JSON.stringify((pm.data as SaveData).to_dictionary())
	pm.data = SaveData.new()
	pm.load_or_default()
	var after: String = JSON.stringify((pm.data as SaveData).to_dictionary())
	assert_eq(after, before, "a restart on step %d lost or changed state" % step)


func _assert_a_full_care_cycle_is_legal(step: int) -> void:
	loop.reset()
	var probe: FsmProbe = FsmProbe.new().attach(loop.fsm)
	assert_true(loop.begin_step(CareSteps.FEED), "step %d could not begin the cycle" % step)
	# `complete_step` is the transition: FEED -> BATH -> … -> CELEBRATE, one call each.
	for state: String in CareSteps.ORDER:
		assert_true(loop.complete_step(state), "step %d could not complete %s" % [step, state])
	assert_true(probe.is_clean(), "step %d: %s" % [step, probe.summary()])
	assert_eq(loop.state_id(), CareLoopManager.STATE_CELEBRATE, "the cycle ends in the party")
	assert_true(loop.close_celebrate_if_needed(), "and the party closes itself (BUG-018)")
	assert_eq(loop.state_id(), CareLoopManager.STATE_IDLE)
	probe.detach()


func _fingerprint_of_a_short_walk() -> String:
	var parts: Array[String] = []
	for step: int in range(60):
		parts.append(_perform(step))
		parts.append(str(pm.get_coins()))
		parts.append(str(pm.placed_count()))
	return ",".join(parts)
