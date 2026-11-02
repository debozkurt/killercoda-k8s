# M12 — Break/fix 02: a cert valid for the wrong name

> The healthy PKI from the baseline, with one link broken. Work breakfix-01 first.

An alert fires: `config-client` in `app-services` cannot call `config-api` in `media`. By every status check the server is healthy. `config-api` is Running, its `Certificate` is Ready, and its Secret exists. The call still fails, and it fails inside the TLS handshake.

This is the **identity** layer. A client checks the **Subject Alternative Names** (SANs) of the server cert against the name it dialed. A cert can be freshly issued and fully trusted, and the client still rejects it when the names do not match.

Your job: read the error, read the cert's SANs, and make the two agree.

The cluster takes 2–3 minutes to come up. Click **Start** when ready.
