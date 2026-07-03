# Done

The build was valid and the apply succeeded, so nothing complained until the kubelet tried to start the container and couldn't find `configmap "edge-relay-conf"`. The generator had produced `edge-relay-config-<hash>` all along — but because the Deployment's `envFrom` name didn't match the generator's declared name, Kustomize never rewrote the reference to the hashed object. Two names that had to be identical had drifted apart by four characters.

The reflex to keep: **when a generated object seems "missing," compare the render to the cluster.** `kubectl kustomize` shows you the hashed name Kustomize created *and* the exact reference it wrote (or didn't rewrite). The reference rewrite is a name match — get the names to agree and the hash follows. This is the *runtime* leaf of the differential: build and apply were both green.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Generators and the name-suffix hash.
- Next scenario: **`breakfix-03-commonlabels-immutable-selector`** — the build succeeds and the API server *rejects* the apply.
