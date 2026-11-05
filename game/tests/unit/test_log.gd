# story: e01s01
extends GutTest
## SC-E01-P0-04/05 — the diary writes schema-valid JSONL and never stores PII.
## The schema is judged by the external tool (`scripts/logs.sh audit`), not by the
## writer's own opinion of itself.

var log: Node = null


func before_each() -> void:
	TestReset.reset_all()
	log = get_node_or_null("/root/Log")
	assert_not_null(log, "Log must be registered as an autoload in project.godot")


func after_each() -> void:
	if log != null and log.get("_file") == null:
		log.call("_start_session")


func test_line_carries_the_required_context_fields() -> void:
	log.call("event", "test.ping", {"item": "mesa"})
	var line: Dictionary = _last_line()

	for key: String in ["ts", "t_ms", "seq", "session", "lvl", "ev"]:
		assert_true(line.has(key), "missing context field %s in %s" % [key, line])
	assert_eq(line["ev"], "test.ping")
	assert_eq(line["lvl"], "info")
	assert_eq(line["item"], "mesa")
	var ts_re: RegEx = RegEx.new()
	ts_re.compile("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")
	assert_not_null(ts_re.search(str(line["ts"])), "ts must be ISO UTC with millis: %s" % line["ts"])
	assert_eq(str(line["session"]).length(), 8, "session id is 8 hex chars")


func test_pii_is_redacted_before_it_reaches_the_file() -> void:
	var dirty: String = TestReset.paint_the_diary_red()
	log.call("event", "test.pii", {"item": dirty, "msg": dirty})
	var raw: String = _raw_last_line()

	assert_false(raw.contains("Maria"), "a name must never be stored: %s" % raw)
	assert_false(raw.contains("@"), "an e-mail must never be stored: %s" % raw)
	assert_false(raw.contains("/Users/"), "an absolute path must never be stored: %s" % raw)
	assert_false(raw.contains("123456789"), "a long digit run must never be stored: %s" % raw)


func test_composite_values_are_dropped() -> void:
	log.call("event", "test.composite", {"blob": {"a": 1}, "list": [1, 2]})
	var line: Dictionary = _last_line()

	assert_false(line.has("blob"), "dict values are rejected by the audit")
	assert_false(line.has("list"), "array values are rejected by the audit")
	assert_true(int(line.get("dropped", 0)) >= 1, "the drop is counted, not silent")


func test_event_names_are_normalized_to_id_shape() -> void:
	log.call("event", "Maria Clara", {})
	assert_eq(_last_line()["ev"], "log.invalid_event")


func test_written_values_are_id_shaped_or_redacted() -> void:
	# The external auditor (scripts/log_tool.py) accepts only id-shaped strings under
	# non-msg keys; anything else must have been redacted or dropped by the writer.
	log.call("event", "test.shape", {"item": "mesa", "msg": "nhami"})
	var line: Dictionary = _last_line()

	for key: String in line.keys():
		var value: Variant = line[key]
		if not value is String:
			continue
		if key == "ts" or key == "session":
			continue
		if key == "msg" and value != Log.REDACTED:
			continue
		assert_true(
			bool(log.call("is_safe_id", value)),
			"%s=%s is not id-shaped and was not redacted" % [key, value],
		)


func test_no_forbidden_pattern_survives_any_key() -> void:
	(
		log
		. call(
			"event",
			"test.forbidden",
			{
				"item": TestReset.paint_the_diary_red(),
				"msg": TestReset.paint_the_diary_red(),
				"scene": "../Users/evil",
			}
		)
	)
	var raw: String = _raw_last_line()

	# Same case sensitivity as scripts/log_tool.py: the absolute-path rule matches
	# /Users/, /home/, /var/mobile and drive letters, not arbitrary lowercase text.
	for forbidden: String in ["Maria", "@", "/Users/", "/home/", "/var/mobile", "123456789"]:
		assert_false(raw.contains(forbidden), "found %s in %s" % [forbidden, raw])


func _last_line() -> Dictionary:
	var raw: String = _raw_last_line()
	var parsed: Variant = JSON.parse_string(raw)
	return parsed as Dictionary if parsed is Dictionary else {}


func _raw_last_line() -> String:
	var path: String = str(log.get("log_path"))
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var last: String = ""
	while not file.eof_reached():
		var line: String = file.get_line()
		if not line.strip_edges().is_empty():
			last = line
	file.close()
	return last


# BUG-004 — documented policy, not an accident: the diary stores message *ids*.
# A bare first name is invisible to the PII patterns, so prose is refused
# outright instead of being half-redacted.
func test_prose_under_msg_is_refused_by_policy() -> void:
	log.call("event", "test.prose", {"msg": "hora do banho"})
	assert_eq(_last_line()["msg"], Log.REDACTED)

	log.call("event", "test.msg_id", {"msg": "hora_do_banho"})
	assert_eq(_last_line()["msg"], "hora_do_banho", "an id survives, and that is the contract")


# BUG-003/013: `last_line` is a mirror, so a closed diary must not leave the
# previous event behind for a payload-only assertion to read.
func test_last_line_never_survives_a_closed_diary() -> void:
	log.event("test.before_close", {"msg": "antes"})
	assert_eq(log.last_line.get("ev"), "test.before_close")

	log.stop_session()

	log.event("test.after_close", {"msg": "depois"})
	assert_true(log.last_line.is_empty(), "a refused write leaves no stale mirror: %s" % log.last_line)
