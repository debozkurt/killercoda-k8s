# M12 — Break/fix 03: the client trusts the wrong CA

> The healthy PKI from the baseline, with one link broken. Work breakfix-01 and 02 first.

An alert fires: `config-client` in `app-services` cannot call `config-api` in `media`. The server side is flawless. Its cert is issued, Ready, and lists the right names. The call fails on the client's side of the check.

This is the **trust** layer. A client accepts a server only when it can chain the server's cert to a CA it already holds. `config-api` presents a cert signed by the internal CA, so the client needs that CA's public cert. A different CA makes the client reject a valid certificate.

Your job: recognize a trust failure, find which CA the client holds, and give it the right one. Do not disable verification.

The cluster takes 2–3 minutes to come up. Click **Start** when ready.
