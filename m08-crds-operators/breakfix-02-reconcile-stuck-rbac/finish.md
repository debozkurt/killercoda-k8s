# Done

The operator was Running the whole time and provisioning nothing. Its reconcile loop read both tenants and tried to create their child Deployments, but the ServiceAccount it authenticates as had a ClusterRole granting only `get`/`list`/`watch` on Deployments — no `create`. Every pass hit `403 Forbidden` at the first write, so the tenants stayed `Provisioning` with no capacity. Granting the missing verbs let the very next loop succeed; no restart needed, because a control loop is level-triggered — it re-checks desired vs. observed continuously and acts the moment it can.

Two things worth keeping: **an operator's Pod status tells you the process is alive, not that reconciliation is working** — when custom resources sit un-progressed, read their `.status` and the operator's **logs**, which name the failing step; and **RBAC is the most common reason an operator silently does nothing** — it runs as a ServiceAccount and can only do what its Role/ClusterRole grants, so `kubectl auth can-i --as=<the operator's SA>` and the operator's logs are the fast path to the gap. (RBAC in full is M10.)

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The controller pattern: reconciliation.
- Continue to **`breakfix-03-orphaned-owner-reference`** — this time the operator works, but a deleted tenant left something behind.
