# Evidence pass: t22_play_beat and t3_skip_beat

<!-- story: e13s06 -->

Date: 2026-11-09. Pass owner: e13s06. This document is the rule. A later template that disagrees with it is wrong.

## What was read

The scope names the extract as `.rea/report/builder-template-usage.json`. That path is not in this worktree. A search of the repository found no template class, no sibling initializer, and no scene object list for template 22 or template 3.

The names `CheckIfSoundsEnded`, "tableau", and "skip beat" appear only in the epic text that already called those labels a guess. They are not quoted from a class file in this tree.

No script was executed against an extract. There was no extract to run.

## t22_play_beat

- What it does: unknown. The catalogue weight is 392 scenes. That number is a count, not a behaviour.
- What starts it: not observed.
- What ends it: not observed. A claim that it ends when sounds finish, or when touches are counted, would need a method body. That body is not here. The claim is not made.
- What a scene supplies: not observed. No component names and no object counts were available.
- Evidence: absence. Searched the worktree for the usage report, for `Template22`, and for `CheckIfSoundsEnded` outside the epic prose.
- Confidence: low.
- Call: skip. Building it would repeat the guess D3 rejected.

## t3_skip_beat

- What it does: unknown. The catalogue weight is 130 scenes.
- What starts it: not observed.
- What ends it: not observed. "Any input skips" is the guess, not a reading.
- What a scene supplies: not observed.
- Evidence: absence. Same search. No sibling initializer and no object graph.
- Confidence: low.
- Call: skip. Building it would invent the beat.

## Coverage that follows

Wave 1 measured 1,593 of 1,801 template scenes (88.4%) only if both templates are built. They are not.

Skipped weight: 392 + 130 = 522 scenes.

Covered weight: 1,593 − 522 = 1,071 scenes.

Share: 1,071 / 1,801 = 59.5%.

Templates with a unit test and a scene after this pass: 11. The two skipped ids keep a written rule (this page) and do not get a script.

The measurement identity in the scope (1,593 + 83 + 46 + 79 = 1,801) stays. It counts catalogue weight, not what this wave ships. The coverage sentence is the 1,071 / 59.5% line.

## Build-or-skip

| Template | Call | Confidence | Scenes left out |
|---|---|---|---|
| t22_play_beat | skip | low | 392 |
| t3_skip_beat | skip | low | 130 |

A later extract can reopen one row. Until that extract is in the tree, neither id is registered in `TemplateCatalog`.
