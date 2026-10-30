# Done

A CRD's schema is real validation. The API server checked the custom resource against the schema, found `platinum` outside the enum, and refused to store it. The operator was healthy and never saw the resource, so no downstream object failed. The error message named the field, the bad value and the allowed values.

Keep two points. A rejected custom resource leaves no trace except the error you saw at apply time, so a pipeline that discards `kubectl apply` output hides it. And `kubectl explain` shows the schema you must satisfy.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the reasoning, see [`LESSON.md`](../LESSON.md) § Extending the API with CRDs.
- Next scenario: **`breakfix-02-reconcile-stuck-rbac`**. The resources are valid, and the operator still does nothing.
