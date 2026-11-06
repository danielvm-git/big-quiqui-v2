# Specs — Coelinha QuiQui (`big-quiqui-v2`)

All planning, product, architecture, security, verification, and vertical-slice epic specifications for Coelinha QuiQui (TutoTOONS-grade greenfield rebuild).

## Structure
- `specs/state.yaml` — Active session state, workflow mode (`solo-git`), and release pointers.
- `specs/planning-status.yaml` — Discover & Elaborate phase completion checklist.
- `specs/release-plan.yaml` — WSJF-ordered vertical-slice epics (`e01`–`e11`) where every epic ships a playable, end-to-end testable scene.
- `specs/execution-status.yaml` — Live story/task execution status.
- `specs/product/` — `VISION_LATEST.yaml`, `SCOPE_LATEST.yaml`, `GLOSSARY_LATEST.yaml`, `REQUIREMENTS_TRACE.yaml`.
- `specs/tech-architecture/` — `tech-stack.md`, `EXPLICIT_STATE_MACHINES.md`, `TEST_PLAN_LATEST.md`, `SECURITY_PLAN_LATEST.md`, `DESIGN_PLAN_LATEST.md`.
- `specs/adr/` — Architectural Decision Records (`ADR-001` through `ADR-010`).
- `specs/epics/archive/` — Closed epic capsules, verbatim, moved here when the epic ships.
- `specs/epics/eNN-slug/` — Vertical-slice epic capsules, one directory per open epic (`epic.yaml`, story `.md` specs, `eNNsYY-tasks.yaml`).
- `specs/security/` — STRIDE threat models per epic (`epics/eNN/THREAT_MODEL.md`).
- `specs/verifications/` — Gate verification and visual audit reports.
- `specs/bugs/registry.yaml` — Discovered defects registry.
