# Done

The tenant "didn't get created" for the most literal reason: the API server refused it. The CRD carries an OpenAPI schema — `spec.tier` is an enum of `gold`/`silver`/`bronze` — and every custom resource is validated against it at admission, exactly like a built-in. `tier: platinum` failed the enum, so nothing was persisted, the operator never saw a `vega`, and no child Deployment was built. Correcting the tier to a valid value made the resource conform; the API server accepted it and the healthy operator provisioned it on its next pass.

Two things worth keeping: **a CRD's schema is real validation, enforced by the API server, not the operator** — so "my custom resource won't apply" is almost always a schema mismatch you can read straight from the error message (`kubectl explain <kind>` and the CRD's `openAPIV3Schema` show the rules); and **a rejected resource fails silently downstream** — there's no crash and no operator log, because the object never existed, so you diagnose it by trying the apply and reading admission's response.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Extending the API with CRDs.
- Continue to **`breakfix-02-reconcile-stuck-rbac`** — the resource is valid this time, but the operator still can't provision it.
