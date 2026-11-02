# Done

The server answered with a 400, so the TLS channel had opened and the server judged the client. The server log gave the reason: `unsuitable certificate purpose`. The client cert was signed by the trusted CA and carried a valid name, but its Extended Key Usage said `server auth`. A `Certificate` that lists the wrong `usages` gets exactly the wrong purpose. Restoring `client auth` and letting cert-manager reissue fixed it.

The instinct to keep: in mTLS, read who rejects. A handshake error means the client rejects the server. An HTTP error from the server means the server rejects the client, and its log says why. Signer, name and purpose are three separate checks.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Mutual TLS.
- That completes M12: issuance, identity, trust, and the server side of mTLS.
