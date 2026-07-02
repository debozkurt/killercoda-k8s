# Done

A `Running 1/1` workload with an empty `kubectl logs` — not a crash, not a scheduling problem, but a broken **logging contract**. The one line it printed named the culprit: it wrote its real activity to `/var/log/app/session.log`, a file inside the container, and the kubelet captures only **stdout/stderr**. The output existed the whole time; nothing was capturing it. Getting it onto stdout — by reconfiguring the app, or by a streaming sidecar that tails the file — made it visible to `kubectl logs` and, in a real cluster, to the node-level collector that ships every Pod's stdout to a central store.

The reflex: **an empty log on a healthy Pod means the app isn't logging to stdout** — check where it *is* writing (its own banner often tells you; `kubectl exec … ls /var/log/…` confirms), then bridge that output to stdout.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Logs.
- Next scenario: **`breakfix-02-sidecar-crashloop`** — a Pod at `1/2`, where the events tell you *which* container is down and `--previous` tells you why.
