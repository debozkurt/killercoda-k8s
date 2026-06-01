# Done

You diagnosed a pod that wasn't *failing* to pull — it was forbidden from pulling. `ErrImageNeverPull` is the one differential branch where no registry is contacted at all: `imagePullPolicy: Never` plus an uncached image. The tell was the status word *Never* and the absence of any `Pulling`/`Failed to pull` event. You let the kubelet pull (or, for a real air-gapped node, you'd pre-load the image and keep `Never`).

That's the first and simplest branch. The next three are all *real* pull attempts that fail at different points — reachability, auth, and the reference itself.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "How — and whether — the kubelet pulls".
- Next scenario: **`breakfix-02-registry-unreachable`** — this time the kubelet *does* try to pull, and can't even reach the registry.
