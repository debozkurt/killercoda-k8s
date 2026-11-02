# Done

You toured both traffic controls on a healthy cluster. A default-deny isolated every Pod in media for ingress, and one additive allow let app-services reach session-broker. You proved enforcement: an allowed call succeeded and a denied call hung to a timeout. You read why a cross-namespace allow needs a namespaceSelector. You routed an Ingress request through a controller and saw a 404 when no rule matched. You proved two guarantees: a Pod's own node is always allowed, and a second policy adds access without changing the first.

Carry three signatures into the break/fix scenarios:

- a NetworkPolicy drop is a **silent timeout**, not NXDOMAIN and not connection refused
- an Ingress **404** means no rule matched the host or path
- an Ingress **503** means a rule matched and the backend failed

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the why.
- Work the five break/fix scenarios in order:
  - **breakfix-01-networkpolicy-default-deny** — a service went dark after a lockdown
  - **breakfix-02-networkpolicy-cross-namespace** — an allow that allows nothing
  - **breakfix-03-ingress-misrouting** — a 503 with a healthy backend
  - **breakfix-04-egress-dns-timeout** — every lookup in a namespace times out
  - **breakfix-05-ingress-404-pathtype** — the home page loads and a deep link returns 404
- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each one.
