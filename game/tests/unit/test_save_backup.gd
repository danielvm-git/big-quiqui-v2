# story: e11s01
extends GutTest
## FIX-06 — corrupt primary recovers from `.bak` before defaults.

var pm: Node = null


func before_each() -> void:
	pm = get_node("/root/ProgressManager")
	pm.set_test_mode(true)
	pm.reset()
	TestReset.delete_test_save()


func after_each() -> void:
	pm.reset()
	TestReset.delete_test_save()
	if FileAccess.file_exists(pm.bak_path()):
		DirAccess.remove_absolute(pm.bak_path())
	pm.set_test_mode(false)


func test_corrupt_primary_restores_from_backup() -> void:
	pm.data.coins = 77
	assert_true(pm.save())
	assert_true(FileAccess.file_exists(pm.bak_path()))
	var file: FileAccess = FileAccess.open(pm.save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	pm.load_or_default()
	assert_eq(pm.data.coins, 77, "backup wins over corrupt primary")
