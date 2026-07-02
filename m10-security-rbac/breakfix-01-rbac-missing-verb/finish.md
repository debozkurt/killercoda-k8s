# Done

A `CrashLoopBackOff` that was never an app bug: the container's logs read `403 Forbidden — cannot list resource "endpoints" ... in the namespace "media"`. The identity was right (`system:serviceaccount:media:endpoint-watcher`), so the *permission* was the problem — its Role granted `get` and `watch` on endpoints but not `list`, and a collection read needs `list`. Adding the one verb flipped `kubectl auth can-i` from `no` to `yes`; a `rollout restart` cleared the backoff.

The reflex: **a CrashLoop whose logs say `Forbidden` is an RBAC problem, not an app problem.** Read the Forbidden as a sentence — identity, verb, resource, scope — and fix whichever one is wrong.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § RBAC.
- Next scenario: **`breakfix-02-serviceaccount-default`** — the same 403, but this time the identity the message names is *wrong*.
