# Done

The order gate held the release. `voicemail` listed `message-cache` in `dependsOn`, and no HelmRelease has that name. The helm-controller checks each dependency at the start of every pass, so it stopped before the chart and reported `DependencyNotReady`. The message, `unable to get ... dependency`, told a missing dependency from a red one. Pointing `dependsOn` at `message-store` opened the gate.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers the CI check that catches a stale reference.
- [LESSON.md](../LESSON.md) covers why the gate also matters after install.
- **breakfix-04: Path Not Found** — a pushed commit never lands, and the old workload serves.
