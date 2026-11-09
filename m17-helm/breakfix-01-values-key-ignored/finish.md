# Done

The values file set `replicas`, and the template reads `replicaCount`. Helm stored the unused key and rendered the chart default. The gap showed in two places: `helm get values -a` listed both keys, and `helm get manifest` rendered 1 replica.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) compares the `--set` fix with the file fix.
- [LESSON.md](../LESSON.md) covers values precedence and schema validation.
- **breakfix-02: Bad Upgrade, Rollback**: an upgrade reported `deployed`, and the rollout does not finish.
