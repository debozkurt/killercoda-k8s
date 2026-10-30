# Done

The CRD release retired `v1` (`served: false`) while the operator still read `v1`. Every list call failed, so the operator reconciled nothing. The Pod showed `Running`, RBAC was fine, and the tenants' `.status` stayed blank. The operator's logs named the failing request, and the CRD's `Served:` flags explained it.

Keep two points. Upgrade an operator and its CRD in lockstep, and never stop serving a version that consumers still use. And two stalls can look alike. Forbidden leaves `Provisioning` with a 403 in the logs. An unserved version leaves blank status with a list error in the logs.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the reasoning, see [`LESSON.md`](../LESSON.md) § Versions.
- Next scenario: **`breakfix-04-orphaned-owner-reference`**. The failure moves from creation to cleanup.
