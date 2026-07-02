# Done

You toured both traffic controls healthy. On the east-west side: a `default-deny-ingress` selecting every pod in `media`, plus one additive allow that let the `app-services` plane reach `session-broker` — and you proved the CNI enforces it, with an allowed source getting through and a denied one hanging to a timeout. You saw why cross-namespace allows need a `namespaceSelector` and how namespaces carry an automatic name label. On the north-south side: an ingress-nginx controller claiming an Ingress by its `nginx` class and routing external HTTP to `portal-ui`.

That's the shape of "shaped, working traffic." Internalize the two new failure signatures before you break them:

- a NetworkPolicy drop is a **silent timeout** (not `NXDOMAIN`, not `connection refused`)
- an Ingress backend problem is a **`503`**; a routing-rule miss is a **`404`**

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order:
  - **`breakfix-01-networkpolicy-default-deny`** — a service went dark after a lockdown; the allow was never added.
  - **`breakfix-02-networkpolicy-cross-namespace`** — an allow that allows nothing, because its peer is namespace-local.
  - **`breakfix-03-ingress-misrouting`** — an Ingress that `503`s with a perfectly healthy backend.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
