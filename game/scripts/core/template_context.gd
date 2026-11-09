# story: e12s04
class_name TemplateContext
extends RefCounted
## One contract for every template: rig, tray, reactions, runner, node lookup.
##
## Reason for Depth: 28 templates share no-lives, no-timers, and instant-answer rules here
## instead of duplicating guards in each file.

var host: Node = null
var rig: QuiQuiRig = null
var tray: Control = null
var reactions: ReactionExecutor = null
var runner: StepRunner = null
var nodes: PlayerNodeTable = null
var step_def: StepDef = null
