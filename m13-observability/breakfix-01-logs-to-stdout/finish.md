# Done

A Running 1/1 workload had an empty `kubectl logs`. The Pod was not crashing and not unschedulable. It broke the **logging contract**. Its banner named `/var/log/app/session.log`, a file inside the container, and the kubelet captures only stdout and stderr. The output existed the whole time. Nothing captured it. You moved it onto stdout, either by changing the app or with a streaming sidecar. Now `kubectl logs` and a node-level collector can both see it.

The reflex: **an empty log on a healthy Pod means the app does not log to stdout.** Read the banner for the destination. Confirm with `kubectl exec … ls /var/log`. Then bridge the output to stdout.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Logs.
- Next scenario: **`breakfix-02-sidecar-crashloop`**, a Pod at 1/2 where a sidecar dies after it starts.
