# Done

The fetch stage stopped. The `GitRepository` named a branch that the repo does not have, so source-controller never stored an artifact. With no artifact, each consumer reported that it had nothing to apply, and the workloads never existed. Pointing the source at `main` produced an artifact, and the consumers applied it at once.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers the durable fix and the alert that catches a stalled source.
- [LESSON.md](../LESSON.md) covers the other fetch case: an earlier artifact exists, and every consumer stays green.
- **breakfix-02: Kustomization Suspended** — drift that Flux should revert stays, and `apps` reports `Ready True`.
