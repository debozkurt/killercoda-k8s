# Done

The caller got a raw connection reset, not a 503, and the server logged `filter_chain_not_found`. That pairing means plaintext from a caller with no Envoy. The `signaling` namespace had the injection label, but its pods started before the label. A rollout restart created a 2/2 pod, and the call returned 200 with `STRICT` unchanged.

The reflex: **a reset with no HTTP status means the caller has no sidecar. A namespace label changes only pods created after it.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-05-fault-injection-left-on`**.
