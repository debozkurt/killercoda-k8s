# Done

You diagnosed a bug that passes every health check and only bites on shutdown. The pod was `Running` and `Ready`; the failure was a `terminationGracePeriodSeconds` of 1 trying to contain a 15-second drain, so the kubelet `SIGKILL`ed the container mid-drain on every termination. You reproduced it by *timing a delete*, found the mismatch in the spec, and sized the budget to fit the work.

The principle to carry: graceful shutdown is only as good as the budget you give it. `preStop` plus `SIGTERM` handling must fit inside `terminationGracePeriodSeconds`, with headroom — or every rollout sheds live work.

**Next:**

- Check [`ANSWER-KEY.md`](../ANSWER-KEY.md) — the exact grace-period accounting, the PID-1 signal-forwarding trap, and how to *measure* the right number instead of guessing.
- For the *why*, see [`LESSON.md`](../LESSON.md) § graceful termination.
- That's all three M01 break/fix scenarios. You've now seen the Pod lifecycle break at startup (liveness), in steady state (readiness), and at shutdown (grace period). Next on the linear path: **M02 — Container Images & Registries**.
