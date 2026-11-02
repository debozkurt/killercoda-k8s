# Done

A silent timeout with healthy DNS, endpoints and Pods points at a policy. The default-deny-ingress policy selected every Pod in media and listed no allowed source. Nothing let the real callers back in.

The fix added an allow and kept the deny, because the lockdown was the intent.

The reflex: **a NetworkPolicy drop is a quiet timeout, and the repair is usually a missing allow, not a policy to delete.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § The NetworkPolicy model.
- Next scenario: **breakfix-02-networkpolicy-cross-namespace**. An allow exists, and it still allows nothing.
