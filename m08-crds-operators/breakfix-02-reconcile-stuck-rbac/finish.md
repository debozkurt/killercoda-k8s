# Done

The operator was a healthy process and a stalled controller. Its ServiceAccount could read Deployments and could not create them, so every reconcile stopped at the first write. The Pod showed `Running` throughout. The evidence sat in the tenants' `.status` and in the logs.

Keep two points. Pod status says the program is alive, not that its loop progresses. And a controller is level-triggered, so it recovered on its own once the permission existed. No restart was needed.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the reasoning, see [`LESSON.md`](../LESSON.md) § The controller pattern.
- Next scenario: **`breakfix-03-unserved-crd-version`**. The same symptom, and RBAC is fine.
