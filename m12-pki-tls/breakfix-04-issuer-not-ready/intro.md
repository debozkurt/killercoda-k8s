# M12 — Break/fix 04: two Certificates fail at once

> The healthy PKI from the baseline, with one link broken. Work breakfix-01 first.

An alert fires: `config-api` in `media` and `config-client` in `app-services` both sit in `ContainerCreating`. Two workloads in two namespaces fail together, and no manifest of either changed.

This is the **issuance** layer again, one rung deeper. Last time the `Certificate` named an issuer that did not exist. Here every issuer name resolves, and issuance still stalls. Two failures with one shape point at what the two `Certificate` objects share.

Your job: name the shared link, prove it with one command, and fix it once.

The cluster takes 2–3 minutes to come up. Click **Start** when ready.
