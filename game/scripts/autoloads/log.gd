# story: e01s01
extends Node
## Schema-validated JSONL play diary (local only, never leaves the device).
##
## Every line is one JSON object with the context fields
## `ts, t_ms, seq, session, lvl, ev` and optional `scene, state`.
## The contract is enforced from the outside by `bash scripts/logs.sh audit`
## (see scripts/log_tool.py), which rejects:
##   - missing context fields / bad `ts` / `session` not 8 hex / bad `lvl`
##   - composed values (dict/list)
##   - absolute paths, e-mails and digit runs of 6+
##   - any value that is not id-shaped, except `msg` and `<redacted>`
## So every value this writer emits is flattened, redacted and id-checked.

const LEVELS: Array[String] = ["info", "warn", "error"]
const REDACTED: String = "<redacted>"
const PREFIX: String = "quiqui-"
const MAX_VALUE_CHARS: int = 64
const MSG_MAX_CHARS: int = 200

var session_id: String = ""
var log_dir: String = "user://logs"
var log_path: String = ""

var _file: FileAccess = null
var _seq: int = 0
var _writes: int = 0
var _id_re: RegEx = RegEx.new()
var _abs_path_re: RegEx = RegEx.new()
var _email_re: RegEx = RegEx.new()
var _digit_run_re: RegEx = RegEx.new()


func _ready() -> void:
	_id_re.compile("^[a-z0-9_.:/-]{1,64}$")
	_abs_path_re.compile("(^|[\\s'\"(=])(/Users/|/home/|/var/mobile|/private/var|[A-Za-z]:\\\\)")
	_email_re.compile("\\S+@\\S+\\.\\S+")
	_digit_run_re.compile("\\d{6,}")
	session_id = _new_session_id()
	_start_session()


func _exit_tree() -> void:
	event("session.marker", {"phase": "end"})
	stop_session()


# ── public API ───────────────────────────────────────────────────────────────


func event(ev: String, data: Dictionary = {}, level: String = "info") -> void:
	if _file == null:
		return
	var dropped: int = 0
	var line: Dictionary = {
		"ts": _timestamp(),
		"t_ms": Time.get_ticks_msec(),
		"seq": _seq,
		"session": session_id,
		"lvl": level if LEVELS.has(level) else "info",
		"ev": _safe_id(ev, "log.invalid_event"),
	}
	for key: Variant in data.keys():
		var name: String = _safe_id(str(key), "")
		if name.is_empty():
			continue
		var value: Variant = data[key]
		if value is Dictionary or value is Array:
			dropped += 1
			continue
		line[name] = _safe_value(name, value)
	if dropped > 0:
		line["dropped"] = dropped
	_file.store_line(JSON.stringify(line))
	_file.flush()
	_seq += 1
	_writes += 1


func set_context(scene_id: String = "", state_id: String = "") -> void:
	if not scene_id.is_empty():
		var scene_value: String = _safe_id(scene_id, "none")
		if scene_value != "none":
			event("context.scene", {"scene": scene_value})
	if not state_id.is_empty():
		var state_value: String = _safe_id(state_id, "none")
		if state_value != "none":
			event("context.state", {"state": state_value})


func stop_session() -> void:
	if _file != null:
		_file.flush()
		_file.close()
		_file = null


func write_count() -> int:
	return _writes


func redact_pii(text: String) -> String:
	var out: String = _abs_path_re.sub(text, "$1" + REDACTED, true)
	out = _email_re.sub(out, REDACTED, true)
	out = _digit_run_re.sub(out, REDACTED, true)
	return out


## True when the value is safe to write under a non-`msg` key.
func is_safe_id(text: String) -> bool:
	return _id_re.search(text) != null and text.length() <= MAX_VALUE_CHARS


func _start_session() -> void:
	if DirAccess.make_dir_recursive_absolute(log_dir) != OK and not DirAccess.dir_exists_absolute(log_dir):
		push_warning("Log: cannot create %s — diary disabled" % log_dir)
		return
	log_path = "%s/%s%s.jsonl" % [log_dir, PREFIX, session_id]
	_file = FileAccess.open(log_path, FileAccess.WRITE)
	if _file == null:
		push_warning("Log: cannot open %s — diary disabled" % log_path)
		return
	event("session.marker", {"phase": "start"})


func _new_session_id() -> String:
	return "%08x" % (randi() & 0xffffffff)


func _timestamp() -> String:
	var unix_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var stamp: Dictionary = Time.get_datetime_dict_from_unix_time(int(unix_ms / 1000))
	return (
		"%04d-%02d-%02dT%02d:%02d:%02d.%03dZ"
		% [
			int(stamp["year"]),
			int(stamp["month"]),
			int(stamp["day"]),
			int(stamp["hour"]),
			int(stamp["minute"]),
			int(stamp["second"]),
			unix_ms % 1000,
		]
	)


func _safe_id(value: String, fallback: String) -> String:
	var cleaned: String = value.strip_edges().to_lower()
	if cleaned.is_empty() or cleaned.length() > MAX_VALUE_CHARS:
		return fallback
	if not is_safe_id(cleaned):
		return fallback
	return cleaned


func _safe_value(key: String, value: Variant) -> Variant:
	if value is int or value is float or value is bool:
		return value
	var text: String = redact_pii(str(value))
	if key == "msg":
		if text.length() > MSG_MAX_CHARS:
			text = text.substr(0, MSG_MAX_CHARS)
		if not is_safe_id(text):
			return REDACTED
		return REDACTED if text == REDACTED else text
	var candidate: String = _safe_id(text, REDACTED)
	return candidate
