# story: e11s01
extends GutTest
## INV-05 — the diary vocabulary is closed and id-shaped.
##
## BUG-003/004/042/046/049 lineage. The auditor (`scripts/log_tool.py`) validates what
## is *written*; nothing validated what the code is *allowed to write*. An event id with
## a space, a capital or a colon would reach the file and fail the audit on a child's
## iPad instead of here.

const MAX_ID_CHARS: int = 64


func test_every_emitted_event_id_is_id_shaped() -> void:
	var ids: Array[String] = SourceScanner.event_ids()
	assert_gt(ids.size(), 20, "the scanner must actually find the vocabulary")

	var pattern: RegEx = RegEx.new()
	pattern.compile("^[a-z0-9_.]{1,64}$")
	for id: String in ids:
		assert_not_null(pattern.search(id), "event id is not auditable: '%s'" % id)
		assert_lte(id.length(), MAX_ID_CHARS, "event id too long: %s" % id)


func test_the_vocabulary_is_namespaced_by_subject() -> void:
	var namespaces: Dictionary = {}
	for id: String in SourceScanner.event_ids():
		var head: String = id.split(".")[0]
		namespaces[head] = true
	for expected: String in ["save", "fsm", "scene", "care", "audio", "rig", "item", "furniture"]:
		assert_true(namespaces.has(expected), "no event under the %s namespace" % expected)


func test_no_event_id_is_defined_but_never_emitted() -> void:
	## A vocabulary entry that nothing emits is a lie in the docs and a blind spot in the
	## audit. The reverse (emitting an id the audit does not know) is caught above.
	var reserved: Array[String] = ["fsm.transition", "save.written", "scene.changed"]
	var ids: Array[String] = SourceScanner.event_ids()
	for id: String in reserved:
		assert_true(ids.has(id), "%s is part of the documented vocabulary" % id)


func test_no_message_payload_carries_prose() -> void:
	## BUG-004's policy: `msg` carries an id, never a sentence. A literal with a space
	## passed to `msg` is prose by definition.
	var pattern: RegEx = RegEx.new()
	pattern.compile('"msg"\\s*:\\s*"([^"]*)"')
	var offenders: Array[String] = []
	for path: String in SourceScanner.scripts():
		for found: RegExMatch in pattern.search_all(SourceScanner.text(path)):
			if found.get_string(1).contains(" "):
				offenders.append("%s: %s" % [path, found.get_string(1)])
	assert_eq(offenders, [] as Array[String], "prose under msg (BUG-004 policy)")


func test_every_event_call_goes_through_the_diary_sink() -> void:
	## `Log.event` and `LogSink` are the only writers; a raw `FileAccess` write to a
	## `.jsonl` anywhere in scripts/ would bypass the redaction the audit proves.
	var pattern: RegEx = RegEx.new()
	pattern.compile("\\.jsonl")
	var offenders: Array[String] = []
	for path: String in SourceScanner.scripts():
		if not path.ends_with("autoloads/log.gd") and pattern.search(SourceScanner.text(path)) != null:
			offenders.append(path)
	assert_eq(offenders, [] as Array[String], "only Log may touch a .jsonl file")
