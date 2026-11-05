# M15 — Break/fix 03: mTLS Mode Mismatch

> Pre-req: the M15 baseline tour.

**Alert:** every call to `session-broker` returns 503.

Every `media` pod is 2/2 and `Ready`. The VirtualService routes to `stable`, and that subset has an endpoint. The namespace still runs `STRICT` mTLS, as the security team requires.

Your job: find which side of the connection refuses it, and fix it without weakening `STRICT`.

The cluster takes 3 to 5 minutes to start. Click **Start** when ready.
