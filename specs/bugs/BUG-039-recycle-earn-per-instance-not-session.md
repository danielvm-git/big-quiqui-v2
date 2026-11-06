---
bug_id: BUG-039
status: open
severity: medium
scope: code
title: The recycling coin and hint are guarded per VilaScene instance, so every visit to the Vila pays +1 again
---
# BUG-039: The recycling coin and hint are guarded per VilaScene instance, so every visit to the Vila pays +1 again

<!-- story: e08s02 -->

**Found by:** e08 post-epic review (whole-epic diff 272c722..844884d).

## Evidence

vila.gd keeps `_recycle_awarded` and `_recycle_hint_done` as instance fields; SceneManager builds a
new VilaScene per visit, so Casa->Vila->Casa->Vila farms one coin per trip. e08s02 AC7 says the hint
is not shown again 'this session' and Review A recorded 'single earn per session by design'. Fix: a
session-level ledger on the scene class, reset by TestReset.
