# Done

The prod patch file named `edge-relayer`, and the base Deployment is `edge-relay`. A patch file with no `target:` names exactly one resource, so Kustomize failed the build, and `apply -k` created nothing. The answer was in the build error, not in the cluster.

The reflex: **when `apply -k` leaves nothing in the cluster, run `kubectl kustomize` and read the error.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-02-generator-name-mismatch`**.
