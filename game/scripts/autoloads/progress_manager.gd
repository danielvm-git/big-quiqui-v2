# story: e01s03
# story: e10s01
# story: e11s01
# story: e13s05
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
	var loaded: Dictionary = SaveFile.read_dictionary(save_path)
	if loaded.is_empty():
		_recover_from_backup()
		return
	data = SaveData.from_dictionary(loaded)
	_emit("save.loaded", {"coins": data.coins, "cycles": data.completed_cycles})
	_mirror_backup()


## FIX-06: a corrupt save is survivable. Without a good `.bak` it degrades to defaults,
## which is data loss — recorded, never silent.
func _recover_from_backup() -> void:
	var recovered: Dictionary = SaveFile.read_dictionary(bak_path())
	if recovered.is_empty():
		_fail_load("corrupt", "corrupt")
		return
	data = SaveData.from_dictionary(recovered)
	_emit("save.recovered_from_backup", {"coins": data.coins})
	_mirror_backup()


func _fail_load(err: String, reason: String) -> void:
	last_error = err
	data = SaveData.new()
	_emit("save.load_failed", {"reason": reason})


## Atomic write: temp file, flush, close, rename. Returns false on failure.
func save() -> bool:
	last_error = ""
	var failure: String = SaveFile.write_atomic(save_path, data.to_dictionary())
	if not failure.is_empty():
		last_error = "open_failed" if failure == "open" else "rename_failed"
		_emit("save.write_failed", {"reason": failure})
		return false
	write_count += 1
	_emit("save.written", {"coins": data.coins, "cycles": data.completed_cycles})
	_mirror_backup()
	progress_changed.emit()
	return true


func tmp_path() -> String:
	return SaveFile.tmp_path(save_path)


func bak_path() -> String:
	return SaveFile.bak_path(save_path)


func has_orphan_tmp() -> bool:
	return SaveFile.has_orphan_tmp(save_path)


func _mirror_backup() -> void:
	if data != null:
		SaveFile.mirror_backup(save_path, data.to_dictionary())


# ── mutation helpers (clamped, always announced) ─────────────────────────────


func get_coins() -> int:
	return 0 if data == null else data.coins


func get_tickets() -> int:
	return 0 if data == null else data.tickets


func add_coins(amount: int) -> void:
	_apply(amount, 0)


func add_tickets(amount: int) -> void:
	_apply(0, amount)


## Records what she is wearing. One id per slot, validated by `Ids` before it can
## reach disk or a `res://` path (T-E05-01). Returns false and changes nothing when
## the slot or the id is not valid.
func equip(slot: String, id: String) -> bool:
	if not Ids.is_valid(slot) or not Ids.is_valid(id):
		_emit("progress.invalid_equip", {"slot": "invalid"})
		return false
	if equipped(slot) == id:
		return true  # idempotent: equipping the same thing twice is not an event
	OutfitLedger.set_slot(data, slot, id)
	if not save():
		progress_changed.emit()
	return true


func equipped(slot: String) -> String:
	return OutfitLedger.get_slot(data, slot)


## The bin path: clears one slot, saves, and announces the change so the rig and the closet
## repaint. An unknown slot changes nothing.
func clear_slot(slot: String) -> bool:
	if not Ids.is_valid(slot):
		_emit("progress.invalid_equip", {"slot": "invalid"})
		return false
	if not OutfitLedger.clear(data, slot):
		return true
	if not save():
		progress_changed.emit()
	return true


## Applies the saved look to a rig without going through the closet: the room that
## opens must already show what the child chose last time.
func dress(rig: Node) -> void:
	OutfitLedger.dress(data, rig)


func complete_cycle(coins: int = CYCLE_COINS_REWARD, tickets: int = CYCLE_TICKETS_REWARD) -> void:
	_apply(coins, tickets, 1)


