# Done

`session-cache` was declared with 3 replicas but only `session-cache-0` existed, stuck `0/1 Running`. The default `OrderedReady` policy won't create ordinal N+1 until ordinal N is Ready — and `-0` never became Ready because its readiness probe pointed at port 8080 while nginx serves on 80. One wrong port halted the entire set. Fixing it took two moves: `patch` the probe port back to 80, then `delete` the stuck `session-cache-0`. That second step is the catch — `OrderedReady` won't roll a corrected template onto a Pod that was never Ready (a documented "forced rollback"), so the Pod on the bad revision has to be deleted before its replacement can come up on the fix. Ordinal 0 then passed, and `OrderedReady` created `-1` and `-2` in order.

The lesson: **an `OrderedReady` StatefulSet is only as available as its lowest unready ordinal.** Missing higher ordinals aren't a scheduling problem — they're a signal that a lower ordinal is blocking the whole sequence. Diagnose the *first* unready Pod.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Stable identity and the ordered lifecycle.
- Next scenario: **`breakfix-03-leader-election-rbac`** — the Pods are all up, but no leader is ever elected.
