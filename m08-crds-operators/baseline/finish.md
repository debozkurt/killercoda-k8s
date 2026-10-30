# Done

You read a working operator end to end. A **CRD** added the `MediaTenant` type. Two **custom resources** carry a `.spec` that you declare and a `.status` that the operator writes. The **tenant-operator** reconciled each tenant into a child Deployment. **Owner references** hang the children from the tenants, so deleting a tenant removes its tree. A **finalizer** held the tenant until the operator finished its cleanup.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the reasoning behind each step.
- Work the five break/fix scenarios in order. Each breaks one link:
  - **`breakfix-01-cr-schema-rejected`** — a new tenant will not apply, because admission rejects it.
  - **`breakfix-02-reconcile-stuck-rbac`** — the operator is `Running` and no tenant advances, because RBAC forbids the first write.
  - **`breakfix-03-unserved-crd-version`** — the operator is `Running` and no tenant advances, because it reads a version the CRD no longer serves.
  - **`breakfix-04-orphaned-owner-reference`** — an offboarded tenant's Deployment still runs, because it has no ownerReference.
  - **`breakfix-05-finalizer-stuck-terminating`** — a deleted tenant never disappears, because its finalizer has no controller.
- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
