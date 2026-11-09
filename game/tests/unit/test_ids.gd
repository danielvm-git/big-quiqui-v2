# story: e01s03
extends GutTest
## BUG-008 — one contract for every resource id in the game. The diary keeps its
## own, looser pattern on purpose (it is owned by scripts/log_tool.py), so this
## test pins the split instead of pretending there is only one pattern.


func test_the_contract_is_the_conventions_pattern() -> void:
	# `\A…\z`, not `^…$`: PCRE's `$` also matches before a trailing newline.
	assert_eq(Ids.PATTERN, "\\A[a-z0-9_]{1,64}\\z", "CONVENTIONS.md §4 is the source")


func test_a_trailing_newline_is_refused() -> void:
	# ^…$ accepted this, and a tampered save could carry it (review A on BUG-008).
	for value: String in ["mesa\n", "mesa\r\n", "mesa\n\n"]:
		assert_false(Ids.is_valid(value), value)
		assert_false(SaveData.is_valid_id(value), value)
	assert_false(
		SaveData.from_dictionary({"owned_furniture": ["mesa\n"]}).owned_furniture.has("mesa\n"),
		"a newline id never reaches the save"
	)


func test_valid_ids_pass() -> void:
	for value: String in ["mesa", "green_overalls", "tapete_2", "a"]:
		assert_true(Ids.is_valid(value), value)


func test_invalid_ids_are_refused() -> void:
	for value: String in ["", "MESA", "Maria Clara", "bad-id", "../etc/passwd", "id.with.dot"]:
		assert_false(Ids.is_valid(value), value)


func test_the_length_ceiling_is_real() -> void:
	assert_true(Ids.is_valid("a".repeat(64)))
	assert_false(Ids.is_valid("a".repeat(65)))


func test_save_data_and_the_rig_share_this_contract() -> void:
	for value: String in ["mesa", "MESA", "bad-id", "../etc/passwd"]:
		assert_eq(SaveData.is_valid_id(value), Ids.is_valid(value), value)
