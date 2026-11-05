# Done

The caller's log read `URX,UC` against a healthy endpoint, and the server's sidecar logged `filter_chain_not_found` for each attempt. The PeerAuthentication required mTLS (`STRICT`), and the DestinationRule told callers to send plaintext (`DISABLE`). Setting the client to `ISTIO_MUTUAL` made both sides agree with `STRICT` unchanged.

The reflex: **mTLS is a two-sided contract. Read the PeerAuthentication and the DestinationRule together, and repair the client side.** Without the explicit `DISABLE`, automatic mTLS would have sent mTLS here.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-04-injection-not-restarted`**.
