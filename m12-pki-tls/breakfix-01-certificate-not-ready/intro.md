# M12 — Break/fix 01: a Certificate that won't issue

> The healthy PKI from the baseline, with one link broken.

An alert fires: `config-api` in the `media` namespace never goes Ready. After a manifest change, the Pod sits in `ContainerCreating`. The rest of the fleet is healthy.

This is the **issuance** layer: does a signed cert exist? A `Certificate` that cannot issue never writes its Secret. A Pod that mounts that Secret waits at the starting line.

Your job: show that the Pod is not the problem, climb the cert-manager ladder to the reason issuance failed, and fix the cause.

The cluster takes 2–3 minutes to come up. Click **Start** when ready.
