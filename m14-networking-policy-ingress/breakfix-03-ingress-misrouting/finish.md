# Done

You read a `503` for what it is: the Ingress controller matched a rule but had no healthy backend to forward to. The tell was that the backend was demonstrably fine — `portal-ui` had endpoints and answered directly on port 80 — which meant the break was in the rule connecting the front door to that Service. `describe ingress` against `get svc` showed it in one line: the rule forwarded to `portal-ui:8080`, a port the Service never exposed, so the controller resolved it to zero endpoints and returned `503`.

The reflex to carry: **`503` is a backend problem — Service name, port, or endpoints — and `404` is a routing-rule problem (host or path). Read the code first, then read the Ingress rule against the Service it names.** An Ingress inherits every Service failure mode from M04; the L7 hop just adds two status codes on top.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Ingress: an L7 router.
- You've worked all three scenarios. Together they extend M04's connectivity differential with the two branches this module adds — the silent policy timeout, and the Ingress `503`/`404`.
