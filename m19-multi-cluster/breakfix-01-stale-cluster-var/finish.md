# Done

A region overlay was cloned from its sibling and one line — its `REGION` cluster variable — never got changed. The cluster rendered, applied, and ran perfectly; it just reported the wrong region. There was nothing to `describe` and no error to read. You found it by rendering the affected cluster, spotting the value that disagreed with the label, and tracing `REGION` up the layer path to the single file that owns it.

The reflex to keep: **when a fleet value is wrong but the workload is healthy, render the cluster and grep the value up its layer path.** The layer that sets it — the last one in composition order — is where you fix it, and fixing it there corrects every cluster that inherits the layer. This is the *stale-in-the-owning-layer* leaf of the differential.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Cluster variables: what differs, and where it lives.
- Next scenario: **`breakfix-02-shadowed-override`** — this time the owning layer is *correct*, and a different layer is overriding it.
