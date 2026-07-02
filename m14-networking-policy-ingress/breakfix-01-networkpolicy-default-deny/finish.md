# Done

You diagnosed a silent timeout the way M04 taught you to diagnose a refused connection: rule out each hop first. DNS resolved, the endpoints were populated, the Pods were Ready — and the connection still hung, which left exactly one culprit: a NetworkPolicy dropping the packet. The `default-deny-ingress` had selected every pod in `media` and flipped the namespace to deny, with no allow to let the real callers back in.

The fix was to *add* the allow, not remove the deny — because the lockdown was the intent, not the bug. That's the reflex to keep: **a NetworkPolicy drop is a quiet timeout, and the repair is almost always a missing allow, not a policy to delete.** Isolation in Kubernetes comes from the absence of an allow; you restore access by adding one narrowly, keeping everything else denied.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The NetworkPolicy model.
- Next scenario: **`breakfix-02-networkpolicy-cross-namespace`** — this time an allow *is* present, and it still allows nothing.
