# story: e12s02
# story: e12s04
# story: e13s01
# story: e13s03
# story: e13s04
# story: e13s05
# story: e13s08
class_name StepDef
extends Resource
## One step in a data-driven scene: a template id and typed parameters only — never paths or scripts.

@export var template_id: String = ""
@export var param_int: int = 0
@export var repeat_count: int = 1
@export var mode: String = "single"
@export var receiver_id: String = ""
@export var item_ids: PackedStringArray = PackedStringArray()
@export var on_hit_pose: String = ""
## Optional, parallel to `item_ids`: the pose each target or layer answers with. An empty entry uses `on_hit_pose`.
@export var hit_poses: PackedStringArray = PackedStringArray()
@export var on_hit_sfx_id: String = ""
@export var on_miss_sfx_id: String = "sfx_soft_error"
@export var care_step_id: String = ""
@export var hint_delay_sec: float = 0.0
@export var hint_from_id: String = ""
@export var hint_to_id: String = ""
@export var hint_voice_key: String = ""
@export var loop_sfx_id: String = ""
@export var tool_id: String = ""
@export var world_size: Vector2 = Vector2(1920.0, 1080.0)
@export var pan_tolerance: float = 24.0
@export var completion_threshold: float = 0.9
@export var slot_ids: PackedStringArray = PackedStringArray()
@export var category_ids: PackedStringArray = PackedStringArray()
@export var lane_count: int = 3
@export var spawn_seed: int = 1
@export var spawn_cadence: int = 2
@export var spawn_lifetime: int = 4
@export var goal_count: int = 3
@export var destination_ids: PackedStringArray = PackedStringArray()
@export var destination_scenes: PackedStringArray = PackedStringArray()
@export var destination_locks: PackedStringArray = PackedStringArray()
@export var destination_positions: PackedVector2Array = PackedVector2Array()
@export var destination_icons: PackedStringArray = PackedStringArray()
