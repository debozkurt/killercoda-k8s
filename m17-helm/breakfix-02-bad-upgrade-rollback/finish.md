# Done

`helm status` said `deployed`, because Helm graded the apply and not the Pods. `kubectl get deployment -o wide` showed the stuck rollout, the Pod events named the missing tag, and `helm history` held revision 1 as the target. `helm rollback` wrote revision 3 and kept the release record and the Deployment in agreement.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers the `rollout undo` trap and the roll-forward fix.
- [LESSON.md](../LESSON.md) covers the release record, `--wait` and `--rollback-on-failure`.
- **breakfix-03: Render Required Value**: an install fails and nothing deploys.
