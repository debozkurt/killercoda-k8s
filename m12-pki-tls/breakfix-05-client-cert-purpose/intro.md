# M12 — Break/fix 05: a client cert the server refuses

> The healthy PKI from the baseline, with one link broken. Work breakfix-02 and 03 first.

An alert fires: `config-client` in `app-services` cannot call `config-api` in `media`. Both Pods are Running. Both `Certificate` objects are Ready. The call returns an HTTP error page, so the TLS channel opens and the server then refuses the caller.

This is the **mTLS server side**. The server verifies the client cert before it serves a request. A cert needs the right name, a trusted signer, and the right purpose. The server rejects a cert issued for another purpose, even when a trusted CA signed it.

Your job: find which side rejects, read the server's reason, and fix the client cert at its source.

The cluster takes 2–3 minutes to come up. Click **Start** when ready.
