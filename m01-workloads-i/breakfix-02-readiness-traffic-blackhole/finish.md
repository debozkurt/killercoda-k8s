# Done

You found a Service with no backends while every Pod was `Running`. The `READY 0/1` column and the empty `kubectl get endpoints` were the tells; `describe` named the cause — a readiness probe on the wrong port, refusing to pass, quietly pulling every replica out of rotation. No restarts, because readiness doesn't restart anything.

Hold the contrast with breakfix-01: **liveness restarts, readiness gates traffic.** Same kind of typo, completely different blast radius. And "Running" never means "Ready."

**Next:**

- Check [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including the trap where a readiness probe wired to a shared dependency takes down *all* replicas at once.
- For the *why*, see [`LESSON.md`](../LESSON.md) § the three probes, and the readiness → Endpoints link (full Services treatment is M04).
- Last M01 scenario: **`breakfix-03-prestop-truncation`** — the workload is healthy and serving, until you try to shut it down.
