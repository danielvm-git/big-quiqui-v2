# story: e01s03
extends Node
## Owns the typed save model and its atomic persistence (ADR-005).
##
## Write path: serialize → `progress.json.tmp` → flush → close → rename over
## `progress.json`. A crash mid-write can therefore never leave a half-written
## save: either the old file is intact or the new one is complete.
##
## Tests never touch the production file: `TestReset` calls `set_test_mode(true)`,
## which moves every read and write to `user://test_progress.json`.

signal progress_changed

const PRODUCTION_PATH: String = "user://progress.json"
const TEST_PATH: String = "user://test_progress.json"
const TMP_SUFFIX: String = ".tmp"

var data: SaveData = null
var save_path: String = PRODUCTION_PATH
var test_mode: bool = false
var write_count: int = 0
var last_error: String = ""


func _ready() -> void:
	data = SaveData.new()
	load_or_default()


# ── TestReset seam ───────────────────────────────────────────────────────────


func set_test_mode(enabled: bool) -> void:
	test_mode = enabled
	save_path = TEST_PATH if enabled else PRODUCTION_PATH
	if enabled:
		data = SaveData.new()
		load_or_default()


func is_test_mode() -> bool:
	return test_mode


# ── persistence ──────────────────────────────────────────────────────────────


## Loads the save file, or installs defaults. Never errors: a broken file is a
## recovered state, not a crash (CONVENTIONS §4 graceful degradation).
func load_or_default() -> void:
	last_error = ""
	if not FileAccess.file_exists(save_path):
		data = SaveData.new()
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		last_error = "open_failed"
		data = SaveData.new()
		_emit("save.load_failed", {"reason": "open"})
		return
	var text: String = file.get_as_text()
	file.close()
	# JSON.new().parse() reports the error instead of pushing an engine error, so a
	# corrupt save is a recovered state that a test can assert on.
	var json: JSON = JSON.new()
	var parse_error: int = json.parse(text)
	if parse_error != OK or not json.data is Dictionary:
		last_error = "corrupt"
		data = SaveData.new()
		_emit("save.load_failed", {"reason": "corrupt"})
		return
	data = SaveData.from_dictionary(json.data as Dictionary)
	_emit("save.loaded", {"coins": data.coins, "cycles": data.completed_cycles})


## Atomic write: temp file, flush, close, rename. Returns false on failure.
func save() -> bool:
	last_error = ""
	var tmp_path: String = save_path + TMP_SUFFIX
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		last_error = "open_failed"
		_emit("save.write_failed", {"reason": "open"})
		return false
	file.store_string(JSON.stringify(data.to_dictionary(), "\t"))
	file.flush()
	file.close()

	var renamed: int = DirAccess.rename_absolute(tmp_path, save_path)
	if renamed != OK:
		last_error = "rename_failed"
		DirAccess.remove_absolute(tmp_path)
		_emit("save.write_failed", {"reason": "rename"})
		return false

	write_count += 1
	_emit("save.written", {"coins": data.coins, "cycles": data.completed_cycles})
	progress_changed.emit()
	return true


func tmp_path() -> String:
	return save_path + TMP_SUFFIX


func has_orphan_tmp() -> bool:
	return FileAccess.file_exists(tmp_path())


# ── mutation helpers (clamped, always announced) ─────────────────────────────


func add_coins(amount: int) -> void:
	data.coins = clampi(data.coins + amount, 0, SaveData.MAX_COINS)
	progress_changed.emit()


func add_tickets(amount: int) -> void:
	data.tickets = clampi(data.tickets + amount, 0, SaveData.MAX_COINS)
	progress_changed.emit()


func complete_cycle(coins: int = 5, tickets: int = 1) -> void:
	add_coins(coins)
	add_tickets(tickets)
	data.completed_cycles += 1
	progress_changed.emit()


## TestReset entry point.
func reset() -> void:
	data = SaveData.new()
	write_count = 0
	last_error = ""
	if has_orphan_tmp():
		DirAccess.remove_absolute(tmp_path())


func _emit(ev: String, data_in: Dictionary) -> void:
	var sink: Node = get_node_or_null("/root/Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data_in)
