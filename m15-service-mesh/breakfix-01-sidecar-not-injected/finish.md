# Done

The caller's access log read `URX,UF` with a `TLS_error`: the client sent mTLS and the server answered in plaintext. The server pod was 1/1, absent from `istioctl proxy-status`, and carried `sidecar.istio.io/inject=false`. Removing the label rolled a 2/2 pod, and the call returned 200 with `STRICT` mTLS unchanged.

The reflex: **a pod is in the mesh only if it has a sidecar. Count containers early.** The explicit `ISTIO_MUTUAL` mode made this failure loud. Under automatic mTLS, the caller would have sent plaintext and the call would have worked, unencrypted.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-02-virtualservice-subset`**.
