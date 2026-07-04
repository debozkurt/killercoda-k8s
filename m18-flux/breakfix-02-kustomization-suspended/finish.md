# Done

You diagnosed drift that wouldn't revert — not a broken source, not a failing workload, but a consumer whose reconciliation was switched off. The `apps` Kustomization was `SUSPENDED True`, so Flux applied nothing and the hand-scaled 5 replicas persisted. `flux resume` turned reconciliation back on and the drift corrected itself to the git-declared 2.

**Next:**

- For the canonical path and the suspend-tripwire discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — why a suspended object hides in plain sight and how drift correction works — read [LESSON.md](../LESSON.md).
- **breakfix-03: HelmRelease Dependency** — a release is stuck `not ready` and never installs, though source and everything else are healthy. The `dependsOn` names something that isn't there.
