# M12 — Break/fix 01: a Certificate that won't issue

> Pre-req: the M12 baseline tour. You've seen a healthy leaf `Certificate` go `Ready: True` and produce a `kubernetes.io/tls` Secret. Here it doesn't.

`config-api` in the `media` namespace serves HTTPS from a cert-manager-issued certificate. After a manifest change it won't come up — the Pod is stuck `ContainerCreating` and never goes Ready. The rest of the fleet is fine.

This is the **issuance** layer of PKI: does a signed cert actually *exist*? A `Certificate` object can sit un-issued forever, and when it does, the Secret it's supposed to write is never created — so any Pod mounting that Secret is stuck at the starting line. Your job: recognize that the Pod isn't the problem, climb the cert-manager ladder to find *why* issuance failed, and fix it so the Secret gets written.

The cluster takes 2–3 minutes to come up (cert-manager installs during boot). Click **Start** when ready.