## Mutates and **writes**: every caller is a money path, and a reward that lives only in
## RAM is gone the moment iOS kills the app from the switcher. The write is atomic
## (`.tmp` + rename), so a crash mid-write keeps the previous file.
##
## One logical change, one `progress_changed`: the `add_coins`/`add_tickets` mutators are for
## the HUD's incremental updates, a full cycle is a single event.
func _apply(coins_delta: int, tickets_delta: int, cycles_delta: int = 0) -> void:
	data.coins = clampi(data.coins + coins_delta, 0, SaveData.MAX_COINS)
	data.tickets = clampi(data.tickets + tickets_delta, 0, SaveData.MAX_TICKETS)
	data.completed_cycles = clampi(data.completed_cycles + cycles_delta, 0, SaveData.MAX_CYCLES)
	# `save()` announces the change itself (the HUD repaints once). If the write fails,
	# the HUD still needs to know the RAM value moved.
	if not save():
		progress_changed.emit()


## TestReset entry point.
func reset() -> void:
	data = SaveData.new()
	write_count = 0
	last_error = ""
	SaveFile.remove(tmp_path())
	SaveFile.remove(bak_path())


# ── furniture (e09s01) ───────────────────────────────────────────────────────


## One atomic purchase: every refusal happens before the first mutation, so a refused
## tap can never take coins without handing back the piece. A piece she already owns is
## idempotent and free — the store's second tap is not a second charge.
func buy_furniture(id: String, price: int) -> bool:
	if not Ids.is_valid(id) or price < 0:
		_emit("furniture.invalid", {"item": "invalid"})
		return false
	if owns_furniture(id):
		_emit("furniture.already_owned", {"item": id})
		return false
	if data.coins < price:
		_emit("furniture.denied", {"item": id, "reason": "coins"})
		return false
	data.coins = clampi(data.coins - price, 0, SaveData.MAX_COINS)
	data.owned_furniture.append(id)
	if not save():
		progress_changed.emit()
	return true


func owns_furniture(id: String) -> bool:
	return data != null and data.owned_furniture.has(id)


func owned_count() -> int:
	return 0 if data == null else data.owned_furniture.size()


func owned_furniture() -> Array[String]:
	return FurnitureLedger.owned_copy(data)


## One placement per piece (e09s02): the ratio is the only thing persisted, so the room
## lands in the same spot on the iPad and on a desktop canvas. Owned pieces only.
func place_furniture(id: String, nx: float, ny: float) -> bool:
	if not Ids.is_valid(id):
		_emit("furniture.invalid", {"item": "invalid"})
		return false
	if not owns_furniture(id):
		_emit("furniture.place_refused", {"item": id, "reason": "not_owned"})
		return false
	if not FurnitureLedger.upsert(data, id, nx, ny):
		_emit("furniture.place_refused", {"item": "invalid"})
		return false
	if not save():
		progress_changed.emit()
	return true


func remove_furniture(id: String) -> bool:
	if not FurnitureLedger.drop(data, id):
		return false
	if not save():
		progress_changed.emit()
	return true


func placed() -> Array[Dictionary]:
	return FurnitureLedger.copies(data)


func placed_count() -> int:
	return FurnitureLedger.count(data)


# ── friend stars (e10s01) ─────────────────────────────────────────────────────


## +1 mastery point per friend, capped at `MAX_STARS`. Every refusal (unknown id,
## capped friend) happens before the first mutation, so a replayed win can never
## double-pay a star and an unsafe id never reaches the save model.
func add_star(friend_id: String) -> bool:
	if not FriendCatalog.is_friend(friend_id):
		_emit("star.refused", {"friend": "invalid"})
		return false
	var current: int = stars_of(friend_id)
	if current >= SaveData.MAX_STARS:
		_emit("star.refused", {"friend": friend_id, "reason": "cap"})
		return false
	data.friend_stars[friend_id] = current + 1
	if not save():
		progress_changed.emit()
	return true


## The clamped read side: a tampered save shows what the rules allow, never more.
func stars_of(friend_id: String) -> int:
	if data == null or not data.friend_stars.has(friend_id):
		return 0
	return clampi(int(data.friend_stars[friend_id]), 0, SaveData.MAX_STARS)


func _emit(ev: String, data_in: Dictionary) -> void:
	LogSink.emit_from(self, ev, data_in)
