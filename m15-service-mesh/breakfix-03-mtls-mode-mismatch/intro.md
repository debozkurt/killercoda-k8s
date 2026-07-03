# M15 — Break/fix 03: mTLS Mode Mismatch

> Pre-req: the M15 baseline tour and break/fix 01–02. You've ruled out "no sidecar" and "empty subset." This `503` is the third kind.

`session-broker` is `503`ing, and it's neither of the last two causes. Every pod is `2/2` and in the mesh. The VirtualService routes to `stable`, and that subset has healthy endpoints. `istioctl proxy-config` shows the route landing on live pods. By every check so far, the request should complete — and it doesn't.

The break is in mTLS, and specifically in the fact that mTLS has **two halves that must agree**. A **PeerAuthentication** governs what a *server's* sidecar will accept. A **DestinationRule**'s `tls` mode governs what a *client's* sidecar will send. Here the server side is `STRICT` (accept only mTLS) while the client side was set to `DISABLE` (send plaintext). Callers dutifully send plaintext into a server that rejects everything but mTLS, so the connection is reset and the caller's Envoy returns `503`.

This is a config-vs-config mismatch — nothing is "down." Your job: read both halves, spot that they disagree, and bring the client side back in line with the server. The cluster takes 3–5 minutes to come up. Click **Start** when ready.
