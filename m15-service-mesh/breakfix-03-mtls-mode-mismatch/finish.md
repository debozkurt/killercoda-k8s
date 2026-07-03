# Done

You worked a `503` that survived every earlier check: pods `2/2`, route on `stable`, endpoints present, mTLS "on." The break was that mTLS has two halves — the server's PeerAuthentication (`STRICT`, accept only mTLS) and the client's DestinationRule `tls` mode (`DISABLE`, send plaintext) — and they contradicted each other. Callers sent plaintext into a server that rejects it. Bringing the client's mode to `ISTIO_MUTUAL` made both sides agree, and traffic flowed.

The reflex to keep: **mTLS is a two-sided contract — read the PeerAuthentication and the DestinationRule together.** When the workload is healthy and the route is correct, a `503` is usually a transport-policy disagreement. And fix it in the safe direction: raise the client to mTLS, don't drop the server to PERMISSIVE. The whole point of the mesh was to encrypt that hop.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Mesh-managed mTLS.
- You've completed M15's three break/fix scenarios — three different roots (no sidecar, empty subset, mTLS mismatch) behind the same `503`. The differential is the skill.
