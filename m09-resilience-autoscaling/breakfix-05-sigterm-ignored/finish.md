# Done

The kubelet sent SIGTERM and the container ignored it (`trap '' TERM`). Nothing ended the process until the 45-second grace period expired and the runtime sent SIGKILL. Every delete and drain waited the full 45 seconds, and every replaced Pod lingered in `Terminating` after a rollout. Nothing errored, because the cost was time. In-flight work was still cut off at the end.

Termination is one budget that starts at deletion. A container with a SIGTERM handler uses a fraction of it. Read a slow change as a duration: time a delete and compare it with `terminationGracePeriodSeconds`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Graceful shutdown.
- Last scenario: **`breakfix-06-hpa-quota-capped`**. An autoscaler that asks for Pods that never arrive.
