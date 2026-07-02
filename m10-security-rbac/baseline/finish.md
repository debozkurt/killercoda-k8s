# Done

You read the fleet's security posture top to bottom: the ServiceAccount each Pod runs as (`default`, unless set) and the bound token projected into it, the RBAC Roles and bindings that grant permissions plus `kubectl auth can-i` to prove any decision, the `securityContext` the fleet runs with (the permissive defaults), and PodSecurity admission rejecting a non-compliant Pod while admitting a hardened one. That's the shape of "healthy" — internalize it so each broken gate stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the four break/fix scenarios, in order — the first three walk the `Forbidden` differential (one phrase in the message each), the fourth flips to the admission gate:
  - **`breakfix-01-rbac-missing-verb`** — `403 Forbidden`, `cannot list … in the namespace`: a Role that grants `get` but not `list`.
  - **`breakfix-02-serviceaccount-default`** — the same 403, naming `…:default`: a Pod that never adopted its intended SA.
  - **`breakfix-03-rbac-cluster-scope`** — `403 Forbidden … at the cluster scope`: a namespaced binding for a cluster-scoped resource.
  - **`breakfix-04-podsecurity-restricted`** — a Deployment `0/1` with no Pods at all: an admission rejection under `restricted`.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
