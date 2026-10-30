# Done

The Deployment stated the problem: UP-TO-DATE 1 of 2, `rollout status` waiting on "1 out of 2 new replicas have been updated", a new ReplicaSet Pod in `ImagePullBackOff`, and `Progressing False` with `ProgressDeadlineExceeded`. Revision 2 named an image tag that does not exist. The service stayed up because `maxUnavailable` rounds down to 0 for 2 replicas, so both old Pods kept serving. `kubectl rollout undo` restored the last good revision.

A rolling update stalls instead of crashing the service, and Kubernetes does not act on a stall by itself. With a larger fleet it can retire up to `maxUnavailable` old Pods first, so capacity dips before the stall.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Rolling updates and rollback.
- Next scenario: **`breakfix-04-pdb-unready-pods`**. A sane budget that still blocks a drain.
