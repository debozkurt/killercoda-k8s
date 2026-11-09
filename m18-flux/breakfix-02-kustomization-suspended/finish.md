# Done

Delivery was switched off for one object. The `apps` Kustomization was suspended, so kustomize-controller skipped every pass: no drift correction, no new revision, no prune. It kept the condition of its last pass, `Ready True`, and only the `SUSPENDED` column showed the state. `flux resume` ran a pass at once, and the pass reverted the drift.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers the incident runbook that keeps a suspend from outliving the incident.
- [LESSON.md](../LESSON.md) covers suspend as a tool and as a hazard.
- **breakfix-03: HelmRelease Dependency** — a release never installs, and its source and its chart are healthy.
