# Done

The Deployment told the whole story: `UP-TO-DATE 1` of 2, `rollout status` stuck at "1 out of 2 new replicas have been updated," a new ReplicaSet Pod in `ImagePullBackOff`, and `Progressing False / ProgressDeadlineExceeded`. The root cause was a bad image tag (`nginx:1.25-doesnotexist`) in revision 2. The service stayed up the entire time because the rolling update's default `maxUnavailable` kept the old version serving until the new one was Ready — which it never was. `kubectl rollout undo` rewound to the last good revision and the rollout completed.

The lesson that generalizes: **a rolling update fails safe — it stalls rather than crashes — and rollback is the fast way out.** Kubernetes keeps the old ReplicaSet serving and flags a stuck rollout as `ProgressDeadlineExceeded`, but it does not act on that itself; a human or a pipeline must roll back or roll forward. Read the Deployment's conditions and the new ReplicaSet's Pods to find *why* it stalled, then `rollout undo` to recover while you fix the release properly.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Rolling updates and rollback.
- That's the last break/fix in M09. Revisit the baseline or `LESSON.md` to consolidate, then on to M10.
