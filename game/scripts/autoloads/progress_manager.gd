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
const CYCLE_COINS_REWARD: int = 5
const CYCLE_TICKETS_REWARD: int = 1

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
		_fail_load("open_failed", "open")
		return
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		_fail_load("corrupt", "corrupt")
		return
	data = SaveData.from_dictionary(json.data as Dictionary)
	_emit("save.loaded", {"coins": data.coins, "cycles": data.completed_cycles})


func _fail_load(err: String, reason: String) -> void:
	last_error = err
	data = SaveData.new()
	_emit("save.load_failed", {"reason": reason})


## Atomic write: temp file, flush, close, rename. Returns false on failure.
func save() -> bool:
	last_error = ""
	var tmp: String = tmp_path()
	if not _write_tmp(tmp):
		last_error = "open_failed"
		_emit("save.write_failed", {"reason": "open"})
		return false
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		last_error = "rename_failed"
		DirAccess.remove_absolute(tmp)
		_emit("save.write_failed", {"reason": "rename"})
		return false
	write_count += 1
	_emit("save.written", {"coins": data.coins, "cycles": data.completed_cycles})
	progress_changed.emit()
	return true


func _write_tmp(tmp: String) -> bool:
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data.to_dictionary(), "\t"))
	file.flush()
	file.close()
	return true


func tmp_path() -> String:
	return save_path + TMP_SUFFIX


func has_orphan_tmp() -> bool:
	return FileAccess.file_exists(tmp_path())


# ── mutation helpers (clamped, always announced) ─────────────────────────────


func get_coins() -> int:
	return 0 if data == null else data.coins


func get_tickets() -> int:
	return 0 if data == null else data.tickets


func add_coins(amount: int) -> void:
	_apply(amount, 0)


func add_tickets(amount: int) -> void:
	_apply(0, amount)


## One logical change, one `progress_changed`: the mutators above are for the
## HUD's incremental updates, a full cycle is a single event.
## Records what she is wearing. One id per slot, validated by `Ids` before it can
## reach disk or a `res://` path (T-E05-01). Returns false and changes nothing when
## the slot or the id is not valid.
func equip(slot: String, id: String) -> bool:
	if not Ids.is_valid(slot) or not Ids.is_valid(id):
		_emit("progress.invalid_equip", {"slot": "invalid"})
		return false
	if str(data.equipped_outfits.get(slot, "")) == id:
		return true  # idempotent: equipping the same thing twice is not an event
	data.equipped_outfits[slot] = id
	save()
	progress_changed.emit()
	return true


func equipped(slot: String) -> String:
	return str(data.equipped_outfits.get(slot, ""))


## Applies the saved look to a rig without going through the closet: the room that
## opens must already show what the child chose last time.
func dress(rig: Node) -> void:
	if rig == null or not is_instance_valid(rig):
		return
	var outfit: String = equipped(SaveData.SLOT_BODY)
	if not outfit.is_empty():
		rig.call("set_outfit", outfit)
	for slot: String in [SaveData.SLOT_HEAD, SaveData.SLOT_NECK, SaveData.SLOT_EYES]:
		var id: String = equipped(slot)
		if not id.is_empty():
			rig.call("set_accessory", slot, id)


func complete_cycle(coins: int = CYCLE_COINS_REWARD, tickets: int = CYCLE_TICKETS_REWARD) -> void:
	_apply(coins, tickets, 1)


func _apply(coins_delta: int, tickets_delta: int, cycles_delta: int = 0) -> void:
	data.coins = clampi(data.coins + coins_delta, 0, SaveData.MAX_COINS)
	data.tickets = clampi(data.tickets + tickets_delta, 0, SaveData.MAX_TICKETS)
	data.completed_cycles = clampi(data.completed_cycles + cycles_delta, 0, SaveData.MAX_CYCLES)
	progress_changed.emit()


## TestReset entry point.
func reset() -> void:
	data = SaveData.new()
	write_count = 0
	last_error = ""
	if has_orphan_tmp():
		DirAccess.remove_absolute(tmp_path())


func _emit(ev: String, data_in: Dictionary) -> void:
	LogSink.emit_from(self, ev, data_in)
