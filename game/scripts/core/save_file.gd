# story: e11s03
class_name SaveFile
extends RefCounted
## The bytes, and nothing else (ADR-005, amended by BUG-016/FIX-06).
##
## `ProgressManager` owns the model and announces what happened; this owns the three file
## shapes around it: the atomic `progress.json` write, the orphan `.tmp` a crash can leave,
## and the last-known-good `.bak` that turns a corrupt save into a recoverable one.
##
## It is static and pure over its paths so the manager can be about state, not `FileAccess`
## — and so `progress_manager.gd` stays inside the 300-line bar it kept crossing (INV-09).

const TMP_SUFFIX: String = ".tmp"
const BAK_SUFFIX: String = ".bak"


static func tmp_path(save_path: String) -> String:
	return save_path + TMP_SUFFIX


static func bak_path(save_path: String) -> String:
	return save_path + BAK_SUFFIX


static func has_orphan_tmp(save_path: String) -> bool:
	return FileAccess.file_exists(tmp_path(save_path))


## A parsed dictionary, or `{}` for missing / unreadable / non-object JSON. The caller
## distinguishes "absent" from "corrupt"; this only refuses to throw.
static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	return json.data as Dictionary


## Serialises to `path` and flushes. Not atomic on its own: `write_atomic` is the one to
## call for the save, this is for the `.bak` staging file.
static func write_dictionary(path: String, payload: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	return true


## Atomic write: temp file, flush, close, rename. A crash mid-write leaves the previous
## file intact, which is the whole promise of ADR-005.
static func write_atomic(save_path: String, payload: Dictionary) -> String:
	var tmp: String = tmp_path(save_path)
	if not write_dictionary(tmp, payload):
		return "open"
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		DirAccess.remove_absolute(tmp)
		return "rename"
	return ""


## Copies the current model next to the save as the last-known-good. Best effort: a full
## disk must not stop the save that just succeeded.
static func mirror_backup(save_path: String, payload: Dictionary) -> bool:
	var bak: String = bak_path(save_path)
	var tmp: String = bak + TMP_SUFFIX
	if not write_dictionary(tmp, payload):
		return false
	if DirAccess.rename_absolute(tmp, bak) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true


static func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
