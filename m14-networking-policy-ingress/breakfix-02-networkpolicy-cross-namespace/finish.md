# Done

The allow looked complete and matched nothing. Its peer was a bare podSelector. A bare podSelector selects Pods in the policy's own namespace, so `podSelector: { app: sip-app }` in a media policy means "sip-app Pods in media". None exist.

A namespaceSelector in the same list entry made an AND and pointed the peer at sip-app Pods in app-services.

The reflex: **a cross-namespace allow always needs a namespaceSelector.** List shape also matters. Two selectors in one entry are an AND. Two entries are an OR. That difference is a security boundary.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Peers and selectors.
- Next scenario: **breakfix-03-ingress-misrouting**. Leave east-west behind. An Ingress returns 503 while its backend is healthy.
