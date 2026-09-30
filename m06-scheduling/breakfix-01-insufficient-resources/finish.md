# Done

A `Pending` Pod had one event that held the diagnosis: `FailedScheduling` with `Insufficient memory`. The memory request had slipped from 256Mi to 256Gi. The scheduler fits Pods by their requests, not by live usage, so it placed the Pod nowhere. The fix changed only the request and its limit.

Carry this reflex through the module: **for a `Pending` Pod, read the `FailedScheduling` event first, not the logs.** When requests do not fit, this is the signature.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The resource contract.
- Next scenario: **`breakfix-02-untolerated-taint`**. The Pod is `Pending` again, but no node is short of resources. A node repels the Pod.
