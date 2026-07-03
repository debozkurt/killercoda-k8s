# M12 — Break/fix 03: the client trusts the wrong CA

> Pre-req: the M12 baseline tour. You've seen `config-client` verify `config-api` against a mounted CA bundle (`/etc/tls/trust/ca.crt`). Here it's verifying against the wrong one.

`config-client` in `app-services` calls `config-api` in `media` over mTLS. The server side is flawless — the cert is issued, `Ready`, and valid for the right name (you fixed that last scenario). But the call still fails, and this time the failure is on the *client's* side of the check.

This is the **trust** layer: a TLS client accepts a server only if it can chain the server's cert up to a CA it already holds. `config-api`'s cert is signed by the internal CA — so the client must hold *that* CA's public cert to verify it. Mount a different CA and the client rejects a perfectly valid certificate. Your job: recognize a trust failure (not a bad cert), find which CA the client is trusting, and give it the right one — **not** by disabling verification.

The cluster takes 2–3 minutes to come up (cert-manager installs during boot). Click **Start** when ready.
