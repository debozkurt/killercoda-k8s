# Done

`session-cache`'s Pods were all healthy, but peer discovery was broken: the governing Service had a `clusterIP` instead of `clusterIP: None`, so it was an ordinary VIP Service, and per-Pod DNS records (`session-cache-0.session-cache.media.svc`) are published **only** for a headless one. No member could address another by name. `get svc` showed the VIP where `None` belonged; the fix meant working around an immutable field — `clusterIP` can't be edited, so you deleted and recreated the Service headless, without disturbing the Pods or their PVCs.

The lesson: **a StatefulSet's stable identity is only reachable if its governing Service is headless.** Identity and discovery are two separate primitives, and this failure breaks discovery while identity looks fine.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Headless Services and per-Pod DNS.
- Next scenario: **`breakfix-02-statefulset-ordered-wedge`** — this time the Pods themselves don't all come up.
