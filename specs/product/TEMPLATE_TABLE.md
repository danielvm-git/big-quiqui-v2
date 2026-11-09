# Wave-1 template table

<!-- story: e13s07 -->
<!-- story: e13s09 -->

Fifteen rows. `built` needs a script, a unit test and a scene file. `skip` stays out of the catalog. The `scenes` column is the measured Builder scene count per template, and `TEMPLATE_USAGE_MANIFEST.json` is the committed record of those counts (source path and sha256 included); the gate fails when a row or the scope total disagrees with it. The built rows add up to 1,071 of 1,801 (59.5%). `test_template_registry` computes that sum and fails when it disagrees with the scope, when a cell is blank or a row is repeated.

The `scene` column names a catalogue probe def until e14 assigns each template its real rooms. A probe loads through `def_override` in the player tests and is not a room a child can open yet.

| id | status | rule | parameters | scene | test | scenes | evidence |
|---|---|---|---|---|---|---|---|
| t0_title | built | One verb starts the game. | none | title_probe | test_t0_title | 13 | e13s05 |
| t3_skip_beat | skip | Not built. No method list was in the tree. | none | none | none | 130 | specs/product/TEMPLATE_EVIDENCE_T22_T3.md |
| t20_drag_snap | built | Drag onto a receiver. The runner completes the step. | item_ids, receiver_id | kitchen | test_t20_drag_snap | 147 | e12 |
| t21_touch_each | built | Each def id is one tap. Repeats do not raise progress. | item_ids, mode | touch_each_probe | test_t21_touch_each | 274 | e13s02 |
| t22_play_beat | skip | Not built. No scene objects were in the tree. | none | none | none | 392 | specs/product/TEMPLATE_EVIDENCE_T22_T3.md |
| t23_erase | built | Clear until the def threshold. Later rubs stay done. | completion_threshold | bathroom_probe | test_t23_erase | 131 | e13s04 |
| t25_map | built | Pan a def world. Locks read the care loop. | destination_ids, destination_scenes, destination_locks | home_map | test_t25_map | 65 | e13s03 |
| t32_reward | built | Pay once through the cycle ledger. No ad. | item_ids | reward_probe | test_t32_reward | 8 | e13s05 |
| t34_rub_reveal | built | Reveal layers in def order. | item_ids, loop_sfx_id | rub_reveal_probe | test_t34_rub_reveal | 121 | e13s01 |
| t40_draw_fill | built | Paint until the def threshold. Residue still looks clean. | completion_threshold | bathroom_probe | test_t40_draw_fill | 197 | e13s04 |
| t45_dress_decorate | built | Snap or place from the def. A bad id is not saved. | item_ids, slot_ids, category_ids | dress_probe | test_t45_dress_decorate | 94 | e13s05 |
| t50_lanes | built | Catch a spawned item. A miss is quiet. | item_ids, lane_count, spawn_seed | penguin_lanes | test_t50_lanes | 14 | e13s08 |
| t51_prize_pick | built | One tap saves one prize from the def. | item_ids | wheel | test_t51_prize_pick | 7 | e13s09 |
| t_rhythm_pose | built | Three pads; a miss replays; pay once. | item_ids | duck_dance | test_t_rhythm_pose | 0 | e14s03 |
| t_album | built | Friend cards read stored stars. No photo. | item_ids | album | test_t_album | 0 | e14s03 |
