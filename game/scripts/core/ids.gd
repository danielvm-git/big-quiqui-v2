# story: e01s03
class_name Ids
extends RefCounted
## Single owner of the game-wide resource-id contract (CONVENTIONS.md §4).
##
## The play diary keeps its own, looser pattern on purpose: it is fixed by the
## external auditor (`scripts/log_tool.py` `ID_RE`) and must not drift with this
## one, so a diary key may carry `.`, `:` and `/` while a save/art id may not.

## `\A…\z` and not `^…$`: PCRE's `$` also matches before a trailing newline, so
## `^…$` accepts `"mesa\n"` (CONVENTIONS.md §4, review A on BUG-008).
const PATTERN: String = "\\A[a-z0-9_]{1,64}\\z"
const MAX_CHARS: int = 64

static var _re: RegEx = null


static func is_valid(value: String) -> bool:
	if value.is_empty() or value.length() > MAX_CHARS:
		return false
	if _re == null:
		_re = RegEx.new()
		_re.compile(PATTERN)
	return _re.search(value) != null
