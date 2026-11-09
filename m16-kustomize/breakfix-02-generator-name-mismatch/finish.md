# Done

The Deployment referenced `edge-relay-conf`, and the generator is `edge-relay-config`. Kustomize rewrites a reference to the hashed name only when the names match exactly, so the reference stayed bare. Build and apply succeeded, and the kubelet could not find the ConfigMap.

The reflex: **when a generated object seems missing, compare the reference in the render with the generated name.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-03-commonlabels-immutable-selector`**.
