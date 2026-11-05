# story: e02s01
class_name CareSteps
extends RefCounted
## The care cycle vocabulary and its order — the only place these names live.
##
## `CareLoopManager` derives its `STATE_*` constants and `STEP_ORDER` from here,
## and `CasaScene` builds its door table from the same list, so a rename can
## never desynchronise the machine from the hub that reports on it.

const IDLE: String = "IDLE"
const FEED: String = "FEED"
const BATH: String = "BATH"
const DRESS: String = "DRESS"
const PLAY: String = "PLAY"
const SLEEP: String = "SLEEP"
const CELEBRATE: String = "CELEBRATE"

## The five in-cycle steps, in the order the child plays them.
const ORDER: Array[String] = [FEED, BATH, DRESS, PLAY, SLEEP]
