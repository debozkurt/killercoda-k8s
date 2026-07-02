# Done

You read a working operator end to end: a **CRD** (`MediaTenant`) that added a first-class type to the API, two **custom resources** whose `.spec` you'd declare and whose `.status` the operator writes, the **tenant-operator** control loop that reconciled each tenant into a child media Deployment, and the **ownerReferences** that hang those children off their MediaTenant so cascading deletion can clean up. That's the shape of "the operator is healthy" — internalize it so each break stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each breaks one link in that chain:
  - **`breakfix-01-cr-schema-rejected`** — a new tenant won't apply at all: its custom resource violates the CRD's schema, so admission rejects it.
  - **`breakfix-02-reconcile-stuck-rbac`** — the operator is Running, but no tenant ever reaches Ready and no children appear: reconciliation is stuck.
  - **`breakfix-03-orphaned-owner-reference`** — a tenant was offboarded, but its media Deployment is still running: a missing ownerReference broke cascading deletion.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
