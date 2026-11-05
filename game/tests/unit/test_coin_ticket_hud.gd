# story: e02s02
extends GutTest
## SC-E02-P1-10..13 — the HUD mirrors the economy: coins and tickets as icon +
## numeral, refreshed by signal, never touching the production save.

var pm: Node = null


func before_each() -> void:
	TestReset.reset_all()
	pm = get_node_or_null("/root/ProgressManager")
	assert_not_null(pm)


func _mounted() -> CoinTicketHud:
	var hud: CoinTicketHud = CoinTicketHud.new()
	hud.size = Vector2(380.0, 88.0)
	add_child_autofree(hud)
	return hud


func test_shows_zero_zero_on_a_fresh_save() -> void:
	var hud: CoinTicketHud = _mounted()

	assert_eq(hud.coins_shown(), 0)
	assert_eq(hud.tickets_shown(), 0)
	assert_eq(hud.coin_label().text, "0")
	assert_eq(hud.ticket_label().text, "0")


func test_refresh_reads_the_real_progress_manager() -> void:
	var hud: CoinTicketHud = _mounted()
	pm.add_coins(12)
	pm.add_tickets(2)

	hud.refresh()

	assert_eq(hud.coins_shown(), 12)
	assert_eq(hud.tickets_shown(), 2)
	assert_eq(hud.coin_label().text, "12")
	assert_eq(hud.ticket_label().text, "2")


func test_progress_changed_signal_updates_the_hud_without_manual_refresh() -> void:
	var hud: CoinTicketHud = _mounted()
	assert_eq(hud.coins_shown(), 0)

	pm.add_coins(3)

	assert_eq(hud.coins_shown(), 3, "add_coins emits progress_changed and the HUD listens")


func test_the_hud_is_never_a_hit_target() -> void:
	var hud: CoinTicketHud = _mounted()

	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "taps must pass through to the scene")


func test_survives_a_missing_progress_manager() -> void:
	# The HUD duck-types the autoload; without it, it shows zeros and never crashes.
	var hud: CoinTicketHud = CoinTicketHud.new()
	hud.manager_path = "/root/ManagerThatDoesNotExist"  # seam, set before _ready resolves it
	add_child_autofree(hud)

	assert_eq(hud.coins_shown(), 0)
	assert_eq(hud.tickets_shown(), 0)
	hud.refresh()  # must be a no-op, not a crash
	assert_eq(hud.coins_shown(), 0)
