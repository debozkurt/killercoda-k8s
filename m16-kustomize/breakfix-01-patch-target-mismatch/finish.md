# Done

A patch targeted a resource name that didn't exist, so `kustomize build` failed and `apply -k` sent nothing to the cluster. The workload was *absent*, not broken — and the answer wasn't in `kubectl describe` (there was nothing to describe), it was in the build output. You rendered the overlay, read `no matches for Id ... failed to find unique target for patch`, and lined up the patch's `metadata.name` (`edge-relayer`) against the base's real name (`edge-relay`).

The reflex to keep: **when `apply -k` yields nothing, run `kubectl kustomize` and read the error.** Kustomize is a compiler; a build error is a first-class diagnosis, not a mystery. This is the *build* leaf of the three-layer differential — build, apply, runtime.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Patches: how a change finds its target.
- Next scenario: **`breakfix-02-generator-name-mismatch`** — this time the build *and* the apply succeed, and the Pod still won't start.
