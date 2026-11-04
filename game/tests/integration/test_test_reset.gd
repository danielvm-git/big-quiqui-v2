# story: e01s01
extends GutTest
## SC-E01-P0-06 — tests can never touch the production save file (ADR-005).

const PRODUCTION_SAVE: String = "user://progress.json"


func before_each() -> void:
	TestReset.reset_all()


func test_test_save_path_is_not_the_production_path() -> void:
	assert_ne(TestReset.TEST_SAVE_PATH, PRODUCTION_SAVE)
	assert_true(TestReset.TEST_SAVE_PATH.ends_with("test_progress.json"))


func test_reset_removes_a_leftover_test_save() -> void:
	var file: FileAccess = FileAccess.open(TestReset.TEST_SAVE_PATH, FileAccess.WRITE)
	assert_not_null(file, "the test save path must be writable")
	file.store_string('{"coins": 999}')
	file.close()
	assert_true(FileAccess.file_exists(TestReset.TEST_SAVE_PATH))

	TestReset.reset_all()

	assert_false(
		FileAccess.file_exists(TestReset.TEST_SAVE_PATH),
		"reset_all deletes the test save so no test inherits another's state",
	)


func test_reset_survives_managers_that_do_not_exist_yet() -> void:
	# ProgressManager arrives in e01s03; today the lookup must be a safe no-op.
	assert_null(TestReset.manager_node("ProgressManager"))
	TestReset.reset_all()
	assert_true(true, "reset_all must not error when a manager is absent")


func test_production_save_is_never_created_by_reset() -> void:
	var existed_before: bool = FileAccess.file_exists(PRODUCTION_SAVE)
	TestReset.reset_all()
	var exists_after: bool = FileAccess.file_exists(PRODUCTION_SAVE)
	assert_eq(
		existed_before,
		exists_after,
		"reset_all must never create or delete the production save",
	)
