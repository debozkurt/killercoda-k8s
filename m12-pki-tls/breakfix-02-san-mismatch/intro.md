# M12 — Break/fix 02: a cert valid for the wrong name

> Pre-req: the M12 baseline tour. You've decoded a cert and read its SANs, and watched `config-client` call `config-api` over mTLS. Here the call fails on identity.

`config-client` in `app-services` calls `config-api` in `media` over mutual TLS. Everything *looks* healthy — `config-api` is `Running 1/1`, its `Certificate` is `Ready`, the `kubernetes.io/tls` Secret exists — but the call is failing, and it's failing during the TLS handshake, not the app.

This is the **identity** layer: a cert can be freshly issued and perfectly trusted and still get rejected, because the name it's valid for isn't the name the client dialed. Modern TLS checks the cert's **Subject Alternative Names** against the connection's target host, and only the SANs — the legacy Common Name doesn't count. Your job: read the error, read the cert's SANs, and make the two agree.

The cluster takes 2–3 minutes to come up (cert-manager installs during boot). Click **Start** when ready.
